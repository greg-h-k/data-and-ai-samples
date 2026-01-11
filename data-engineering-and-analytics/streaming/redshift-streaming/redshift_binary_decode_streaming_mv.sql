-- Redshift Materialized View for Binary-Encoded Kinesis Data
-- This handles common binary encoding formats before JSON parsing
--
-- RECOMMENDED: Use the optimized CTE approach below (Option A) which decodes
-- data once and extracts all fields efficiently. Other options are provided
-- as alternatives for specific use cases.

-- Step 1: Create external schema for Kinesis
CREATE EXTERNAL SCHEMA IF NOT EXISTS kinesis_binary_schema
FROM KINESIS
IAM_ROLE 'arn:aws:iam::YOUR_ACCOUNT_ID:role/RedshiftKinesisRole';

-- =============================================================================
-- OPTION A: OPTIMIZED CTE APPROACH (RECOMMENDED)
-- =============================================================================
-- This is the best practice approach: decode the binary data once in a CTE,
-- then extract all fields from the parsed JSON. This avoids redundant decoding
-- operations and provides the best query performance.

CREATE MATERIALIZED VIEW sensor_data_optimized_decode AS
WITH decoded_data AS (
    SELECT
        -- Choose the appropriate decoding method for your data:
        FROM_BASE64(kinesis_data) as json_string,  -- For Base64 encoding
        -- kinesis_data::VARCHAR(MAX) as json_string,  -- For UTF-8 encoding
        -- FROM_HEX(kinesis_data)::VARCHAR(MAX) as json_string,  -- For Hex encoding

        approximate_arrival_timestamp,
        partition_key,
        shard_id,
        sequence_number,
        kinesis_data as original_data
    FROM kinesis_binary_schema."YOUR_KINESIS_STREAM_NAME"
    WHERE approximate_arrival_timestamp >= DATEADD(day, -7, GETDATE())
),
parsed_data AS (
    SELECT
        JSON_PARSE(json_string) as json_obj,
        json_string,
        approximate_arrival_timestamp,
        partition_key,
        shard_id,
        sequence_number,
        original_data
    FROM decoded_data
    WHERE JSON_PARSE(json_string) IS NOT NULL
)
SELECT
    -- Extract all fields from parsed JSON
    json_obj.sensor_id::INTEGER as sensor_id,
    json_obj.current_temperature::INTEGER as current_temperature,
    json_obj.status::VARCHAR(50) as status,
    json_obj.created_date::DATE as created_date,

    -- Nested objects (if present in your data)
    json_obj.device.type::VARCHAR(50) as device_type,
    json_obj.device.model::VARCHAR(100) as device_model,
    json_obj.location.building::VARCHAR(100) as building,
    json_obj.location.floor::INTEGER as floor,

    -- Arrays (if present in your data)
    json_obj.measurements[0].value::DECIMAL(8,2) as first_measurement_value,
    json_obj.measurements[0].unit::VARCHAR(20) as first_measurement_unit,
    JSON_ARRAY_LENGTH(json_obj, 'measurements') as measurement_count,

    -- Configuration fields (if present in your data)
    json_obj.config.sampling_rate::INTEGER as sampling_rate,
    json_obj.config.enabled::BOOLEAN as config_enabled,

    -- Computed fields
    CASE
        WHEN json_obj.current_temperature::INTEGER > json_obj.config.threshold_high::INTEGER
        THEN 'HIGH'
        WHEN json_obj.current_temperature::INTEGER < json_obj.config.threshold_low::INTEGER
        THEN 'LOW'
        ELSE 'NORMAL'
    END as temperature_status,

    -- Time fields
    approximate_arrival_timestamp,
    DATE_TRUNC('hour', approximate_arrival_timestamp) as arrival_hour,

    -- Metadata
    partition_key,
    shard_id,
    sequence_number,

    -- Debug fields (can be removed in production)
    json_string as decoded_json_for_debug,
    original_data as binary_data_for_debug

FROM parsed_data;

-- Enable auto-refresh for the optimized view
ALTER MATERIALIZED VIEW sensor_data_optimized_decode AUTO REFRESH YES;

-- =============================================================================
-- OPTION B: Base64 Encoded JSON Data (Simple Approach)
-- =============================================================================
-- Use this when your data is Base64 encoded and you need a simpler view
-- with fewer fields. Less efficient than Option A due to repeated decoding.

CREATE MATERIALIZED VIEW sensor_data_base64_decoded AS
SELECT
    -- Decode Base64 to get JSON string, then parse
    JSON_PARSE(FROM_BASE64(kinesis_data)) as parsed_json,

    -- Extract fields from decoded JSON
    JSON_PARSE(FROM_BASE64(kinesis_data)).sensor_id::INTEGER as sensor_id,
    JSON_PARSE(FROM_BASE64(kinesis_data)).current_temperature::INTEGER as current_temperature,
    JSON_PARSE(FROM_BASE64(kinesis_data)).status::VARCHAR(50) as status,
    JSON_PARSE(FROM_BASE64(kinesis_data)).created_date::DATE as created_date,

    -- Extract nested objects
    JSON_PARSE(FROM_BASE64(kinesis_data)).device.type::VARCHAR(50) as device_type,
    JSON_PARSE(FROM_BASE64(kinesis_data)).location.building::VARCHAR(100) as building,

    -- Kinesis metadata
    approximate_arrival_timestamp,
    partition_key,
    shard_id,
    sequence_number,

    -- Store original binary data for debugging
    kinesis_data as original_binary_data,

    -- Store decoded JSON string for validation
    FROM_BASE64(kinesis_data) as decoded_json_string

FROM kinesis_binary_schema."YOUR_KINESIS_STREAM_NAME"
WHERE
    approximate_arrival_timestamp >= DATEADD(day, -7, GETDATE())
    -- Validate that decoded data is valid JSON
    AND JSON_PARSE(FROM_BASE64(kinesis_data)) IS NOT NULL;

-- =============================================================================
-- OPTION C: UTF-8 Encoded Binary Data
-- =============================================================================
-- Use this when your Kinesis data is UTF-8 encoded (most common for JSON producers)

CREATE MATERIALIZED VIEW sensor_data_utf8_decoded AS
SELECT
    -- Convert binary to UTF-8 string, then parse JSON
    JSON_PARSE(kinesis_data::VARCHAR(MAX)) as parsed_json,

    -- Extract fields from decoded JSON
    JSON_PARSE(kinesis_data::VARCHAR(MAX)).sensor_id::INTEGER as sensor_id,
    JSON_PARSE(kinesis_data::VARCHAR(MAX)).current_temperature::INTEGER as current_temperature,
    JSON_PARSE(kinesis_data::VARCHAR(MAX)).status::VARCHAR(50) as status,

    -- Kinesis metadata
    approximate_arrival_timestamp,
    partition_key,
    shard_id,

    -- Store decoded string
    kinesis_data::VARCHAR(MAX) as decoded_json_string

FROM kinesis_binary_schema."YOUR_KINESIS_STREAM_NAME"
WHERE
    approximate_arrival_timestamp >= DATEADD(day, -7, GETDATE())
    AND JSON_PARSE(kinesis_data::VARCHAR(MAX)) IS NOT NULL;

-- =============================================================================
-- OPTION D: Hex-Encoded Binary Data
-- =============================================================================
-- Use this when your data is hex-encoded

CREATE MATERIALIZED VIEW sensor_data_hex_decoded AS
SELECT
    -- Convert hex string to binary, then to UTF-8, then parse JSON
    JSON_PARSE(FROM_HEX(kinesis_data)::VARCHAR(MAX)) as parsed_json,

    -- Extract fields
    JSON_PARSE(FROM_HEX(kinesis_data)::VARCHAR(MAX)).sensor_id::INTEGER as sensor_id,
    JSON_PARSE(FROM_HEX(kinesis_data)::VARCHAR(MAX)).current_temperature::INTEGER as current_temperature,

    -- Kinesis metadata
    approximate_arrival_timestamp,
    partition_key,

    -- Store intermediate values for debugging
    FROM_HEX(kinesis_data)::VARCHAR(MAX) as decoded_json_string

FROM kinesis_binary_schema."YOUR_KINESIS_STREAM_NAME"
WHERE
    approximate_arrival_timestamp >= DATEADD(day, -7, GETDATE())
    AND JSON_PARSE(FROM_HEX(kinesis_data)::VARCHAR(MAX)) IS NOT NULL;

-- =============================================================================
-- DATA VALIDATION VIEW
-- =============================================================================
-- This view helps identify which encoding format your data uses.
-- Run this first to determine which decoding method to use.

CREATE MATERIALIZED VIEW binary_decode_validation AS
SELECT
    approximate_arrival_timestamp,
    partition_key,
    shard_id,

    -- Test different decoding methods
    CASE
        WHEN JSON_PARSE(FROM_BASE64(kinesis_data)) IS NOT NULL THEN 'BASE64_SUCCESS'
        WHEN JSON_PARSE(kinesis_data::VARCHAR(MAX)) IS NOT NULL THEN 'UTF8_SUCCESS'
        WHEN JSON_PARSE(FROM_HEX(kinesis_data)::VARCHAR(MAX)) IS NOT NULL THEN 'HEX_SUCCESS'
        ELSE 'DECODE_FAILED'
    END as decode_method,

    -- Show first 100 characters of decoded data for inspection
    LEFT(
        CASE
            WHEN JSON_PARSE(FROM_BASE64(kinesis_data)) IS NOT NULL THEN FROM_BASE64(kinesis_data)
            WHEN JSON_PARSE(kinesis_data::VARCHAR(MAX)) IS NOT NULL THEN kinesis_data::VARCHAR(MAX)
            WHEN JSON_PARSE(FROM_HEX(kinesis_data)::VARCHAR(MAX)) IS NOT NULL THEN FROM_HEX(kinesis_data)::VARCHAR(MAX)
            ELSE 'FAILED_TO_DECODE'
        END,
        100
    ) as decoded_preview,

    -- Original binary data length
    LENGTH(kinesis_data) as binary_data_length,

    -- Show first few bytes of binary data
    LEFT(kinesis_data, 50) as binary_preview

FROM kinesis_binary_schema."YOUR_KINESIS_STREAM_NAME"
WHERE approximate_arrival_timestamp >= DATEADD(hour, -1, GETDATE())
LIMIT 100;

-- Enable auto-refresh for validation view
ALTER MATERIALIZED VIEW binary_decode_validation AUTO REFRESH YES;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================
-- Note: Redshift automatically manages indexes on materialized views.
-- Manual index creation on MVs is not supported in Redshift Serverless
-- and may not be needed in provisioned clusters due to automatic optimization.

GRANT SELECT ON sensor_data_optimized_decode TO PUBLIC;
GRANT SELECT ON binary_decode_validation TO PUBLIC;
-- Or grant to specific users/groups:
-- GRANT SELECT ON sensor_data_optimized_decode TO data_analysts;

-- =============================================================================
-- EXAMPLE QUERIES
-- =============================================================================

-- Query 1: Check what decoding method works for your data
/*
SELECT
    decode_method,
    COUNT(*) as record_count,
    AVG(binary_data_length) as avg_binary_length
FROM binary_decode_validation
GROUP BY decode_method
ORDER BY record_count DESC;
*/

-- Query 2: Inspect decoded data samples
/*
SELECT
    decode_method,
    decoded_preview,
    binary_preview
FROM binary_decode_validation
WHERE decode_method != 'DECODE_FAILED'
LIMIT 10;
*/

-- Query 3: Validate sensor data after decoding
/*
SELECT
    sensor_id,
    current_temperature,
    device_type,
    building,
    temperature_status,
    approximate_arrival_timestamp
FROM sensor_data_optimized_decode
WHERE arrival_hour >= DATEADD(hour, -2, GETDATE())
ORDER BY approximate_arrival_timestamp DESC
LIMIT 50;
*/
