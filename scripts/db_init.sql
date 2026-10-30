CREATE DATABASE assesment;

DROP TABLE IF EXISTS hubs CASCADE;
CREATE TABLE hubs (
hub_id VARCHAR(10) PRIMARY KEY,
hub_name VARCHAR(50),
cluster VARCHAR(50)
);

DROP TABLE IF EXISTS agents CASCADE;
CREATE TABLE agents(
agent_id VARCHAR(50) PRIMARY KEY,
agent_name VARCHAR(100),
hub_id VARCHAR(10) REFERENCES hubs(hub_id),
salary_type VARCHAR(20),
joining_date DATE,
active_status VARCHAR(20)
);

DROP TABLE IF EXISTS orders CASCADE;
CREATE TABLE orders(
order_id VARCHAR(20) PRIMARY KEY,
hub_id VARCHAR(10) REFERENCES hubs(hub_id),
created_at TIMESTAMP,
final_status VARCHAR(20),
cod_amount NUMERIC(10,2),
delivery_charge NUMERIC(10,2)
);

DROP TABLE IF EXISTS order_logs CASCADE;
CREATE TABLE order_logs(
log_id VARCHAR(20) PRIMARY KEY,
order_id VARCHAR(20) REFERENCES orders(order_id),
agent_id VARCHAR(10) REFERENCES agents(agent_id),
status VARCHAR(20),
hold_reason VARCHAR(50),
event_time TIMESTAMP,
attempt_no INT
);

DROP TABLE IF EXISTS agent_salary CASCADE;
CREATE TABLE agent_salary(
salary_type VARCHAR(20) PRIMARY KEY,
monthly_salary NUMERIC(10,2),
daily_allowance NUMERIC(10,2),
allowance_per_delivery NUMERIC(10,2)
);

DROP TABLE IF EXISTS costs CASCADE;
CREATE TABLE costs(
what VARCHAR(100) PRIMARY KEY,
amount_bdt NUMERIC(10,2),
when_changed VARCHAR(100)
);

DROP TABLE IF EXISTS rules CASCADE;
CREATE TABLE rules(
rule VARCHAR(150) PRIMARY KEY,
value VARCHAR(50)
);

DROP TABLE IF EXISTS volume_forecast CASCADE;
CREATE TABLE volume_forecast(
hub_id VARCHAR(10) REFERENCES hubs(hub_id),
week_start DATE,
week_end DATE,
expected_orders INT
);
