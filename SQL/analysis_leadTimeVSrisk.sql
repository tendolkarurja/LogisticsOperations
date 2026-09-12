-- Estimating lead time days 75th percentile bound to identify shipments with unusually long time
WITH ranked AS (
    SELECT
        lead_time_days,
        PERCENT_RANK() OVER (ORDER BY lead_time_days) AS percentile
    FROM fact_shipment
)
SELECT *
FROM ranked
WHERE percentile >= 0.75
ORDER BY percentile
limit 1


-- Overall percentage of distribution of risk category for unusually long
SELECT
    r.risk_category,
    COUNT(
		CASE 
			WHEN f.lead_time_days >= 21.23 THEN 1 
			END
		) AS long_shipments,
    COUNT(*) AS total_shipments,
    ROUND(
        COUNT(CASE WHEN f.lead_time_days >= 21.23 THEN 1 END) * 100.0
        / COUNT(*),
        2
    ) AS long_shipment_pct
FROM fact_shipment f
JOIN dim_risk r
    ON f.risk_id = r.risk_id
GROUP BY r.risk_category
ORDER BY long_shipment_pct DESC;


alter table dim_corridor
add column p75_thresh double precision;

-- Now getting the 75th percentile bound for each corridor
WITH ranked AS (
    SELECT 
        c.trade_corridor,
        f.lead_time_days,
        PERCENT_RANK() OVER (
            PARTITION BY c.trade_corridor
            ORDER BY f.lead_time_days
        ) AS percentile
    FROM fact_shipment f
    JOIN dim_corridor c
        ON f.corridor_id = c.corridor_id
),
p75 AS (
    SELECT
        trade_corridor,
        lead_time_days,
        percentile,
        ROW_NUMBER() OVER (
            PARTITION BY trade_corridor
            ORDER BY lead_time_days
        ) AS rn
    FROM ranked
    WHERE percentile >= 0.75
)
UPDATE dim_corridor c
SET p75_thresh = p.lead_time_days
FROM p75 p
WHERE c.trade_corridor = p.trade_corridor
  AND p.rn = 1;


select * from dim_corridor;

-- Based on each corridor ka unusually long ka lower limit, risk categorization
SELECT
    c.trade_corridor,
    r.risk_category,
    COUNT(
        CASE 
            WHEN f.lead_time_days >= c.p75_thresh THEN 1
        END
    ) AS long_shipments,
    COUNT(*) AS total_shipments,
    ROUND(
        COUNT(
            CASE 
                WHEN f.lead_time_days >= c.p75_thresh THEN 1
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS long_shipment_pct
FROM fact_shipment f
JOIN dim_risk r
    ON f.risk_id = r.risk_id
JOIN dim_corridor c
    ON f.corridor_id = c.corridor_id
GROUP BY
    c.trade_corridor,
    r.risk_category
ORDER BY long_shipment_pct DESC;

--
SELECT
    r.risk_category,
    COUNT(*) AS total_shipments,

    ROUND(AVG(f.lead_time_days)::numeric, 2) AS avg_lead_time,

    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY f.lead_time_days)::numeric,
        2
    ) AS median_lead_time,

    ROUND(
        PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY f.lead_time_days)::numeric,
        2
    ) AS p75_lead_time,

    ROUND(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY f.lead_time_days)::numeric,
        2
    ) AS p90_lead_time,

    ROUND(STDDEV_SAMP(f.lead_time_days)::numeric, 2) AS stddev_lead_time

FROM fact_shipment f
JOIN dim_risk r
    ON f.risk_id = r.risk_id

GROUP BY r.risk_category

ORDER BY CASE r.risk_category
    WHEN 'Low' THEN 1
    WHEN 'Moderate' THEN 2
    WHEN 'High' THEN 3
END;