-- Redshift Materialized View for Kinesis Data Stream Streaming Ingestion
-- This creates a materialized view that automatically refreshes with streaming data

-- Step 1: Create the external schema for Kinesis (if not exists)
CREATE EXTERNAL SCHEMA IF NOT EXISTS kinesis_schema
FROM KINESIS
IAM_ROLE 'arn:aws:iam::YOUR_ACCOUNT_ID:role/RedshiftKinesisRole';

-- Step 2: Create the materialized view for streaming ingestion
CREATE MATERIALIZED VIEW sensor_data_stream AS
SELECT 
    -- Extract JSON fields from kinesis_data
    JSON_EXTRACT_PATH_TEXT(kinesis_data, 'sensor_id')::INTEGER as sensor_id,
    JSON_EXTRACT_PATH_TEXT(kinesis_data, 'current_temperature')::INTEGER as current_temperature,
    JSON_EXTRACT_PATH_TEXT(kinesis_data, 'status') as status,
    JSON_EXTRACT_PATH_TEXT(kinesis_data, 'created_date')::DATE as created_date,
    
    -- Kinesis metadata fields
    approximate_arrival_timestamp,
    partition_key,
    shard_id,
    sequence_number,
    
    -- Additional computed fields
    CASE 
        WHEN JSON_EXTRACT_PATH_TEXT(kinesis_data, 'current_temperature')::INTEGER > 40 THEN 'HIGH'
        WHEN JSON_EXTRACT_PATH_TEXT(kinesis_data, 'current_temperature')::INTEGER < 0 THEN 'LOW'
        ELSE 'NORMAL'
    END as temperature_category,
    
    -- Extract timestamp for partitioning/filtering
    DATE_TRUNC('hour', approximate_arrival_timestamp) as arrival_hour,
    
    -- Data quality flags
    CASE 
        WHEN JSON_EXTRACT_PATH_TEXT(kinesis_data, 'sensor_id') IS NULL THEN FALSE
        WHEN JSON_EXTRACT_PATH_TEXT(kinesis_data, 'current_temperature') IS NULL THEN FALSE
        WHEN JSON_EXTRACT_PATH_TEXT(kinesis_data, 'status') IS NULL THEN FALSE
        ELSE TRUE
    END as is_valid_record

FROM kinesis_schema."YOUR_KINESIS_STREAM_NAME"
WHERE 
    -- Filter for recent data (optional)
    approximate_arrival_timestamp >= DATEADD(hour, -24, GETDATE())
    
    -- Filter out malformed JSON (optional)
    AND JSON_VALID(kinesis_data)
    
    -- Filter for specific record types (optional)
    AND JSON_EXTRACT_PATH_TEXT(kinesis_data, 'sensor_id') IS NOT NULL;

-- Step 3: Set up auto-refresh for the materialized view
ALTER MATERIALIZED VIEW sensor_data_stream AUTO REFRESH YES;

-- Step 4: Grant permissions to users/roles
-- Note: Redshift automatically manages indexes on materialized views.
-- Manual index creation on MVs is not supported in Redshift Serverless
-- and may not be needed in provisioned clusters due to automatic optimization.
GRANT SELECT ON sensor_data_stream TO PUBLIC;
-- Or grant to specific users/groups:
-- GRANT SELECT ON sensor_data_stream TO data_analysts;

-- Example queries to test the materialized view:

-- Query 1: Recent sensor readings
/*
SELECT 
    sensor_id,
    current_temperature,
    status,
    approximate_arrival_timestamp
FROM sensor_data_stream
WHERE approximate_arrival_timestamp >= DATEADD(hour, -1, GETDATE())
ORDER BY approximate_arrival_timestamp DESC
LIMIT 100;
*/

-- Query 2: Temperature alerts
/*
SELECT 
    sensor_id,
    current_temperature,
    temperature_category,
    approximate_arrival_timestamp
FROM sensor_data_stream
WHERE temperature_category IN ('HIGH', 'LOW')
    AND approximate_arrival_timestamp >= DATEADD(hour, -6, GETDATE())
ORDER BY approximate_arrival_timestamp DESC;
*/

-- Query 3: Sensor status summary
/*
SELECT 
    status,
    COUNT(*) as record_count,
    AVG(current_temperature) as avg_temperature,
    MIN(approximate_arrival_timestamp) as first_reading,
    MAX(approximate_arrival_timestamp) as last_reading
FROM sensor_data_stream
WHERE approximate_arrival_timestamp >= DATEADD(day, -1, GETDATE())
GROUP BY status
ORDER BY record_count DESC;
*/
