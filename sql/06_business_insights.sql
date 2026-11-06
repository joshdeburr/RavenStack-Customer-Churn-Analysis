
-- 1. Executive summary: overall account churn

SELECT
    COUNT(*) AS total_accounts,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END)
        AS churned_accounts,
    SUM(CASE WHEN churn_flag = FALSE THEN 1 ELSE 0 END)
        AS retained_accounts,
    ROUND(
        100.0 * SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS account_churn_rate_pct
FROM accounts;


-- 2. Customer segments with the highest churn rates

SELECT
    industry,
    COUNT(*) AS total_accounts,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END)
        AS churned_accounts,
    ROUND(
        100.0 * SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS churn_rate_pct
FROM accounts
GROUP BY industry
ORDER BY churn_rate_pct DESC;


-- 3. Compare churn rates for trial and non-trial accounts

SELECT
    CASE
        WHEN is_trial = TRUE THEN 'Trial'
        ELSE 'Non-trial'
    END AS customer_type,
    COUNT(*) AS total_accounts,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END)
        AS churned_accounts,
    ROUND(
        100.0 * SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS churn_rate_pct
FROM accounts
GROUP BY is_trial
ORDER BY is_trial DESC;


-- 4. Subscription churn rates by plan and billing frequency

SELECT
    plan_tier,
    billing_frequency,
    COUNT(*) AS total_subscriptions,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END)
        AS churned_subscriptions,
    ROUND(
        100.0 * SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS churn_rate_pct,
    ROUND(
        SUM(CASE WHEN churn_flag = TRUE THEN mrr_amount ELSE 0 END),
        2
    ) AS recorded_churned_mrr
FROM subscriptions
GROUP BY
    plan_tier,
    billing_frequency
ORDER BY churn_rate_pct DESC;


-- 5. Account-level support escalation and churn

SELECT
    CASE
        WHEN a.churn_flag = TRUE THEN 'Churned'
        ELSE 'Retained'
    END AS customer_status,
    COUNT(DISTINCT a.account_id) AS total_accounts,
    COUNT(DISTINCT CASE
        WHEN st.escalation_flag = TRUE THEN a.account_id
    END) AS accounts_with_escalations,
    ROUND(
        100.0 * COUNT(DISTINCT CASE
            WHEN st.escalation_flag = TRUE THEN a.account_id
        END) / COUNT(DISTINCT a.account_id),
        2
    ) AS account_escalation_rate_pct,
    ROUND(AVG(st.resolution_time_hours), 2)
        AS avg_resolution_hours
FROM accounts a
LEFT JOIN support_tickets st
    ON a.account_id = st.account_id
GROUP BY a.churn_flag
ORDER BY a.churn_flag;


-- 6. Compare average product usage by account churn status

WITH account_usage AS (
    SELECT
        a.account_id,
        a.churn_flag,
        COUNT(fu.usage_id) AS usage_records,
        COALESCE(SUM(fu.usage_count), 0) AS total_usage,
        COALESCE(SUM(fu.usage_duration_secs), 0)
            AS total_duration_secs,
        COALESCE(SUM(fu.error_count), 0) AS total_errors
    FROM accounts a
    LEFT JOIN subscriptions s
        ON a.account_id = s.account_id
    LEFT JOIN feature_usage fu
        ON s.subscription_id = fu.subscription_id
    GROUP BY
        a.account_id,
        a.churn_flag
)
SELECT
    CASE
        WHEN churn_flag = TRUE THEN 'Churned'
        ELSE 'Retained'
    END AS customer_status,
    COUNT(*) AS account_count,
    ROUND(AVG(total_usage), 2) AS avg_total_usage,
    ROUND(AVG(usage_records), 2) AS avg_usage_records,
    ROUND(
        SUM(total_usage) / NULLIF(SUM(usage_records), 0),
        2
    ) AS usage_per_record,
    ROUND(
        SUM(total_duration_secs) / NULLIF(SUM(usage_records), 0),
        2
    ) AS duration_secs_per_record
FROM account_usage
GROUP BY churn_flag
ORDER BY churn_flag;


-- 7. Churn reasons ranked by refund impact

SELECT
    reason_code,
    COUNT(*) AS churn_events,
    COUNT(DISTINCT account_id) AS unique_accounts,
    ROUND(SUM(refund_amount_usd), 2) AS total_refunds_usd,
    ROUND(
        100.0 * SUM(refund_amount_usd)
        / NULLIF(
            (SELECT SUM(refund_amount_usd)
             FROM churn_events),
            0
        ),
        2
    ) AS refund_share_pct
FROM churn_events
GROUP BY reason_code
ORDER BY total_refunds_usd DESC;
