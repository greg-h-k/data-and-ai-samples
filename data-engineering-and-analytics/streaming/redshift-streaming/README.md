# Redshift Streaming Ingestion from Kinesis Data Streams

> **Services:** Amazon Kinesis Data Streams, Amazon Redshift, AWS IAM
> **Complexity:** Intermediate
> **Tags:** `streaming` `real-time` `iot` `data-ingestion` `materialized-views`

This sample demonstrates how to stream data directly from Amazon Kinesis Data Streams into Amazon Redshift using native streaming ingestion with materialized views.

## Overview

### What This Sample Does

This project provides a complete working example of:

1. **Data Producer**: A Python script that generates simulated IoT sensor data and publishes it to Kinesis Data Streams
2. **Streaming Ingestion**: SQL scripts that create Redshift materialized views to consume data directly from Kinesis in near real-time
3. **Data Transformation**: Examples of parsing JSON data, handling different binary encodings, and computing derived fields

### Why Use Streaming Ingestion?

**Traditional ETL Pipeline:**
```
Kinesis → S3 → Glue/Lambda ETL → Redshift
         ↓
    Minutes to hours latency
    Complex infrastructure
    Multiple failure points
```

**Streaming Ingestion (This Approach):**
```
Kinesis → Redshift Materialized View
         ↓
    Seconds latency
    No ETL infrastructure
    Automatic refresh
```

**Benefits:**
- **Near real-time analytics**: Data is available in Redshift within seconds of arriving in Kinesis
- **Simplified architecture**: No need for intermediate storage (S3) or ETL jobs (Glue/Lambda)
- **Cost reduction**: Eliminate data movement costs and ETL compute
- **Automatic scaling**: Redshift handles the streaming ingestion automatically
- **Built-in data quality**: Filter and validate data as it's ingested

### Use Cases

- Real-time IoT sensor monitoring and analytics
- Live dashboards and operational metrics
- Streaming data validation and quality checks
- Event-driven analytics pipelines

## Architecture

```
┌─────────────────────┐
│   IoT Sensors       │
│   (Simulated)       │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│  kinesis_producer   │
│  (Python Script)    │
│  - 20 sensors       │
│  - Temperature data │
│  - Status updates   │
└─────────┬───────────┘
          │ put_records()
          ▼
┌─────────────────────┐
│  Kinesis Data       │
│  Stream             │
│  (demo-stream)      │
└─────────┬───────────┘
          │ Streaming ingestion
          ▼
┌─────────────────────┐
│  Redshift           │
│  Materialized View  │
│  - Auto-refresh     │
│  - JSON parsing     │
│  - Data validation  │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│  Analytics Queries  │
│  - Real-time data   │
│  - Aggregations     │
│  - Alerts           │
└─────────────────────┘
```

## Prerequisites

### AWS Resources

1. **Amazon Kinesis Data Stream**
   - Create a stream in your target region
   - Note the stream name (default: `demo-stream`)

2. **Amazon Redshift Cluster or Serverless Workgroup**
   - Provisioned cluster or Serverless namespace
   - Network connectivity to Kinesis (VPC endpoints or public access)

3. **IAM Role for Redshift**
   - Create an IAM role that Redshift can assume
   - Attach the following policy (customize the resource ARN):

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "kinesis:GetRecords",
           "kinesis:GetShardIterator",
           "kinesis:DescribeStream",
           "kinesis:DescribeStreamSummary",
           "kinesis:ListShards"
         ],
         "Resource": "arn:aws:kinesis:*:YOUR_ACCOUNT_ID:stream/demo-stream"
       }
     ]
   }
   ```

4. **AWS Credentials**
   - Configure AWS CLI credentials or use IAM roles
   - The producer needs `kinesis:PutRecord` and `kinesis:PutRecords` permissions

### Local Environment

- Python 3.8+
- pip (Python package manager)
- AWS CLI configured with appropriate credentials

## Installation

1. **Clone the repository:**
   ```bash
   cd streaming/redshift-streaming
   ```

2. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure the producer** (optional - uses environment variables):
   ```bash
   export KINESIS_STREAM_NAME=demo-stream
   export AWS_REGION=us-east-1
   export MAX_RETRIES=3
   export RETRY_BASE_DELAY=0.5
   ```

## Setup Guide

### Step 1: Create the Kinesis Stream

Using AWS CLI:
```bash
aws kinesis create-stream \
  --stream-name demo-stream \
  --shard-count 2 \
  --region us-east-1
```

Or use the AWS Console to create a stream.

### Step 2: Configure Redshift IAM Role

1. Create an IAM role with the Kinesis read policy shown in Prerequisites
2. Associate the role with your Redshift cluster/namespace
3. Note the role ARN for use in the SQL scripts

### Step 3: Set Up Redshift Streaming Ingestion

Connect to your Redshift cluster and run the SQL scripts:

**For JSON data (most common):**

Edit `redshift_streaming_mv.sql`:
- Replace `YOUR_ACCOUNT_ID` with your AWS account ID
- Replace `YOUR_KINESIS_STREAM_NAME` with your stream name

```sql
-- Run in Redshift Query Editor or psql
\i redshift_streaming_mv.sql
```

**For binary-encoded data:**

Edit `redshift_binary_decode_streaming_mv.sql`:
- Replace `YOUR_ACCOUNT_ID` with your AWS account ID
- Replace `YOUR_KINESIS_STREAM_NAME` with your stream name
- Choose the appropriate decoding method (Base64, UTF-8, or Hex)

```sql
\i redshift_binary_decode_streaming_mv.sql
```

### Step 4: Run the Producer

```bash
python kinesis_producer.py
```

The interactive menu allows you to:
1. **Send single record**: Test with one sensor reading
2. **Send batch of records**: Send 1-500 records at once
3. **Run continuous producer**: Sustained throughput (1-100 records/sec)

### Step 5: Query the Data

After sending some records, query the materialized view:

```sql
-- Recent sensor readings
SELECT
    sensor_id,
    current_temperature,
    status,
    temperature_category,
    approximate_arrival_timestamp
FROM sensor_data_stream
WHERE approximate_arrival_timestamp >= DATEADD(minute, -5, GETDATE())
ORDER BY approximate_arrival_timestamp DESC
LIMIT 20;

-- Temperature alerts
SELECT
    sensor_id,
    current_temperature,
    temperature_category
FROM sensor_data_stream
WHERE temperature_category IN ('HIGH', 'LOW')
    AND approximate_arrival_timestamp >= DATEADD(hour, -1, GETDATE());

-- Sensor status summary
SELECT
    status,
    COUNT(*) as record_count,
    AVG(current_temperature) as avg_temperature
FROM sensor_data_stream
WHERE approximate_arrival_timestamp >= DATEADD(hour, -1, GETDATE())
GROUP BY status
ORDER BY record_count DESC;
```

## File Descriptions

| File | Description |
|------|-------------|
| `kinesis_producer.py` | Python script that generates and sends sensor data to Kinesis |
| `redshift_streaming_mv.sql` | Creates a materialized view for JSON streaming ingestion |
| `redshift_binary_decode_streaming_mv.sql` | Creates materialized views for binary-encoded data with multiple decoding options |
| `requirements.txt` | Python dependencies |

## Configuration Reference

### Environment Variables (Producer)

| Variable | Default | Description |
|----------|---------|-------------|
| `KINESIS_STREAM_NAME` | `demo-stream` | Name of the Kinesis stream |
| `AWS_REGION` | `us-east-1` | AWS region |
| `MAX_RETRIES` | `3` | Maximum retry attempts for failed records |
| `RETRY_BASE_DELAY` | `0.5` | Base delay (seconds) for exponential backoff |

### Producer Features

- **Stream validation**: Verifies the stream exists before sending data
- **Retry logic**: Exponential backoff for transient failures
- **Batch optimization**: Uses `put_records` for efficient bulk sends
- **Circuit breaker**: Stops after 5 consecutive failures to prevent runaway errors
- **Partition key distribution**: Uses sensor_id for even shard distribution

### Materialized View Options

**redshift_streaming_mv.sql:**
- Simple JSON parsing with `JSON_EXTRACT_PATH_TEXT`
- Computed fields (temperature_category)
- Data quality flags
- 24-hour rolling window

**redshift_binary_decode_streaming_mv.sql:**
- **Option A (Recommended)**: Optimized CTE approach - decode once, extract many
- **Option B**: Direct Base64 decoding
- **Option C**: UTF-8 binary decoding
- **Option D**: Hex decoding
- **Validation view**: Auto-detects encoding format

## Troubleshooting

### Producer Issues

**"Stream does not exist" error:**
- Verify the stream name and region match your Kinesis stream
- Check AWS credentials have `kinesis:DescribeStream` permission

**Throttling errors:**
- Reduce `records_per_second` in continuous mode
- Increase Kinesis shard count for higher throughput

### Redshift Issues

**"Access denied" creating external schema:**
- Verify the IAM role ARN is correct
- Ensure the role is associated with your Redshift cluster
- Check the role has Kinesis read permissions

**Empty materialized view:**
- Verify data is being sent to Kinesis (check CloudWatch metrics)
- Check the stream name in the SQL matches exactly (case-sensitive)
- Run `REFRESH MATERIALIZED VIEW view_name;` to force a refresh

**JSON parsing errors:**
- Use the `binary_decode_validation` view to identify the encoding format
- Ensure the JSON structure matches the field extraction in your view

## Best Practices

1. **Use the CTE approach** for binary-encoded data to avoid redundant decoding
2. **Set appropriate time filters** in materialized views to limit data volume
3. **Monitor Kinesis throughput** to ensure shards aren't overwhelmed
4. **Use partition keys wisely** for even data distribution
5. **Enable auto-refresh** for continuous data availability

## Cleanup

Follow these steps to remove all resources and avoid ongoing charges.

### Step 1: Drop Redshift Objects

Connect to your Redshift cluster and run:

```sql
-- Drop the materialized view
DROP MATERIALIZED VIEW IF EXISTS sensor_data_stream;

-- Drop the external schema
DROP SCHEMA IF EXISTS kinesis_schema;
```

If you used the binary decoding options, also drop those:

```sql
DROP MATERIALIZED VIEW IF EXISTS sensor_data_stream_binary;
DROP VIEW IF EXISTS binary_decode_validation;
```

### Step 2: Delete the Kinesis Stream

Using AWS CLI:

```bash
aws kinesis delete-stream \
  --stream-name demo-stream \
  --region us-east-1
```

Wait for the stream to be deleted:

```bash
aws kinesis describe-stream \
  --stream-name demo-stream \
  --region us-east-1
# Should return "ResourceNotFoundException" when deleted
```

### Step 3: Clean Up IAM Role (Optional)

If you created a dedicated IAM role for this sample:

```bash
# Detach the policy first
aws iam detach-role-policy \
  --role-name RedshiftKinesisRole \
  --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/RedshiftKinesisPolicy

# Delete the policy
aws iam delete-policy \
  --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/RedshiftKinesisPolicy

# Delete the role
aws iam delete-role \
  --role-name RedshiftKinesisRole
```

### Step 4: Verify Cleanup

Confirm all resources are removed:

```bash
# Verify Kinesis stream is deleted
aws kinesis list-streams --region us-east-1

# Verify IAM role is deleted (if applicable)
aws iam get-role --role-name RedshiftKinesisRole
# Should return "NoSuchEntity" error
```

**Note:** If you're using an existing Redshift cluster for other purposes, do not delete it. Only remove the streaming-specific objects (materialized views and external schema).

## Further Reading

- [Amazon Redshift Streaming Ingestion](https://docs.aws.amazon.com/redshift/latest/dg/materialized-view-streaming-ingestion.html)
- [Amazon Kinesis Data Streams Developer Guide](https://docs.aws.amazon.com/streams/latest/dev/introduction.html)
- [Redshift Materialized Views](https://docs.aws.amazon.com/redshift/latest/dg/materialized-view-overview.html)
