DROP VIEW attempt;
CREATE VIEW attempt AS
WITH assigned AS(
  SELECT order_id,
  attempt_no,
  agent_id,
  event_time AS assigned_time
  FROM order_logs 
  WHERE status='Assigned'
),
outcome AS(
 SELECT order_id,
 attempt_no, 
 status AS outcome, 
 hold_reason
 FROM order_logs 
 WHERE status IN ('Delivered','Hold','Returned')
)
SELECT a.order_id,
 a.attempt_no,
 a.agent_id,
 ag.agent_name,
 ag.hub_id, 
 a.assigned_time::date AS attempt_date,
 CASE 
   WHEN a.assigned_time::date <=DATE '2026-10-19' THEN 1 
   ELSE 2 
 END AS week_no,
 o.outcome,
 o.hold_reason,
 (o.hold_reason IN ('Late Dispatch','Not Attempted','Agent Time Shortage')) AS agent_side
FROM assigned AS a
JOIN outcome AS o 
USING (order_id,attempt_no)
JOIN agents AS ag 
USING(agent_id);

-- Q1.Working day = a day on which the agent had at least one attempt.

DROP TABLE IF EXISTs daily_agent;
CREATE TABLE daily_agent AS
SELECT agent_id,
agent_name,
hub_id,
attempt_date,
COUNT(*) AS assigned,
COUNT(*) FILTER(WHERE outcome='Delivered') AS delivered,
COUNT(*) FILTER(WHERE outcome='Hold') AS holds,
COUNT(*) FILTER(WHERE outcome='Returned') AS returned
FROM attempt
GROUP BY agent_id,agent_name,hub_id,attempt_date;

select * from daily_agent 
ORDER BY attempt_date,agent_id
LIMIT 20;

SELECT 
       h.hub_id,
	   h.cluster,
       h.hub_name,
       COUNT(*) AS agent_days,
	   SUM(d.assigned) AS total_assigned,
       SUM(d.delivered) AS total_delivered,
       SUM(d.holds) AS total_hold,
       SUM(d.returned) AS total_returned,
       COUNT(DISTINCT(d.agent_id)) AS available_agent_days,
       ROUND(AVG(d.delivered), 2) AS avg_deliveries_per_agent_day
FROM daily_agent d JOIN hubs h USING (hub_id)
GROUP BY h.hub_id,h.hub_name ORDER BY h.hub_id;

--Q2. Utilisation, Week 1 vs Week 2
WITH days AS (
    SELECT generate_series(
        DATE '2026-10-13',
        DATE '2026-10-26',
        INTERVAL '1 day'
    )::date AS work_date
),

capacity AS (
    SELECT
        a.hub_id,
        CASE
            WHEN d.work_date <= DATE '2026-10-19' THEN 1
            ELSE 2
        END AS week_no,
        COUNT(*) AS agent_days
    FROM agents a
    JOIN days d
        ON d.work_date >= a.joining_date
       AND (
            a.active_status = 'Active'
            OR d.work_date <= DATE '2026-10-19'
       )
    GROUP BY
        a.hub_id,
        CASE
            WHEN d.work_date <= DATE '2026-10-19' THEN 1
            ELSE 2
        END
),

attempt_counts AS (
    SELECT
        hub_id,
        week_no,
        COUNT(*) AS attempts
    FROM attempt
    GROUP BY hub_id, week_no
)

SELECT
    h.hub_name,
	h.hub_id,
	h.cluster,
    c.week_no,
    COALESCE(ac.attempts, 0) AS attempts,
    c.agent_days,
    c.agent_days * 40 AS capacity,

    ROUND(
        COALESCE(ac.attempts, 0) * 100.0 /
        NULLIF(c.agent_days * 40, 0),
        2
    ) AS utilisation_pct,

    CASE
        WHEN c.week_no = 2
         AND COALESCE(ac.attempts, 0) >
             c.agent_days * 40 * 0.85
        THEN 'ABOVE TARGET (>85%)'
		WHEN c.week_no = 2
         AND COALESCE(ac.attempts, 0) <
             c.agent_days * 40 * 0.85
        THEN 'WITHIN TARGET (<=85%)'
        ELSE NULL
    END AS flag

FROM capacity c

LEFT JOIN attempt_counts ac
    USING (hub_id, week_no)

JOIN hubs h
    USING (hub_id)

ORDER BY h.hub_id, c.week_no;

--Q3. Week 2 hold reasons
WITH hub AS(
 SELECT hub_id,
 hold_reason,
 BOOL_OR(agent_side) AS agent_side,
 COUNT(*) AS n
 FROM attempt
 WHERE week_no=2
 AND outcome='Hold'
 GROUP BY hub_id,hold_reason
),
total AS(
SELECT hub_id,
SUM(n) AS total_hold,
ROUND(
   100.0 * SUM(n) FILTER (WHERE agent_side) /
   NULLIF(SUM(n), 0),1)AS agent_side_pct
FROM hub
GROUP BY hub_id
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY hub_id
            ORDER BY n DESC, hold_reason
        ) AS rn
    FROM hub
)

SELECT h.hub_id, 
h.hub_name,
t.total_hold,
t.agent_side_pct,
MAX(hold_reason) FILTER(WHERE rn=1) AS top_reason_1,
MAX(n) FILTER (WHERE rn=1) AS top_1_count,
MAX(hold_reason) FILTER(WHERE rn=2) AS top_reason_2,
MAX(n) FILTER (WHERE rn=2) AS top_2_count
FROM ranked r
JOIN total AS t
USING(hub_id)
JOIN hubs AS h
USING (hub_id)
GROUP BY h.hub_id,h.hub_name,t.total_hold,t.agent_side_pct
ORDER BY h.hub_id;

--Q4. Outcome of held orders
WITH held AS(
SELECT DISTINCT order_id
from attempt
where outcome='Hold'
)
SELECT h.hub_name,h.hub_id,
COUNT(*) AS held_orders,
COUNT(*) FILTER (WHERE o.final_status = 'Delivered') AS finally_delivered,
    COUNT(*) FILTER (WHERE o.final_status = 'Returned') AS finally_returned,
    COUNT(*) FILTER (WHERE o.final_status = 'Hold') AS still_on_hold,
ROUND(
  100.0* COUNT(*) FILTER(WHERE o.final_status='Delivered')
  /NULLIF(COUNT(*),0),1) AS delivered_pct,

 ROUND(
  100.0* COUNT(*) FILTER(WHERE o.final_status='Returned')
  /NULLIF(COUNT(*),0),1) AS returned_pct,

 ROUND(
  100.0* COUNT(*) FILTER(WHERE o.final_status='Hold')
  /NULLIF(COUNT(*),0),1) AS hold_pct

FROM held
JOIN orders AS o
USING(order_id)
JOIN hubs AS h
USING(hub_id)
GROUP BY h.hub_id,h.hub_name
ORDER BY h.hub_id;

--Q5. High-return agents
SELECT a.agent_id,
a.agent_name,
a.salary_type,
a.joining_date,
h.hub_id,
h.hub_name,
DATE '2026-10-26'- a.joining_date AS tenure_days,
COUNT(*) AS attempts,
COUNT(*) FILTER (WHERE t.outcome='Returned') AS returned,
ROUND(100* COUNT(*) FILTER (WHERE t.outcome='Returned')/NULLIF(COUNT(*),0),2) AS return_pct
FROM attempt AS t
JOIN agents AS a 
USING(agent_id)
JOIN hubs AS h 
ON h.hub_id=a.hub_id

WHERE DATE '2026-10-26' -a.joining_date >30
AND a.active_status='Active'

GROUP BY a.agent_id,
a.agent_name,
a.salary_type,
a.joining_date,
h.hub_id,
h.hub_name
HAVING
    100.0 * COUNT(*) FILTER (
        WHERE t.outcome = 'Returned'
    ) / NULLIF(COUNT(*), 2) > 15

ORDER BY return_pct DESC;
--Q6. Cost per delivered order

-- Q7: Required Agents and Staffing Gap for 4 Forecast Weeks
WITH historical_apo AS (
    -- Calculate historical attempts per order for each hub
    SELECT
        o.hub_id,
        COUNT(*)::numeric /
            NULLIF(COUNT(DISTINCT l.order_id), 0) AS attempts_per_order
    FROM orders o
    JOIN order_logs l
        ON o.order_id = l.order_id
    WHERE l.status = 'Assigned'
      AND l.event_time::date
          BETWEEN DATE '2026-10-13' AND DATE '2026-10-26'
    GROUP BY o.hub_id
),

active_agents AS (
    -- Count currently active agents in each hub
    SELECT
        hub_id,
        COUNT(*) AS active_agents
    FROM agents
    WHERE active_status = 'Active'
    GROUP BY hub_id
),

staffing AS (
    -- Calculate required agents for each forecast week
    SELECT
        f.hub_id,
        f.week_start,
        f.week_end,
        f.expected_orders,
        apo.attempts_per_order,
        COALESCE(a.active_agents, 0) AS active_agents,

        CEIL(
            f.expected_orders * apo.attempts_per_order
            / (7 * 40 * 0.85)
        ) AS required_agents

    FROM volume_forecast f
    JOIN historical_apo apo
        ON f.hub_id = apo.hub_id
    LEFT JOIN active_agents a
        ON f.hub_id = a.hub_id
)

SELECT
    h.hub_id,
    h.hub_name,
    s.week_start,
    s.week_end,
    s.expected_orders,

    ROUND(s.attempts_per_order, 3) AS attempts_per_order,

    CEIL(
        s.expected_orders * s.attempts_per_order
        / 238.0
    ) AS required_agents,

    s.active_agents,

    CEIL(
        s.expected_orders * s.attempts_per_order
        / 238.0
    ) - s.active_agents AS staffing_gap

FROM staffing s
JOIN hubs h
    ON s.hub_id = h.hub_id

ORDER BY
    h.hub_id,
	h.hub_name,
    s.week_start;
