CREATE TABLE raw_tickets (
    status VARCHAR(50),
    ticket_id INT,
    priority VARCHAR(20),
    source VARCHAR(20),
    topic VARCHAR(100),
    agent_group VARCHAR(50),
    agent_name VARCHAR(100),
    created_time TIMESTAMP,
    expected_sla_resolve TIMESTAMP,
    expected_sla_first_response TIMESTAMP,
    first_response_time TIMESTAMP,
    sla_first_response VARCHAR(20),
    resolution_time TIMESTAMP,
    sla_resolution VARCHAR(20),
    close_time TIMESTAMP,
    agent_interactions NUMERIC,
    survey_results NUMERIC,
    product_group VARCHAR(100),
    support_level VARCHAR(20),
    country VARCHAR(100),
    latitude NUMERIC,
    longitude NUMERIC
);



UPDATE Raw_tickets 
SET topic='Pricing and licensing'
Where topic='Pricing and Licensing';



-- Dim_Agent
CREATE TABLE dim_agent AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY agent_name) AS agent_id,
    agent_name,
    agent_group,
    support_level
FROM (SELECT DISTINCT agent_name, agent_group, support_level FROM raw_tickets) t;

-- Dim_Country
CREATE TABLE dim_country AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY country) AS country_id,
    country,
    latitude,
    longitude
FROM (SELECT DISTINCT country, latitude, longitude FROM raw_tickets) t;

-- Dim_Priority
CREATE TABLE dim_priority AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY priority) AS priority_id,
    priority
FROM (SELECT DISTINCT priority FROM raw_tickets) t;

-- Dim_Topic
CREATE TABLE dim_topic AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY topic) AS topic_id,
    topic
FROM (SELECT DISTINCT topic FROM raw_tickets) t;

-- Dim_Source
CREATE TABLE dim_source AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY source) AS source_id,
    source
FROM (SELECT DISTINCT source FROM raw_tickets) t;

-- Dim_ProductGroup
CREATE TABLE dim_product_group AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY product_group) AS product_group_id,
    product_group
FROM (SELECT DISTINCT product_group FROM raw_tickets) t;

-- Dim_Date
CREATE TABLE dim_date AS
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INT AS date_id,
    d AS date,
    EXTRACT(DAY FROM d) AS day,
    EXTRACT(MONTH FROM d) AS month,
    TO_CHAR(d, 'Month') AS month_name,
    'Q' || EXTRACT(QUARTER FROM d) AS quarter,
    EXTRACT(YEAR FROM d) AS year,
    TO_CHAR(d, 'Day') AS weekday_name,
    CASE WHEN EXTRACT(ISODOW FROM d) IN (6,7) THEN TRUE ELSE FALSE END AS is_weekend
FROM generate_series('2023-01-01'::date, '2024-01-31'::date, '1 day') AS d;


CREATE TABLE fact_tickets AS
SELECT
    r.ticket_id,
    r.status,
    a.agent_id,
    c.country_id,
    p.priority_id,
    t.topic_id,
    s.source_id,
    pg.product_group_id,
    TO_CHAR(r.created_time, 'YYYYMMDD')::INT AS created_date_id,
    r.created_time,
    r.expected_sla_first_response,
    r.first_response_time,
    r.sla_first_response,
    r.expected_sla_resolve,
    r.resolution_time,
    r.sla_resolution,
    r.close_time,
    r.agent_interactions,
    r.survey_results
FROM raw_tickets r
JOIN dim_agent a ON r.agent_name = a.agent_name AND r.agent_group = a.agent_group AND r.support_level = a.support_level
JOIN dim_country c ON r.country = c.country AND r.latitude = c.latitude AND r.longitude = c.longitude
JOIN dim_priority p ON r.priority = p.priority
JOIN dim_topic t ON r.topic = t.topic
JOIN dim_source s ON r.source = s.source
JOIN dim_product_group pg ON r.product_group = pg.product_group;