-- 1. Subscription upgrades and downgrades
-- Examine the frequency of subscription plan changes.

SELECT
    COUNT(*) AS total_subscriptions,
    SUM(CASE WHEN upgrade_flag = TRUE THEN 1 ELSE 0 END) AS upgrades,
    SUM(CASE WHEN downgrade_flag = TRUE THEN 1 ELSE 0 END) AS downgrades,
    ROUND(
        100.0 * SUM(CASE WHEN upgrade_flag = TRUE THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS upgrade_rate_pct,
    ROUND(
        100.0 * SUM(CASE WHEN downgrade_flag = TRUE THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS downgrade_rate_pct
FROM subscriptions;

-- 2. Subscription and revenue overview by billing frequency

SELECT
    billing_frequency,
    COUNT(*) AS subscription_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)
        AS subscription_share_pct,
    ROUND(AVG(mrr_amount), 2) AS avg_mrr,
    ROUND(SUM(mrr_amount), 2) AS total_mrr
FROM subscriptions
GROUP BY billing_frequency
ORDER BY total_mrr DESC;

-- 3. Subscription churn by auto-renewal status

SELECT
    auto_renew_flag,
    COUNT(*) AS subscription_count,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END)
        AS churned_subscriptions,
    ROUND(
        100.0 * SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS subscription_churn_rate_pct
FROM subscriptions
GROUP BY auto_renew_flag
ORDER BY subscription_churn_rate_pct DESC;

-- 4. Subscription churn by billing frequency

SELECT
    billing_frequency,
    COUNT(*) AS subscription_count,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END)
        AS churned_subscriptions,
    ROUND(
        100.0 * SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS subscription_churn_rate_pct,
    ROUND(AVG(mrr_amount), 2) AS avg_mrr
FROM subscriptions
GROUP BY billing_frequency
ORDER BY subscription_churn_rate_pct DESC;

-- 5. Product usage by customer churn status

WITH account_usage AS (
    SELECT
        s.account_id,
        SUM(f.usage_count) AS total_usage_count,
        AVG(f.usage_count) AS avg_usage_per_record,
        SUM(f.usage_duration_secs) AS total_usage_duration_secs,
        SUM(f.error_count) AS total_errors,
        COUNT(*) AS usage_records
    FROM subscriptions s
    JOIN feature_usage f
        ON s.subscription_id = f.subscription_id
    GROUP BY s.account_id
)

SELECT
    a.churn_flag,
    COUNT(*) AS account_count,
    ROUND(AVG(u.total_usage_count), 2) AS avg_total_usage,
    ROUND(AVG(u.total_usage_duration_secs), 2)
        AS avg_total_usage_duration_secs,
    ROUND(AVG(u.total_errors), 2) AS avg_total_errors,
    ROUND(AVG(u.usage_records), 2) AS avg_usage_records
FROM accounts a
JOIN account_usage u
    ON a.account_id = u.account_id
GROUP BY a.churn_flag
ORDER BY a.churn_flag;

-- 6. Average product usage per record by customer status

WITH account_usage AS (
    SELECT
        s.account_id,
        SUM(f.usage_count) AS total_usage_count,
        COUNT(*) AS usage_records,
        SUM(f.usage_duration_secs) AS total_duration_secs,
        SUM(f.error_count) AS total_errors
    FROM subscriptions s
    JOIN feature_usage f
        ON s.subscription_id = f.subscription_id
    GROUP BY s.account_id
)

SELECT
    a.churn_flag,
    COUNT(*) AS account_count,
    ROUND(
        AVG(1.0 * u.total_usage_count / u.usage_records),
        2
    ) AS avg_usage_per_record,
    ROUND(
        AVG(1.0 * u.total_duration_secs / u.usage_records),
        2
    ) AS avg_duration_per_record_secs,
    ROUND(
        AVG(1.0 * u.total_errors / u.usage_records),
        2
    ) AS avg_errors_per_record
FROM accounts a
JOIN account_usage u
    ON a.account_id = u.account_id
GROUP BY a.churn_flag
ORDER BY a.churn_flag;

-- 7. Feature usage by customer churn status

SELECT
    f.feature_name,
    a.churn_flag,
    COUNT(*) AS usage_records,
    COUNT(DISTINCT a.account_id) AS account_count,
    ROUND(AVG(f.usage_count), 2) AS avg_usage_count,
    ROUND(AVG(f.usage_duration_secs), 2)
        AS avg_duration_secs,
    ROUND(AVG(f.error_count), 2) AS avg_errors
FROM feature_usage f
JOIN subscriptions s
    ON f.subscription_id = s.subscription_id
JOIN accounts a
    ON s.account_id = a.account_id
GROUP BY
    f.feature_name,
    a.churn_flag
ORDER BY
    f.feature_name,
    a.churn_flag;
    
-- 8. Feature adoption by customer churn status

WITH account_feature_usage AS (
    SELECT DISTINCT
        s.account_id,
        f.feature_name
    FROM feature_usage f
    JOIN subscriptions s
        ON f.subscription_id = s.subscription_id
)

SELECT
    fl.feature_name,
    a.churn_flag,
    COUNT(DISTINCT af.account_id) AS accounts_using_feature,
    COUNT(DISTINCT a.account_id) AS accounts_in_group,
    ROUND(
        100.0 * COUNT(DISTINCT af.account_id)
        / COUNT(DISTINCT a.account_id),
        2
    ) AS feature_adoption_pct
FROM accounts a
CROSS JOIN (
    SELECT DISTINCT feature_name
    FROM feature_usage
) fl
LEFT JOIN account_feature_usage af
    ON af.account_id = a.account_id
    AND af.feature_name = fl.feature_name
GROUP BY
    fl.feature_name,
    a.churn_flag
ORDER BY
    fl.feature_name,
    a.churn_flag;
    
-- 9. Subscription churn by upgrade and downgrade status

SELECT
    upgrade_flag,
    downgrade_flag,
    COUNT(*) AS subscription_count,
    SUM(
        CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END
    ) AS churned_subscriptions,
    ROUND(
        100.0 * SUM(
            CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS subscription_churn_rate_pct
FROM subscriptions
GROUP BY
    upgrade_flag,
    downgrade_flag
ORDER BY
    subscription_churn_rate_pct DESC;
    
-- 10. Subscription churn by plan tier

SELECT
    plan_tier,
    COUNT(*) AS subscription_count,
    SUM(
        CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END
    ) AS churned_subscriptions,
    ROUND(
        100.0 * SUM(
            CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS subscription_churn_rate_pct,
    ROUND(AVG(mrr_amount), 2) AS avg_mrr
FROM subscriptions
GROUP BY plan_tier
ORDER BY subscription_churn_rate_pct DESC;