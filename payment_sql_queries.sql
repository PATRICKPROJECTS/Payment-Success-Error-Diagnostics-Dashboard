-- ============================================================================
-- PAYMENT SUCCESS & ERROR DIAGNOSTICS DASHBOARD
-- SQL QUERIES REFERENCE
-- 
-- Nigerian Digital Payments Analytics
-- ============================================================================

-- This document provides SQL queries to generate key metrics for the 
-- Payment Success & Error Diagnostics Dashboard from fact tables.
--
-- Tables:
--   - dim_users: User demographics and signup info
--   - fact_app_events: Step-by-step transaction flow events
--   - fact_transactions: Final transaction records

-- ============================================================================
-- 1. OVERALL SUCCESS METRICS
-- ============================================================================

-- Get final transaction status (Success vs Failure)
SELECT
  tx_id,
  MAX(event_timestamp) as last_event_time,
  MAX(CASE WHEN step = 'Transaction_Success' THEN 1 ELSE 0 END) as is_successful,
  MAX(step) as final_step
FROM fact_app_events
GROUP BY tx_id;

-- Calculate overall success rate
SELECT
  COUNT(*) as total_transactions,
  SUM(CASE WHEN final_step = 'Transaction_Success' THEN 1 ELSE 0 END) as successful_count,
  ROUND(100.0 * SUM(CASE WHEN final_step = 'Transaction_Success' THEN 1 ELSE 0 END) 
        / COUNT(*), 2) as success_rate_pct
FROM (
  SELECT
    transaction_id,
    MAX(step) as final_step
  FROM fact_app_events
  GROUP BY transaction_id
);

-- ============================================================================
-- 2. FUNNEL ANALYSIS - DROP-OFF BY STEP
-- ============================================================================

-- Transaction step progression (funnel)
SELECT
  'Transaction_Initiated' as step,
  COUNT(DISTINCT transaction_id) as user_count,
  1.0 as step_order
FROM fact_app_events
UNION ALL
SELECT
  'Payment_Method_Selected' as step,
  COUNT(DISTINCT transaction_id) as user_count,
  2.0 as step_order
FROM fact_app_events
WHERE step IN ('Payment_Method_Selected', 'PIN_Entered', 'Transaction_Success')
UNION ALL
SELECT
  'PIN_Entered' as step,
  COUNT(DISTINCT transaction_id) as user_count,
  3.0 as step_order
FROM fact_app_events
WHERE step IN ('PIN_Entered', 'Transaction_Success')
UNION ALL
SELECT
  'Transaction_Success' as step,
  COUNT(DISTINCT transaction_id) as user_count,
  4.0 as step_order
FROM fact_app_events
WHERE step = 'Transaction_Success'
ORDER BY step_order;

-- Drop-off percentage at each step
WITH step_counts AS (
  SELECT
    'Initiated' as stage,
    COUNT(DISTINCT transaction_id) as tx_count,
    1 as seq
  FROM fact_app_events
  WHERE step = 'Transaction_Initiated'
  UNION ALL
  SELECT
    'Method Selected' as stage,
    COUNT(DISTINCT transaction_id) as tx_count,
    2 as seq
  FROM fact_app_events
  WHERE step = 'Payment_Method_Selected'
  UNION ALL
  SELECT
    'PIN Entered' as stage,
    COUNT(DISTINCT transaction_id) as tx_count,
    3 as seq
  FROM fact_app_events
  WHERE step = 'PIN_Entered'
  UNION ALL
  SELECT
    'Success' as stage,
    COUNT(DISTINCT transaction_id) as tx_count,
    4 as seq
  FROM fact_app_events
  WHERE step = 'Transaction_Success'
)
SELECT
  stage,
  tx_count,
  ROUND(100.0 * tx_count / LAG(tx_count) OVER (ORDER BY seq), 2) as completion_rate_pct
FROM step_counts
ORDER BY seq;

-- ============================================================================
-- 3. GEOGRAPHIC ANALYSIS
-- ============================================================================

-- Success rate by state
SELECT
  u.location,
  COUNT(DISTINCT fe.transaction_id) as total_transactions,
  SUM(CASE WHEN fe.final_step = 'Transaction_Success' THEN 1 ELSE 0 END) as successful_tx,
  ROUND(100.0 * SUM(CASE WHEN fe.final_step = 'Transaction_Success' THEN 1 ELSE 0 END) 
        / COUNT(DISTINCT fe.transaction_id), 2) as success_rate_pct
FROM fact_app_events fe
INNER JOIN dim_users u ON fe.user_id = u.user_id
LEFT JOIN (
  SELECT
    transaction_id,
    MAX(step) as final_step
  FROM fact_app_events
  GROUP BY transaction_id
) final_status ON fe.transaction_id = final_status.transaction_id
GROUP BY u.location
ORDER BY success_rate_pct DESC;

-- ============================================================================
-- 4. PAYMENT METHOD ANALYSIS
-- ============================================================================

-- Success rate by payment method
SELECT
  ft.payment_method,
  COUNT(DISTINCT fe.transaction_id) as total_transactions,
  SUM(CASE WHEN fe.final_step = 'Transaction_Success' THEN 1 ELSE 0 END) as successful_tx,
  ROUND(100.0 * SUM(CASE WHEN fe.final_step = 'Transaction_Success' THEN 1 ELSE 0 END) 
        / COUNT(DISTINCT fe.transaction_id), 2) as success_rate_pct
FROM fact_app_events fe
INNER JOIN fact_transactions ft ON fe.transaction_id = ft.transaction_id
LEFT JOIN (
  SELECT
    transaction_id,
    MAX(step) as final_step
  FROM fact_app_events
  GROUP BY transaction_id
) final_status ON fe.transaction_id = final_status.transaction_id
GROUP BY ft.payment_method
ORDER BY success_rate_pct DESC;

-- Average transaction value by success status
SELECT
  CASE WHEN final_step = 'Transaction_Success' THEN 'Success' ELSE 'Failure' END as status,
  COUNT(*) as transaction_count,
  ROUND(AVG(amount), 0) as avg_amount,
  ROUND(SUM(amount), 0) as total_value
FROM (
  SELECT
    ft.transaction_id,
    ft.amount,
    MAX(fe.step) as final_step
  FROM fact_transactions ft
  LEFT JOIN fact_app_events fe ON ft.transaction_id = fe.transaction_id
  GROUP BY ft.transaction_id, ft.amount
)
GROUP BY CASE WHEN final_step = 'Transaction_Success' THEN 'Success' ELSE 'Failure' END;

-- ============================================================================
-- 5. DEMOGRAPHIC ANALYSIS
-- ============================================================================

-- Success rate by age group
SELECT
  u.age_group,
  COUNT(DISTINCT fe.transaction_id) as total_transactions,
  SUM(CASE WHEN fe.final_step = 'Transaction_Success' THEN 1 ELSE 0 END) as successful_tx,
  ROUND(100.0 * SUM(CASE WHEN fe.final_step = 'Transaction_Success' THEN 1 ELSE 0 END) 
        / COUNT(DISTINCT fe.transaction_id), 2) as success_rate_pct
FROM fact_app_events fe
INNER JOIN dim_users u ON fe.user_id = u.user_id
LEFT JOIN (
  SELECT
    transaction_id,
    MAX(step) as final_step
  FROM fact_app_events
  GROUP BY transaction_id
) final_status ON fe.transaction_id = final_status.transaction_id
GROUP BY u.age_group
ORDER BY success_rate_pct DESC;

-- Success rate by signup channel
SELECT
  u.signup_channel,
  COUNT(DISTINCT fe.transaction_id) as total_transactions,
  SUM(CASE WHEN fe.final_step = 'Transaction_Success' THEN 1 ELSE 0 END) as successful_tx,
  ROUND(100.0 * SUM(CASE WHEN fe.final_step = 'Transaction_Success' THEN 1 ELSE 0 END) 
        / COUNT(DISTINCT fe.transaction_id), 2) as success_rate_pct
FROM fact_app_events fe
INNER JOIN dim_users u ON fe.user_id = u.user_id
LEFT JOIN (
  SELECT
    transaction_id,
    MAX(step) as final_step
  FROM fact_app_events
  GROUP BY transaction_id
) final_status ON fe.transaction_id = final_status.transaction_id
GROUP BY u.signup_channel
ORDER BY success_rate_pct DESC;

-- ============================================================================
-- 6. TRANSACTION TYPE ANALYSIS
-- ============================================================================

-- Success rate by transaction type
SELECT
  ft.transaction_type,
  COUNT(DISTINCT fe.transaction_id) as total_transactions,
  SUM(CASE WHEN fe.final_step = 'Transaction_Success' THEN 1 ELSE 0 END) as successful_tx,
  ROUND(100.0 * SUM(CASE WHEN fe.final_step = 'Transaction_Success' THEN 1 ELSE 0 END) 
        / COUNT(DISTINCT fe.transaction_id), 2) as success_rate_pct,
  ROUND(AVG(ft.amount), 0) as avg_amount
FROM fact_app_events fe
INNER JOIN fact_transactions ft ON fe.transaction_id = ft.transaction_id
LEFT JOIN (
  SELECT
    transaction_id,
    MAX(step) as final_step
  FROM fact_app_events
  GROUP BY transaction_id
) final_status ON fe.transaction_id = final_status.transaction_id
GROUP BY ft.transaction_type
ORDER BY success_rate_pct DESC;

-- ============================================================================
-- 7. ERROR PATTERN ANALYSIS
-- ============================================================================

-- Most common failure steps
SELECT
  final_step as failure_point,
  COUNT(DISTINCT transaction_id) as failure_count,
  ROUND(100.0 * COUNT(DISTINCT transaction_id) 
        / (SELECT COUNT(DISTINCT transaction_id) FROM fact_app_events), 2) as pct_of_total
FROM (
  SELECT
    transaction_id,
    MAX(step) as final_step
  FROM fact_app_events
  GROUP BY transaction_id
)
WHERE final_step != 'Transaction_Success'
GROUP BY final_step
ORDER BY failure_count DESC;

-- ============================================================================
-- 8. TIME-BASED ANALYSIS
-- ============================================================================

-- Success rate by time of day
SELECT
  EXTRACT(HOUR FROM timestamp) as hour_of_day,
  COUNT(DISTINCT transaction_id) as total_transactions,
  SUM(CASE WHEN final_step = 'Transaction_Success' THEN 1 ELSE 0 END) as successful_tx,
  ROUND(100.0 * SUM(CASE WHEN final_step = 'Transaction_Success' THEN 1 ELSE 0 END) 
        / COUNT(DISTINCT transaction_id), 2) as success_rate_pct
FROM (
  SELECT
    fe.transaction_id,
    fe.timestamp,
    MAX(fe.step) as final_step
  FROM fact_app_events fe
  GROUP BY fe.transaction_id, fe.timestamp
)
GROUP BY EXTRACT(HOUR FROM timestamp)
ORDER BY success_rate_pct DESC;

-- ============================================================================
-- 9. USER COHORT ANALYSIS
-- ============================================================================

-- Repeat vs first-time user success
SELECT
  CASE WHEN user_tx_count = 1 THEN 'First-time' ELSE 'Repeat' END as user_type,
  COUNT(*) as total_transactions,
  SUM(CASE WHEN final_step = 'Transaction_Success' THEN 1 ELSE 0 END) as successful_tx,
  ROUND(100.0 * SUM(CASE WHEN final_step = 'Transaction_Success' THEN 1 ELSE 0 END) 
        / COUNT(*), 2) as success_rate_pct
FROM (
  SELECT
    fe.transaction_id,
    fe.user_id,
    MAX(fe.step) as final_step,
    ROW_NUMBER() OVER (PARTITION BY fe.user_id ORDER BY fe.timestamp) as user_tx_count
  FROM fact_app_events fe
)
WHERE user_tx_count IN (1, 2)  -- Mark 1st as first-time, others as repeat
GROUP BY user_type;

-- ============================================================================
-- 10. DASHBOARD KPI SUMMARY
-- ============================================================================

-- All-in-one dashboard metrics
SELECT
  (SELECT COUNT(DISTINCT transaction_id) FROM fact_app_events) as total_transactions,
  (SELECT SUM(CASE WHEN final_step = 'Transaction_Success' THEN 1 ELSE 0 END) 
   FROM (SELECT transaction_id, MAX(step) as final_step FROM fact_app_events GROUP BY transaction_id)) as successful_transactions,
  (SELECT COUNT(DISTINCT user_id) FROM dim_users) as total_users,
  (SELECT SUM(amount) FROM fact_transactions) as total_value_transacted,
  (SELECT ROUND(AVG(amount), 0) FROM fact_transactions) as avg_transaction_value
;

-- ============================================================================
-- NOTES FOR IMPLEMENTATION
-- ============================================================================

-- 1. Replace table and column names based on your actual database schema
-- 2. Adjust timestamp functions (EXTRACT) based on your database dialect 
--    - PostgreSQL: EXTRACT(HOUR FROM timestamp)
--    - MySQL: HOUR(timestamp)
--    - SQL Server: DATEPART(HOUR, timestamp)
-- 3. Add date filters WHERE timestamp >= '2026-05-01' for specific periods
-- 4. Create indexes on (transaction_id, user_id, timestamp) for performance
-- 5. Schedule these queries as views or materialized tables for dashboard feeds
