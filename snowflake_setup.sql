-- =============================================================================
-- Olist Analytics - Snowflake Infrastructure Setup
-- Account: VPHIWTB-HD71021
-- Run as: ACCOUNTADMIN
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- =============================================================================
-- 1. DATABASE & SCHEMAS
-- =============================================================================

CREATE OR REPLACE DATABASE olist_analytics;

-- Medallion layers
CREATE OR REPLACE SCHEMA olist_analytics.raw;           -- Source CSVs land here (not a dbt layer)
CREATE OR REPLACE SCHEMA olist_analytics.staging;       -- stg_* models (cast, rename, clean)
CREATE OR REPLACE SCHEMA olist_analytics.intermediate;  -- int_* models (joins, business logic)
CREATE OR REPLACE SCHEMA olist_analytics.marts;         -- dim_* / fct_* (BI-facing)

-- CI schema (dbt slim CI runs here, isolated from dev/prod)
CREATE OR REPLACE SCHEMA olist_analytics.ci;

-- =============================================================================
-- 2. WAREHOUSES (purpose-separated, right-sized for dev)
-- =============================================================================

-- Loading: used by SnowSQL COPY INTO
CREATE OR REPLACE WAREHOUSE olist_loading_wh
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND   = 60
    AUTO_RESUME    = TRUE
    COMMENT        = 'Dev: XSMALL. Prod: XSMALL. Used for COPY INTO from stage.';

-- Transforming: used by dbt runs
CREATE OR REPLACE WAREHOUSE olist_transform_wh
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND   = 60
    AUTO_RESUME    = TRUE
    COMMENT        = 'Dev: XSMALL. Prod: SMALL. Used by dbt build/run/test.';

-- Analytics: used by BI tools (Metabase / Lightdash)
CREATE OR REPLACE WAREHOUSE olist_analytics_wh
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND   = 60
    AUTO_RESUME    = TRUE
    COMMENT        = 'Dev: XSMALL. Prod: MEDIUM. Used by BI tools, read-only.';

-- =============================================================================
-- 3. ROLES  (grant to roles, never directly to users)
-- =============================================================================

-- loader: owns raw schema, runs COPY INTO
CREATE ROLE IF NOT EXISTS loader;

-- transformer: runs dbt, reads raw, writes staging/intermediate/marts
CREATE ROLE IF NOT EXISTS transformer;

-- reporter: read-only on marts, used by BI tools
CREATE ROLE IF NOT EXISTS reporter;

-- Role hierarchy: SYSADMIN owns all custom roles
GRANT ROLE loader      TO ROLE sysadmin;
GRANT ROLE transformer TO ROLE sysadmin;
GRANT ROLE reporter    TO ROLE sysadmin;

-- =============================================================================
-- 4. WAREHOUSE GRANTS
-- =============================================================================

GRANT USAGE ON WAREHOUSE olist_loading_wh   TO ROLE loader;
GRANT USAGE ON WAREHOUSE olist_transform_wh TO ROLE transformer;
GRANT USAGE ON WAREHOUSE olist_analytics_wh TO ROLE reporter;
-- transformer also needs analytics wh for dbt docs / CI
GRANT USAGE ON WAREHOUSE olist_analytics_wh TO ROLE transformer;

-- =============================================================================
-- 5. DATABASE & SCHEMA GRANTS
-- =============================================================================

-- loader
GRANT USAGE ON DATABASE olist_analytics          TO ROLE loader;
GRANT USAGE ON SCHEMA olist_analytics.raw        TO ROLE loader;
GRANT ALL   ON SCHEMA olist_analytics.raw        TO ROLE loader;
GRANT ALL   ON ALL TABLES    IN SCHEMA olist_analytics.raw TO ROLE loader;
GRANT ALL   ON FUTURE TABLES IN SCHEMA olist_analytics.raw TO ROLE loader;

-- transformer
GRANT USAGE ON DATABASE olist_analytics TO ROLE transformer;

GRANT USAGE  ON SCHEMA olist_analytics.raw          TO ROLE transformer;
GRANT SELECT ON ALL TABLES    IN SCHEMA olist_analytics.raw TO ROLE transformer;
GRANT SELECT ON FUTURE TABLES IN SCHEMA olist_analytics.raw TO ROLE transformer;

GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA olist_analytics.staging       TO ROLE transformer;
GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA olist_analytics.intermediate  TO ROLE transformer;
GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA olist_analytics.marts         TO ROLE transformer;
GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA olist_analytics.ci            TO ROLE transformer;

GRANT ALL ON ALL TABLES    IN SCHEMA olist_analytics.staging      TO ROLE transformer;
GRANT ALL ON FUTURE TABLES IN SCHEMA olist_analytics.staging      TO ROLE transformer;
GRANT ALL ON ALL TABLES    IN SCHEMA olist_analytics.intermediate TO ROLE transformer;
GRANT ALL ON FUTURE TABLES IN SCHEMA olist_analytics.intermediate TO ROLE transformer;
GRANT ALL ON ALL TABLES    IN SCHEMA olist_analytics.marts        TO ROLE transformer;
GRANT ALL ON FUTURE TABLES IN SCHEMA olist_analytics.marts        TO ROLE transformer;
GRANT ALL ON ALL TABLES    IN SCHEMA olist_analytics.ci           TO ROLE transformer;
GRANT ALL ON FUTURE TABLES IN SCHEMA olist_analytics.ci           TO ROLE transformer;

-- reporter
GRANT USAGE  ON DATABASE olist_analytics              TO ROLE reporter;
GRANT USAGE  ON SCHEMA   olist_analytics.marts        TO ROLE reporter;
GRANT SELECT ON ALL TABLES    IN SCHEMA olist_analytics.marts TO ROLE reporter;
GRANT SELECT ON FUTURE TABLES IN SCHEMA olist_analytics.marts TO ROLE reporter;

-- =============================================================================
-- 6. ASSIGN ROLES TO USER
-- =============================================================================

GRANT ROLE loader      TO USER HADI90;
GRANT ROLE transformer TO USER HADI90;
GRANT ROLE reporter    TO USER HADI90;

-- =============================================================================
-- 7. FILE STAGE (single stage, in raw schema)
-- =============================================================================

USE SCHEMA olist_analytics.raw;

DROP STAGE IF EXISTS olist_analytics.raw.olist_stage;  -- remove duplicate

CREATE OR REPLACE STAGE olist_analytics.raw.raw_stage
    FILE_FORMAT = (
        TYPE                        = CSV
        SKIP_HEADER                 = 1
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
        NULL_IF                     = ('NULL', 'null', '')
        EMPTY_FIELD_AS_NULL         = TRUE
    )
    COMMENT = 'Single stage for all Olist CSV files. PUT files here then COPY INTO raw tables.';

GRANT READ, WRITE ON STAGE olist_analytics.raw.raw_stage TO ROLE loader;
GRANT READ         ON STAGE olist_analytics.raw.raw_stage TO ROLE transformer;

-- =============================================================================
-- 8. RAW TABLES
-- =============================================================================

USE ROLE loader;
USE SCHEMA olist_analytics.raw;

CREATE OR REPLACE TABLE raw.customers (
    customer_id             VARCHAR(50),
    customer_unique_id      VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city           VARCHAR(100),
    customer_state          VARCHAR(2)
);

CREATE OR REPLACE TABLE raw.geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat             FLOAT,
    geolocation_lng             FLOAT,
    geolocation_city            VARCHAR(100),
    geolocation_state           VARCHAR(2)
);

CREATE OR REPLACE TABLE raw.order_items (
    order_id             VARCHAR(50),
    order_item_id        INT,
    product_id           VARCHAR(50),
    seller_id            VARCHAR(50),
    shipping_limit_date  TIMESTAMP_NTZ,
    price                NUMBER(10,2),
    freight_value        NUMBER(10,2)
);

CREATE OR REPLACE TABLE raw.order_payments (
    order_id              VARCHAR(50),
    payment_sequential    INT,
    payment_type          VARCHAR(20),
    payment_installments  INT,
    payment_value         NUMBER(10,2)
);

CREATE OR REPLACE TABLE raw.order_reviews (
    review_id               VARCHAR(50),
    order_id                VARCHAR(50),
    review_score            INT,
    review_comment_title    VARCHAR(255),
    review_comment_message  TEXT,
    review_creation_date    TIMESTAMP_NTZ,
    review_answer_timestamp TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE raw.orders (
    order_id                        VARCHAR(50),
    customer_id                     VARCHAR(50),
    order_status                    VARCHAR(20),
    order_purchase_timestamp        TIMESTAMP_NTZ,
    order_approved_at               TIMESTAMP_NTZ,
    order_delivered_carrier_date    TIMESTAMP_NTZ,
    order_delivered_customer_date   TIMESTAMP_NTZ,
    order_estimated_delivery_date   DATE
);

CREATE OR REPLACE TABLE raw.products (
    product_id                  VARCHAR(50),
    product_category_name       VARCHAR(100),
    product_name_length         INT,
    product_description_length  INT,
    product_photos_qty          INT,
    product_weight_g            INT,
    product_length_cm           INT,
    product_height_cm           INT,
    product_width_cm            INT
);

CREATE OR REPLACE TABLE raw.sellers (
    seller_id               VARCHAR(50),
    seller_zip_code_prefix  VARCHAR(10),
    seller_city             VARCHAR(100),
    seller_state            VARCHAR(2)
);

CREATE OR REPLACE TABLE raw.category_translation (
    product_category_name         VARCHAR(100),
    product_category_name_english VARCHAR(100)
);

-- =============================================================================
-- 9. LOAD DATA
-- =============================================================================

COPY INTO raw.category_translation FROM @raw_stage/product_category_name_translation.csv.gz  ON_ERROR = 'CONTINUE';
COPY INTO raw.customers            FROM @raw_stage/olist_customers_dataset.csv.gz             ON_ERROR = 'CONTINUE';
COPY INTO raw.orders               FROM @raw_stage/olist_orders_dataset.csv.gz                ON_ERROR = 'CONTINUE';
COPY INTO raw.order_items          FROM @raw_stage/olist_order_items_dataset.csv.gz           ON_ERROR = 'CONTINUE';
COPY INTO raw.order_payments       FROM @raw_stage/olist_order_payments_dataset.csv.gz        ON_ERROR = 'CONTINUE';
COPY INTO raw.order_reviews        FROM @raw_stage/olist_order_reviews_dataset.csv.gz         ON_ERROR = 'CONTINUE';
COPY INTO raw.products             FROM @raw_stage/olist_products_dataset.csv.gz              ON_ERROR = 'CONTINUE';
COPY INTO raw.sellers              FROM @raw_stage/olist_sellers_dataset.csv.gz               ON_ERROR = 'CONTINUE';
COPY INTO raw.geolocation          FROM @raw_stage/olist_geolocation_dataset.csv.gz           ON_ERROR = 'CONTINUE';

-- =============================================================================
-- 10. VERIFY
-- =============================================================================

SELECT 'customers'          AS tbl, COUNT(*) AS rows FROM raw.customers           UNION ALL
SELECT 'orders'             AS tbl, COUNT(*) AS rows FROM raw.orders              UNION ALL
SELECT 'order_items'        AS tbl, COUNT(*) AS rows FROM raw.order_items         UNION ALL
SELECT 'order_payments'     AS tbl, COUNT(*) AS rows FROM raw.order_payments      UNION ALL
SELECT 'order_reviews'      AS tbl, COUNT(*) AS rows FROM raw.order_reviews       UNION ALL
SELECT 'products'           AS tbl, COUNT(*) AS rows FROM raw.products            UNION ALL
SELECT 'sellers'            AS tbl, COUNT(*) AS rows FROM raw.sellers             UNION ALL
SELECT 'geolocation'        AS tbl, COUNT(*) AS rows FROM raw.geolocation         UNION ALL
SELECT 'category_translation' AS tbl, COUNT(*) AS rows FROM raw.category_translation;
