-- 1. Churn events by reason code

SELECT
    reason_code,
    COUNT(*) AS churn_event_count,
    COUNT(DISTINCT account_id) AS unique_accounts,
    ROUND(SUM(refund_amount_usd), 2) AS total_refunds_usd,
    ROUND(AVG(refund_amount_usd), 2) AS avg_refund_usd
FROM churn_events
GROUP BY reason_code
ORDER BY churn_event_count DESC;

-- 2. Refunds by churn reason and reactivation status

SELECT
    reason_code,
    is_reactivation,
    COUNT(*) AS event_count,
    COUNT(DISTINCT account_id) AS unique_accounts,
    ROUND(SUM(refund_amount_usd), 2) AS total_refunds_usd,
    ROUND(AVG(refund_amount_usd), 2) AS avg_refund_usd
FROM churn_events
GROUP BY
    reason_code,
    is_reactivation
ORDER BY
    reason_code,
    is_reactivation;
    
    -- 3. Subscription revenue by churn status

SELECT
    churn_flag,
    COUNT(*) AS subscription_count,
    SUM(
        CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END
    ) AS churned_subscriptions,
    ROUND(SUM(mrr_amount), 2) AS total_mrr,
    ROUND(
        AVG(mrr_amount),
        2
    ) AS avg_mrr_per_subscription,
    ROUND(
        SUM(CASE WHEN churn_flag = TRUE THEN mrr_amount ELSE 0 END),
        2
    ) AS churned_subscription_mrr
FROM subscriptions
GROUP BY churn_flag
ORDER BY churn_flag;

-- 4. Churned subscription count and MRR by plan tier

SELECT
    plan_tier,
    COUNT(*) AS churned_subscriptions,
    ROUND(SUM(mrr_amount), 2) AS recorded_churned_mrr,
    ROUND(AVG(mrr_amount), 2) AS avg_mrr_per_churned_subscription,
    ROUND(
        100.0 * SUM(mrr_amount)
        / (SELECT SUM(mrr_amount)
           FROM subscriptions
           WHERE churn_flag = TRUE),
        2
    ) AS share_of_churned_mrr_pct
FROM subscriptions
WHERE churn_flag = TRUE
GROUP BY plan_tier
ORDER BY recorded_churned_mrr DESC;

-- 5. Churned subscription revenue by billing frequency

SELECT
    billing_frequency,
    COUNT(*) AS churned_subscriptions,
    ROUND(SUM(mrr_amount), 2) AS recorded_churned_mrr,
    ROUND(AVG(mrr_amount), 2) AS avg_mrr_per_subscription,
    ROUND(
        100.0 * SUM(mrr_amount)
        / (SELECT SUM(mrr_amount)
           FROM subscriptions
           WHERE churn_flag = TRUE),
        2
    ) AS share_of_churned_mrr_pct
FROM subscriptions
WHERE churn_flag = TRUE
GROUP BY billing_frequency
ORDER BY recorded_churned_mrr DESC;

-- 6. Refund impact by churn reason

SELECT
    reason_code,
    COUNT(*) AS churn_event_count,
    COUNT(DISTINCT account_id) AS unique_accounts,
    ROUND(SUM(refund_amount_usd), 2) AS total_refunds_usd,
    ROUND(AVG(refund_amount_usd), 2) AS avg_refund_usd,
    ROUND(
        100.0 * SUM(refund_amount_usd)
        / (SELECT SUM(refund_amount_usd)
           FROM churn_events),
        2
    ) AS share_of_total_refunds_pct
FROM churn_events
GROUP BY reason_code
ORDER BY total_refunds_usd DESC;



-- 7. Churned subscription MRR by churn reason
-- Aggregate MRR per account before joining churn reasons

WITH churned_mrr_by_account AS (
    SELECT
        account_id,
        SUM(mrr_amount) AS churned_mrr
    FROM subscriptions
    WHERE churn_flag = TRUE
    GROUP BY account_id
),
reason_accounts AS (
    SELECT DISTINCT
        reason_code,
        account_id
    FROM churn_events
),
reason_event_summary AS (
    SELECT
        reason_code,
        COUNT(*) AS churn_event_count,
        ROUND(SUM(refund_amount_usd), 2) AS total_refunds_usd
    FROM churn_events
    GROUP BY reason_code
)
SELECT
    ra.reason_code,
    COUNT(*) AS unique_accounts,
    res.churn_event_count,
    res.total_refunds_usd,
    ROUND(SUM(COALESCE(cma.churned_mrr, 0)), 2)
        AS associated_churned_mrr
FROM reason_accounts ra
JOIN reason_event_summary res
    ON ra.reason_code = res.reason_code
LEFT JOIN churned_mrr_by_account cma
    ON ra.account_id = cma.account_id
GROUP BY
    ra.reason_code,
    res.churn_event_count,
    res.total_refunds_usd
ORDER BY associated_churned_mrr DESC;


-- 8. Account churn by total subscription MRR segment

WITH account_revenue AS (
    SELECT
        a.account_id,
        a.churn_flag,
        COALESCE(SUM(s.mrr_amount), 0) AS total_account_mrr
    FROM accounts a
    LEFT JOIN subscriptions s
        ON a.account_id = s.account_id
    GROUP BY
        a.account_id,
        a.churn_flag
),
revenue_segments AS (
    SELECT
        account_id,
        churn_flag,
        total_account_mrr,
        CASE
            WHEN total_account_mrr < 1000 THEN 'Under $1,000'
            WHEN total_account_mrr < 3000 THEN '$1,000-$2,999'
            WHEN total_account_mrr < 5000 THEN '$3,000-$4,999'
            ELSE '$5,000+'
        END AS revenue_segment
    FROM account_revenue
)
SELECT
    revenue_segment,
    COUNT(*) AS account_count,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END)
        AS churned_accounts,
    ROUND(
        100.0 * SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS churn_rate_pct,
    ROUND(AVG(total_account_mrr), 2) AS avg_account_mrr
FROM revenue_segments
GROUP BY revenue_segment
ORDER BY
    CASE revenue_segment
        WHEN 'Under $1,000' THEN 1
        WHEN '$1,000-$2,999' THEN 2
        WHEN '$3,000-$4,999' THEN 3
        ELSE 4
    END;


-- 9. Inspect account-level recorded MRR distribution

WITH account_revenue AS (
    SELECT
        a.account_id,
        a.churn_flag,
        COALESCE(SUM(s.mrr_amount), 0) AS total_account_mrr
    FROM accounts a
    LEFT JOIN subscriptions s
        ON a.account_id = s.account_id
    GROUP BY
        a.account_id,
        a.churn_flag
)
SELECT
    COUNT(*) AS account_count,
    MIN(total_account_mrr) AS min_account_mrr,
    ROUND(AVG(total_account_mrr), 2) AS avg_account_mrr,
    MAX(total_account_mrr) AS max_account_mrr,
    ROUND(AVG(CASE
        WHEN churn_flag = TRUE THEN total_account_mrr
    END), 2) AS avg_churned_account_mrr,
    ROUND(AVG(CASE
        WHEN churn_flag = FALSE THEN total_account_mrr
    END), 2) AS avg_retained_account_mrr
FROM account_revenue;


-- 10. Compare account-level recorded MRR by churn status

WITH account_revenue AS (
    SELECT
        a.account_id,
        a.churn_flag,
        COALESCE(SUM(s.mrr_amount), 0) AS total_account_mrr
    FROM accounts a
    LEFT JOIN subscriptions s
        ON a.account_id = s.account_id
    GROUP BY
        a.account_id,
        a.churn_flag
),
ranked_revenue AS (
    SELECT
        churn_flag,
        total_account_mrr,
        ROW_NUMBER() OVER (
            PARTITION BY churn_flag
            ORDER BY total_account_mrr
        ) AS row_num,
        COUNT(*) OVER (
            PARTITION BY churn_flag
        ) AS group_count
    FROM account_revenue
)
SELECT
    CASE
        WHEN churn_flag = TRUE THEN 'Churned'
        ELSE 'Retained'
    END AS customer_status,
    MAX(group_count) AS account_count,
    ROUND(AVG(total_account_mrr), 2) AS avg_account_mrr,
    MIN(CASE
        WHEN row_num = FLOOR((group_count + 1) / 2)
        THEN total_account_mrr
    END) AS median_lower_value,
    MIN(CASE
        WHEN row_num = FLOOR((group_count + 2) / 2)
        THEN total_account_mrr
    END) AS median_upper_value
FROM ranked_revenue
GROUP BY churn_flag
ORDER BY churn_flag;


-- 11. Churned subscription MRR by plan and billing frequency

SELECT
    plan_tier,
    billing_frequency,
    COUNT(*) AS churned_subscriptions,
    ROUND(SUM(mrr_amount), 2) AS recorded_churned_mrr,
    ROUND(AVG(mrr_amount), 2) AS avg_mrr_per_subscription,
    ROUND(
        100.0 * SUM(mrr_amount) /
        (
            SELECT SUM(mrr_amount)
            FROM subscriptions
            WHERE churn_flag = TRUE
        ),
        2
    ) AS share_of_total_churned_mrr_pct
FROM subscriptions
WHERE churn_flag = TRUE
GROUP BY
    plan_tier,
    billing_frequency
ORDER BY recorded_churned_mrr DESC;


-- 12. Subscription churn rate by plan and billing frequency

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
    ) AS subscription_churn_rate_pct,
    ROUND(AVG(mrr_amount), 2) AS avg_mrr_per_subscription
FROM subscriptions
GROUP BY
    plan_tier,
    billing_frequency
ORDER BY
    plan_tier,
    billing_frequency;
