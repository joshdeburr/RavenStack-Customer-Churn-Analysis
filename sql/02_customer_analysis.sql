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

-- 2. Churn by country
-- Compare churn rates across geographic customer segments.
-- Note: interpret small countries cautiously due to smaller account counts.

SELECT
    country,
    COUNT(*) AS account_count,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) AS churned_accounts,
    ROUND(
        100.0 * SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_pct
FROM accounts
GROUP BY country
ORDER BY churn_rate_pct DESC;

-- 3. Churn by plan tier

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

-- 4. Customer size overview


SELECT
    CASE
        WHEN seats < 10 THEN '1-9'
        WHEN seats < 25 THEN '10-24'
        WHEN seats < 50 THEN '25-49'
        ELSE '50+'
    END AS customer_size,
    COUNT(*) AS account_count,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) AS churned_accounts,
    ROUND(
        100.0 * SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_pct
FROM accounts
GROUP BY customer_size
ORDER BY
    CASE customer_size
        WHEN '1-9' THEN 1
        WHEN '10-24' THEN 2
        WHEN '25-49' THEN 3
        WHEN '50+' THEN 4
    END;
   
-- 5. Churn by trial status
    
SELECT
    is_trial,
    COUNT(*) AS account_count,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) AS churned_accounts,
    ROUND(
        100.0 * SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_pct
FROM accounts
GROUP BY is_trial
ORDER BY churn_rate_pct DESC;

-- 6. Churn by customer tenure
-- Tenure measured as of the end of the observation period.

SELECT
    CASE
        WHEN TIMESTAMPDIFF(MONTH, signup_date, '2024-12-31') <= 6
            THEN '0-6 months'
        WHEN TIMESTAMPDIFF(MONTH, signup_date, '2024-12-31') <= 12
            THEN '7-12 months'
        WHEN TIMESTAMPDIFF(MONTH, signup_date, '2024-12-31') <= 24
            THEN '13-24 months'
        ELSE '25+ months'
    END AS tenure_group,
    COUNT(*) AS account_count,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) AS churned_accounts,
    ROUND(
        100.0 * SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_pct
FROM accounts
GROUP BY tenure_group
ORDER BY
    CASE tenure_group
        WHEN '0-6 months' THEN 1
        WHEN '7-12 months' THEN 2
        WHEN '13-24 months' THEN 3
        WHEN '25+ months' THEN 4
    END;
    
-- 7. Retained vs. churned customer profile

SELECT
    CASE
        WHEN churn_flag = TRUE THEN 'Churned'
        ELSE 'Retained'
    END AS customer_status,
    COUNT(*) AS account_count,
    ROUND(AVG(seats), 2) AS avg_seats,
    ROUND(
        100.0 * SUM(CASE WHEN is_trial = TRUE THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS trial_rate_pct
FROM accounts
GROUP BY churn_flag
ORDER BY churn_flag DESC;