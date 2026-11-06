SELECT 'accounts' AS table_name, COUNT(*) AS row_count
FROM accounts

UNION ALL

SELECT 'subscriptions', COUNT(*)
FROM subscriptions

UNION ALL

SELECT 'feature_usage', COUNT(*)
FROM feature_usage

UNION ALL

SELECT 'support_tickets', COUNT(*)
FROM support_tickets

UNION ALL

SELECT 'churn_events', COUNT(*)
FROM churn_events;


SELECT
    COUNT(*) AS total_accounts,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) AS churned_accounts,
    ROUND(
        100.0 * SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_pct
FROM accounts;

SELECT
    plan_tier,
    COUNT(*) AS account_count,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) AS churned_accounts,
    ROUND(
        100.0 * SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_pct
FROM accounts
GROUP BY plan_tier
ORDER BY churn_rate_pct DESC;

SELECT
    plan_tier,
    billing_frequency,
    COUNT(*) AS subscription_count,
    ROUND(AVG(mrr_amount), 2) AS avg_mrr,
    ROUND(SUM(mrr_amount), 2) AS total_mrr
FROM subscriptions
GROUP BY plan_tier, billing_frequency
ORDER BY total_mrr DESC;

SELECT
    CASE
        WHEN churn_flag = TRUE THEN 'Churned'
        ELSE 'Active'
    END AS subscription_status,
    COUNT(*) AS subscription_count
FROM subscriptions
GROUP BY churn_flag
ORDER BY churn_flag;

SELECT
    SUM(CASE WHEN upgrade_flag = TRUE THEN 1 ELSE 0 END) AS upgrades,
    SUM(CASE WHEN downgrade_flag = TRUE THEN 1 ELSE 0 END) AS downgrades
FROM subscriptions;

SELECT
    priority,
    COUNT(*) AS ticket_count,
    ROUND(AVG(first_response_time_minutes), 2) AS avg_first_response_minutes,
    ROUND(AVG(resolution_time_hours), 2) AS avg_resolution_hours
FROM support_tickets
GROUP BY priority
ORDER BY ticket_count DESC;

SELECT
    reason_code,
    COUNT(*) AS churn_events,
    ROUND(SUM(refund_amount_usd), 2) AS total_refunds
FROM churn_events
GROUP BY reason_code
ORDER BY churn_events DESC;

SELECT
    industry,
    COUNT(*) AS account_count,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) AS churned_accounts,
    ROUND(
        100.0 * SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_pct
FROM accounts
GROUP BY industry
ORDER BY churn_rate_pct DESC;

SELECT
    referral_source,
    COUNT(*) AS account_count,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) AS churned_accounts,
    ROUND(
        100.0 * SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_pct
FROM accounts
GROUP BY referral_source
ORDER BY churn_rate_pct DESC;

SELECT
    billing_frequency,
    COUNT(*) AS subscription_count,
    ROUND(AVG(mrr_amount), 2) AS avg_mrr,
    ROUND(SUM(mrr_amount), 2) AS total_mrr
FROM subscriptions
GROUP BY billing_frequency
ORDER BY subscription_count DESC;

SELECT
    feature_name,
    COUNT(*) AS usage_records,
    SUM(usage_count) AS total_usage,
    ROUND(AVG(usage_count), 2) AS avg_usage_count,
    ROUND(AVG(usage_duration_secs), 2) AS avg_duration_secs
FROM feature_usage
GROUP BY feature_name
ORDER BY total_usage DESC;