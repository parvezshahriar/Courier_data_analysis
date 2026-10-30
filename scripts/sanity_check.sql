--Row counts match the source files
SELECT COUNT(*) FROM agent_salary;
SELECT COUNT(*) FROM agents;
SELECT COUNT(*) FROM costs;
SELECT COUNT(*) FROM hubs;
SELECT COUNT(*) FROM order_logs;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM rules;
SELECT COUNT(*) FROM volume_forecast;

--Duplicate keys
SELECT order_id, COUNT(*) FROM orders
GROUP BY order_id 
HAVING COUNT(*)>1;

SELECT agent_id, COUNT(*) FROM agents
GROUP BY agent_id 
HAVING COUNT(*)>1;

SELECT hub_id, COUNT(*) FROM hubs 
GROUP BY hub_id
HAVING COUNT(*)>1;

--Nulls and timestamp types
SELECT MIN(event_time), MAX(event_time) FROM order_logs;

--Join integrity
SELECT COUNT(*) FROM order_logs AS l 
LEFT JOIN orders AS o 
ON l.order_id=o.order_id
where o.order_id is NULL;

SELECT COUNT(*) FROM order_logs AS l
LEFT JOIN agents AS a 
ON l.agent_id=a.agent_id
where l.agent_id IS NOT NULL AND a.agent_id IS NULL;

SELECT COUNT(*) FROM orders AS o 
LEFT JOIN hubs AS h 
ON o.hub_id=h.hub_id
WHERE h.hub_id IS NULL;

SELECT COUNT(*) FROM agents AS a
LEFT JOIN hubs AS h 
ON a.hub_id=h.hub_id
WHERE h.hub_id IS NULL;

SELECT COUNT(*) FROM order_logs as l
JOIN orders as o 
ON l.order_id=o.order_id
JOIN agents as a
ON a.agent_id=l.agent_id
WHERE a.hub_id <>o.hub_id;

--Count per order and attempt number
WITH order_check AS(
  SELECT order_id,attempt_no,
  SUM(CASE WHEN status='Assigned' THEN 1 ELSE 0 END) AS assigned,
  SUM(CASE WHEN status IN ('Delivered', 'Hold', 'Returned') THEN 1 ELSE 0 END) AS outcome
  FROM order_logs
  GROUP BY order_id,attempt_no
)
SELECT *
FROM order_check
where assigned <> 1 OR outcome <> 1;

--Attempt Number
SELECT MAX(attempt_no) FROM order_logs;

--Hold reason on Delivery Status
SELECT status,COUNT(*) AS n,COUNT(hold_reason) AS with_reason
FROM order_logs
GROUP BY status;

--Courier status check
WITH last_ev AS (
  SELECT DISTINCT ON (order_id) order_id, status AS last_status
  FROM order_logs
  WHERE status IN ('Delivered','Hold','Returned')
  ORDER BY order_id, event_time DESC
)
SELECT o.final_status, l.last_status, COUNT(*)
FROM orders AS o 
JOIN last_ev AS l 
USING (order_id)
GROUP BY o.final_status,l.last_status;

--Events before joining date
SELECT COUNT(*) FROM order_logs AS l 
JOIN agents AS a
USING (agent_id)
WHERE l.event_time::date<a.joining_date;

--For inactive agents, check that their last event is on or before 19 October
SELECT a.agent_id, MAX(l.event_time)
FROM agents AS a
JOIN order_logs AS l
USING (agent_id)
WHERE a.active_status='Inactive'
GROUP BY a.agent_id 
HAVING MAX(l.event_time)::date<'2026-10-19';


