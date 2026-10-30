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

-- Working day = a day on which the agent had at least one attempt.

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
