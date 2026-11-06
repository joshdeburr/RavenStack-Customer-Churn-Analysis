-- 1. Support experience by customer churn status

SELECT
    a.churn_flag,
    COUNT(DISTINCT a.account_id) AS account_count,
    COUNT(st.ticket_id) AS total_tickets,
    ROUND(AVG(st.resolution_time_hours), 2)
        AS avg_resolution_time_hours,
    ROUND(AVG(st.first_response_time_minutes), 2)
        AS avg_first_response_minutes,
    ROUND(AVG(st.satisfaction_score), 2)
        AS avg_satisfaction_score
FROM accounts a
LEFT JOIN support_tickets st
    ON a.account_id = st.account_id
GROUP BY a.churn_flag
ORDER BY a.churn_flag;

-- 2. Support ticket escalations by customer churn status

SELECT
    a.churn_flag,
    COUNT(st.ticket_id) AS total_tickets,
    SUM(
        CASE WHEN st.escalation_flag = TRUE THEN 1 ELSE 0 END
    ) AS escalated_tickets,
    ROUND(
        100.0 * SUM(
            CASE WHEN st.escalation_flag = TRUE THEN 1 ELSE 0 END
        ) / COUNT(st.ticket_id),
        2
    ) AS escalation_rate_pct
FROM accounts a
JOIN support_tickets st
    ON a.account_id = st.account_id
GROUP BY a.churn_flag
ORDER BY a.churn_flag;

-- 3. Support ticket volume by customer churn status

WITH account_tickets AS (
    SELECT
        a.account_id,
        a.churn_flag,
        COUNT(st.ticket_id) AS ticket_count
    FROM accounts a
    LEFT JOIN support_tickets st
        ON a.account_id = st.account_id
    GROUP BY
        a.account_id,
        a.churn_flag
)

SELECT
    churn_flag,
    COUNT(*) AS account_count,
    ROUND(AVG(ticket_count), 2) AS avg_tickets_per_account,
    MIN(ticket_count) AS min_tickets,
    MAX(ticket_count) AS max_tickets,
    SUM(CASE WHEN ticket_count = 0 THEN 1 ELSE 0 END)
        AS accounts_with_no_tickets
FROM account_tickets
GROUP BY churn_flag
ORDER BY churn_flag;

-- 4. Accounts with escalated support tickets by churn status

WITH account_escalations AS (
    SELECT
        a.account_id,
        a.churn_flag,
        MAX(
            CASE
                WHEN st.escalation_flag = TRUE THEN 1
                ELSE 0
            END
        ) AS had_escalation
    FROM accounts a
    LEFT JOIN support_tickets st
        ON a.account_id = st.account_id
    GROUP BY
        a.account_id,
        a.churn_flag
)

SELECT
    churn_flag,
    COUNT(*) AS account_count,
    SUM(had_escalation) AS accounts_with_escalations,
    ROUND(
        100.0 * SUM(had_escalation) / COUNT(*),
        2
    ) AS account_escalation_rate_pct
FROM account_escalations
GROUP BY churn_flag
ORDER BY churn_flag;

-- 5. Support satisfaction by ticket priority and churn status

SELECT
    a.churn_flag,
    st.priority,
    COUNT(st.ticket_id) AS ticket_count,
    ROUND(AVG(st.satisfaction_score), 2)
        AS avg_satisfaction_score,
    ROUND(AVG(st.resolution_time_hours), 2)
        AS avg_resolution_time_hours,
    SUM(
        CASE WHEN st.escalation_flag = TRUE THEN 1 ELSE 0 END
    ) AS escalated_tickets
FROM accounts a
JOIN support_tickets st
    ON a.account_id = st.account_id
GROUP BY
    a.churn_flag,
    st.priority
ORDER BY
    st.priority,
    a.churn_flag;
    
-- 6. Escalation rate by ticket priority and churn status

SELECT
    a.churn_flag,
    st.priority,
    COUNT(st.ticket_id) AS ticket_count,
    SUM(
        CASE WHEN st.escalation_flag = TRUE THEN 1 ELSE 0 END
    ) AS escalated_tickets,
    ROUND(
        100.0 * SUM(
            CASE WHEN st.escalation_flag = TRUE THEN 1 ELSE 0 END
        ) / COUNT(st.ticket_id),
        2
    ) AS escalation_rate_pct
FROM accounts a
JOIN support_tickets st
    ON a.account_id = st.account_id
GROUP BY
    a.churn_flag,
    st.priority
ORDER BY
    st.priority,
    a.churn_flag;
    
    -- 7. Resolution time by escalation status and churn

SELECT
    a.churn_flag,
    st.escalation_flag,
    COUNT(st.ticket_id) AS ticket_count,
    ROUND(AVG(st.resolution_time_hours), 2)
        AS avg_resolution_time_hours,
    ROUND(AVG(st.first_response_time_minutes), 2)
        AS avg_first_response_minutes,
    ROUND(AVG(st.satisfaction_score), 2)
        AS avg_satisfaction_score
FROM accounts a
JOIN support_tickets st
    ON a.account_id = st.account_id
GROUP BY
    a.churn_flag,
    st.escalation_flag
ORDER BY
    a.churn_flag,
    st.escalation_flag;
    
    -- 8. Support ticket volume and escalations by industry

SELECT
    a.industry,
    a.churn_flag,
    COUNT(DISTINCT a.account_id) AS account_count,
    COUNT(st.ticket_id) AS total_tickets,
    ROUND(
        COUNT(st.ticket_id) * 1.0
        / COUNT(DISTINCT a.account_id),
        2
    ) AS avg_tickets_per_account,
    SUM(
        CASE WHEN st.escalation_flag = TRUE THEN 1 ELSE 0 END
    ) AS escalated_tickets,
    ROUND(
        100.0 * SUM(
            CASE WHEN st.escalation_flag = TRUE THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(st.ticket_id), 0),
        2
    ) AS escalation_rate_pct
FROM accounts a
LEFT JOIN support_tickets st
    ON a.account_id = st.account_id
GROUP BY
    a.industry,
    a.churn_flag
ORDER BY
    a.industry,
    a.churn_flag;
    
    -- 9. Support satisfaction by industry and churn status

SELECT
    a.industry,
    a.churn_flag,
    COUNT(st.ticket_id) AS ticket_count,
    ROUND(AVG(st.satisfaction_score), 2)
        AS avg_satisfaction_score,
    ROUND(AVG(st.resolution_time_hours), 2)
        AS avg_resolution_time_hours,
    ROUND(AVG(st.first_response_time_minutes), 2)
        AS avg_first_response_minutes
FROM accounts a
JOIN support_tickets st
    ON a.account_id = st.account_id
GROUP BY
    a.industry,
    a.churn_flag
ORDER BY
    a.industry,
    a.churn_flag;
    
    -- 10. Support metrics summary by customer churn status

SELECT
    a.churn_flag,
    COUNT(DISTINCT a.account_id) AS account_count,
    COUNT(st.ticket_id) AS total_tickets,
    ROUND(
        COUNT(st.ticket_id) * 1.0
        / COUNT(DISTINCT a.account_id),
        2
    ) AS avg_tickets_per_account,
    ROUND(AVG(st.resolution_time_hours), 2)
        AS avg_resolution_time_hours,
    ROUND(AVG(st.first_response_time_minutes), 2)
        AS avg_first_response_minutes,
    ROUND(AVG(st.satisfaction_score), 2)
        AS avg_satisfaction_score,
    SUM(
        CASE WHEN st.escalation_flag = TRUE THEN 1 ELSE 0 END
    ) AS escalated_tickets,
    ROUND(
        100.0 * SUM(
            CASE WHEN st.escalation_flag = TRUE THEN 1 ELSE 0 END
        ) / COUNT(st.ticket_id),
        2
    ) AS escalation_rate_pct
FROM accounts a
LEFT JOIN support_tickets st
    ON a.account_id = st.account_id
GROUP BY a.churn_flag
ORDER BY a.churn_flag;