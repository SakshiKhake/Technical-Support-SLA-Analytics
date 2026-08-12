-- ============================================
-- Technical Support Ticket Analysis - SQL Queries
-- Author: Sakshi
-- Database: PostgreSQL
-- Purpose: Analytical queries supporting the Power BI SLA dashboard
-- ============================================

-- Query 1: SLA Compliance % by Agent
-- Business question: Which agents are most reliable at meeting resolution deadlines?
SELECT a.agent_name,
       COUNT(*) AS total_tickets,
       ROUND(100.0 * SUM(CASE WHEN f.sla_resolution = 'Within SLA' THEN 1 ELSE 0 END) / COUNT(*), 2) AS sla_pct
FROM fact_tickets f
JOIN dim_agent a ON f.agent_id = a.agent_id
GROUP BY a.agent_name
ORDER BY sla_pct DESC;


-- Query 2: Average Resolution Time (hours) by Priority
-- Business question: Are high-priority tickets actually resolved faster than low-priority ones?
SELECT p.priority,
       ROUND(AVG(EXTRACT(EPOCH FROM (f.resolution_time - f.created_time))/3600)::NUMERIC, 2) AS avg_resolution_hours
FROM fact_tickets f
JOIN dim_priority p ON f.priority_id = p.priority_id
WHERE f.resolution_time IS NOT NULL
GROUP BY p.priority
ORDER BY avg_resolution_hours DESC;


-- Query 3: SLA Breach % by Topic
-- Business question: Which issue types are hardest for the team to resolve on time?
SELECT t.topic,
       COUNT(*) FILTER (WHERE f.sla_resolution = 'SLA Violated') AS breaches,
       COUNT(*) AS total,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.sla_resolution = 'SLA Violated') / COUNT(*), 2) AS breach_pct
FROM fact_tickets f
JOIN dim_topic t ON f.topic_id = t.topic_id
GROUP BY t.topic
ORDER BY breach_pct DESC;


-- Query 4: Monthly Ticket Volume Trend
-- Business question: Is ticket volume increasing, decreasing, or seasonal across the year?
SELECT d.year, d.month, d.month_name, COUNT(*) AS ticket_count
FROM fact_tickets f
JOIN dim_date d ON f.created_date_id = d.date_id
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;