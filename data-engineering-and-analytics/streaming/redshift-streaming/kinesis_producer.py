#!/usr/bin/env python3
"""
Kinesis Data Streams Producer Script
Generates random sensor data and sends it to a Kinesis stream.

Configuration via environment variables:
    KINESIS_STREAM_NAME: Name of the Kinesis stream (default: demo-stream)
    AWS_REGION: AWS region (default: us-east-1)
    MAX_RETRIES: Maximum retry attempts for failed records (default: 3)
    RETRY_BASE_DELAY: Base delay in seconds for exponential backoff (default: 0.5)
"""

import boto3
import json
import os
import random
import time
from datetime import datetime, timedelta
from typing import Dict, Any, Optional
import logging
from botocore.exceptions import ClientError

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Configuration from environment variables
DEFAULT_STREAM_NAME = 'demo-stream'
DEFAULT_REGION = 'us-east-1'
DEFAULT_MAX_RETRIES = 3
DEFAULT_RETRY_BASE_DELAY = 0.5

class KinesisProducer:
    def __init__(
        self,
        stream_name: str,
        region: str = 'us-east-1',
        max_retries: int = DEFAULT_MAX_RETRIES,
        retry_base_delay: float = DEFAULT_RETRY_BASE_DELAY,
        validate_stream: bool = True
    ):
        """
        Initialize Kinesis producer

        Args:
            stream_name: Name of the Kinesis stream
            region: AWS region (default: us-east-1)
            max_retries: Maximum retry attempts for failed records (default: 3)
            retry_base_delay: Base delay in seconds for exponential backoff (default: 0.5)
            validate_stream: Whether to validate stream exists on init (default: True)
        """
        self.stream_name = stream_name
        self.region = region
        self.max_retries = max_retries
        self.retry_base_delay = retry_base_delay
        self.kinesis_client = boto3.client('kinesis', region_name=region)

        # Validate stream exists if requested
        if validate_stream:
            self._validate_stream()

        # Sensor configuration
        self.sensor_ids = list(range(1001, 1021))  # 20 sensors (1001-1020)
        self.status_options = ['ACTIVE', 'INACTIVE', 'MAINTENANCE', 'ERROR', 'CALIBRATING']

    def _validate_stream(self) -> None:
        """
        Validate that the Kinesis stream exists and is active.

        Raises:
            ValueError: If stream doesn't exist or is not active
        """
        try:
            response = self.kinesis_client.describe_stream(StreamName=self.stream_name)
            status = response['StreamDescription']['StreamStatus']
            if status != 'ACTIVE':
                raise ValueError(f"Stream '{self.stream_name}' exists but is not active (status: {status})")
            logger.info(f"Stream '{self.stream_name}' validated successfully (status: {status})")
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                raise ValueError(f"Stream '{self.stream_name}' does not exist in region '{self.region}'")
            raise

    def _retry_with_backoff(self, func, *args, **kwargs) -> Any:
        """
        Execute a function with exponential backoff retry logic.

        Args:
            func: Function to execute
            *args: Positional arguments for func
            **kwargs: Keyword arguments for func

        Returns:
            Result of successful function execution

        Raises:
            Exception: If all retry attempts fail
        """
        last_exception = None
        for attempt in range(self.max_retries):
            try:
                return func(*args, **kwargs)
            except ClientError as e:
                last_exception = e
                error_code = e.response['Error']['Code']

                # Don't retry on non-retryable errors
                if error_code in ['ValidationError', 'InvalidArgumentException', 'ResourceNotFoundException']:
                    raise

                if attempt < self.max_retries - 1:
                    delay = self.retry_base_delay * (2 ** attempt)
                    logger.warning(f"Attempt {attempt + 1} failed: {error_code}. Retrying in {delay:.2f}s...")
                    time.sleep(delay)

        logger.error(f"All {self.max_retries} retry attempts failed")
        raise last_exception
        
    def generate_sensor_record(self) -> Dict[str, Any]:
        """
        Generate a random sensor record
        
        Returns:
            Dictionary containing sensor data
        """
        # Generate random date within last 30 days
        end_date = datetime.now()
        start_date = end_date - timedelta(days=30)
        random_date = start_date + timedelta(
            seconds=random.randint(0, int((end_date - start_date).total_seconds()))
        )
        
        record = {
            'sensor_id': random.choice(self.sensor_ids),
            'current_temperature': random.randint(-20, 50),  # Temperature in Celsius
            'status': random.choice(self.status_options),
            'created_date': random_date.strftime('%Y-%m-%d')
        }
        
        return record
    
    def send_record(self, record: Dict[str, Any]) -> bool:
        """
        Send a single record to Kinesis with retry logic.

        Args:
            record: The record to send

        Returns:
            True if successful, False otherwise
        """
        try:
            # Convert record to JSON string with newline
            data = json.dumps(record) + '\n'

            # Use sensor_id as partition key for even distribution
            partition_key = str(record['sensor_id'])

            def _put_record():
                return self.kinesis_client.put_record(
                    StreamName=self.stream_name,
                    Data=data,
                    PartitionKey=partition_key
                )

            response = self._retry_with_backoff(_put_record)

            logger.info(f"Record sent successfully. Shard ID: {response['ShardId']}, "
                        f"Sequence Number: {response['SequenceNumber']}")
            return True

        except Exception as e:
            logger.error(f"Error sending record after {self.max_retries} attempts: {str(e)}")
            return False
    
    def send_batch_records(self, records: list) -> int:
        """
        Send multiple records to Kinesis using put_records (batch) with retry logic.

        Failed records are automatically retried with exponential backoff.

        Args:
            records: List of records to send

        Returns:
            Number of successfully sent records
        """
        if not records:
            return 0

        try:
            # Prepare records for batch sending
            kinesis_records = []
            for record in records:
                kinesis_records.append({
                    'Data': json.dumps(record) + '\n',
                    'PartitionKey': str(record['sensor_id'])
                })

            total_success = 0
            records_to_send = kinesis_records

            for attempt in range(self.max_retries):
                def _put_records():
                    return self.kinesis_client.put_records(
                        Records=records_to_send,
                        StreamName=self.stream_name
                    )

                response = _put_records()

                # Check for failed records
                failed_count = response['FailedRecordCount']
                success_count = len(records_to_send) - failed_count
                total_success += success_count

                if failed_count == 0:
                    break

                # Collect failed records for retry
                failed_records = []
                for i, record_result in enumerate(response['Records']):
                    if 'ErrorCode' in record_result:
                        error_code = record_result['ErrorCode']
                        # Only retry on throttling/transient errors
                        if error_code in ['ProvisionedThroughputExceededException', 'InternalFailure']:
                            failed_records.append(records_to_send[i])
                        else:
                            logger.error(f"Record {i} failed (non-retryable): {error_code} - {record_result.get('ErrorMessage', '')}")

                if not failed_records:
                    break

                if attempt < self.max_retries - 1:
                    delay = self.retry_base_delay * (2 ** attempt)
                    logger.warning(f"Retrying {len(failed_records)} failed records in {delay:.2f}s (attempt {attempt + 2}/{self.max_retries})...")
                    time.sleep(delay)
                    records_to_send = failed_records
                else:
                    logger.error(f"Failed to send {len(failed_records)} records after {self.max_retries} attempts")

            logger.info(f"Successfully sent {total_success} out of {len(records)} records")
            return total_success

        except ClientError as e:
            logger.error(f"Error sending batch records: {str(e)}")
            return 0
    
    def run_continuous_producer(self, records_per_second: int = 10, duration_seconds: int = 60) -> int:
        """
        Run continuous data production with graceful error handling.

        Args:
            records_per_second: Number of records to send per second
            duration_seconds: How long to run the producer

        Returns:
            Total number of records successfully sent
        """
        logger.info(f"Starting continuous producer: {records_per_second} records/sec for {duration_seconds} seconds")

        start_time = time.time()
        total_sent = 0
        total_failed = 0
        consecutive_failures = 0
        max_consecutive_failures = 5

        try:
            while time.time() - start_time < duration_seconds:
                batch_start = time.time()

                try:
                    # Generate and send records
                    records = [self.generate_sensor_record() for _ in range(records_per_second)]
                    sent_count = self.send_batch_records(records)
                    total_sent += sent_count
                    failed_count = len(records) - sent_count
                    total_failed += failed_count

                    # Track consecutive failures for circuit breaker
                    if sent_count == 0:
                        consecutive_failures += 1
                        if consecutive_failures >= max_consecutive_failures:
                            logger.error(f"Circuit breaker triggered: {consecutive_failures} consecutive batch failures. Stopping producer.")
                            break
                    else:
                        consecutive_failures = 0

                except Exception as e:
                    consecutive_failures += 1
                    logger.error(f"Error during batch send: {str(e)}")
                    if consecutive_failures >= max_consecutive_failures:
                        logger.error(f"Circuit breaker triggered: {consecutive_failures} consecutive failures. Stopping producer.")
                        break

                # Sleep to maintain the desired rate
                elapsed = time.time() - batch_start
                sleep_time = max(0, 1.0 - elapsed)
                time.sleep(sleep_time)

        except KeyboardInterrupt:
            logger.info("Producer interrupted by user")

        elapsed_time = time.time() - start_time
        logger.info(f"Producer finished. Duration: {elapsed_time:.1f}s, Sent: {total_sent}, Failed: {total_failed}")
        return total_sent

def main():
    """
    Main function to run the Kinesis producer.

    Configuration is loaded from environment variables:
        KINESIS_STREAM_NAME: Name of the Kinesis stream (default: demo-stream)
        AWS_REGION: AWS region (default: us-east-1)
        MAX_RETRIES: Maximum retry attempts (default: 3)
        RETRY_BASE_DELAY: Base delay for exponential backoff in seconds (default: 0.5)
    """
    # Load configuration from environment variables
    stream_name = os.environ.get('KINESIS_STREAM_NAME', DEFAULT_STREAM_NAME)
    region = os.environ.get('AWS_REGION', DEFAULT_REGION)
    max_retries = int(os.environ.get('MAX_RETRIES', DEFAULT_MAX_RETRIES))
    retry_base_delay = float(os.environ.get('RETRY_BASE_DELAY', DEFAULT_RETRY_BASE_DELAY))

    print("Kinesis Data Streams Producer")
    print("=" * 40)
    print(f"Stream Name: {stream_name}")
    print(f"Region: {region}")
    print(f"Max Retries: {max_retries}")
    print()

    # Create producer instance with stream validation
    try:
        producer = KinesisProducer(
            stream_name=stream_name,
            region=region,
            max_retries=max_retries,
            retry_base_delay=retry_base_delay,
            validate_stream=True
        )
    except ValueError as e:
        print(f"❌ Configuration error: {e}")
        print("\nPlease ensure:")
        print(f"  1. The Kinesis stream '{stream_name}' exists in region '{region}'")
        print("  2. Your AWS credentials have permission to access the stream")
        print("\nYou can set environment variables to configure the producer:")
        print("  export KINESIS_STREAM_NAME=your-stream-name")
        print("  export AWS_REGION=your-region")
        return
    except Exception as e:
        print(f"❌ Failed to initialize producer: {e}")
        return

    print("✅ Stream validated successfully!")
    print()
    
    while True:
        print("Choose an option:")
        print("1. Send single record")
        print("2. Send batch of records")
        print("3. Run continuous producer")
        print("4. Exit")
        
        choice = input("\nEnter your choice (1-4): ").strip()
        
        if choice == '1':
            # Send single record
            record = producer.generate_sensor_record()
            print(f"Generated record: {json.dumps(record, indent=2)}")
            
            if producer.send_record(record):
                print("✅ Record sent successfully!")
            else:
                print("❌ Failed to send record")
        
        elif choice == '2':
            # Send batch of records
            try:
                count = int(input("Enter number of records to send (1-500): "))
                if 1 <= count <= 500:
                    records = [producer.generate_sensor_record() for _ in range(count)]
                    print(f"Generated {count} records")
                    
                    sent_count = producer.send_batch_records(records)
                    print(f"✅ Successfully sent {sent_count} out of {count} records")
                else:
                    print("❌ Please enter a number between 1 and 500")
            except ValueError:
                print("❌ Please enter a valid number")
        
        elif choice == '3':
            # Run continuous producer
            try:
                rate = int(input("Enter records per second (1-100): "))
                duration = int(input("Enter duration in seconds: "))
                
                if 1 <= rate <= 100 and duration > 0:
                    producer.run_continuous_producer(rate, duration)
                else:
                    print("❌ Invalid input. Rate should be 1-100, duration should be positive")
            except ValueError:
                print("❌ Please enter valid numbers")
        
        elif choice == '4':
            print("Goodbye!")
            break
        
        else:
            print("❌ Invalid choice. Please try again.")
        
        print()

if __name__ == "__main__":
    main()
