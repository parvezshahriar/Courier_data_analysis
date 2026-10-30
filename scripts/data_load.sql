CREATE OR REPLACE PROCEDURE data_load()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    batch_start_time TIMESTAMP;
    batch_end_time TIMESTAMP;
BEGIN
    batch_start_time := clock_timestamp();
    RAISE NOTICE '================================================';
    RAISE NOTICE 'STARTING DATA LOAD (DELIVERY ASSESSMENT)';
    RAISE NOTICE '================================================';

    -- 1. Load hubs
    start_time := clock_timestamp();
    RAISE NOTICE 'Loading hubs...';
    TRUNCATE TABLE hubs CASCADE;
    COPY hubs
    FROM 'C:/datasets/delivery_assessment/hubs.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ','
    );
    end_time := clock_timestamp();
    RAISE NOTICE 'Load Time: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '.................................';

    -- 2. Load agents
    start_time := clock_timestamp();
    RAISE NOTICE 'Loading agents...';
    TRUNCATE TABLE agents CASCADE;
    COPY agents
    FROM 'C:/datasets/delivery_assessment/agents.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ','
    );
    end_time := clock_timestamp();
    RAISE NOTICE 'Load Time: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '.................................';

    -- 3. Load orders
    start_time := clock_timestamp();
    RAISE NOTICE 'Loading orders...';
    TRUNCATE TABLE orders CASCADE;
    COPY orders
    FROM 'C:/datasets/delivery_assessment/orders.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ','
    );
    end_time := clock_timestamp();
    RAISE NOTICE 'Load Time: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '.................................';

    -- 4. Load order_logs
    start_time := clock_timestamp();
    RAISE NOTICE 'Loading order_logs...';
    TRUNCATE TABLE order_logs CASCADE;
    COPY order_logs
    FROM 'C:/datasets/delivery_assessment/order_logs.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ','
    );
    end_time := clock_timestamp();
    RAISE NOTICE 'Load Time: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '.................................';

    -- 5. Load agent_salary
    start_time := clock_timestamp();
    RAISE NOTICE 'Loading agent_salary...';
    TRUNCATE TABLE agent_salary CASCADE;
    COPY agent_salary
    FROM 'C:/datasets/delivery_assessment/agent_salary.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ','
    );
    end_time := clock_timestamp();
    RAISE NOTICE 'Load Time: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '.................................';

    -- 6. Load costs
    start_time := clock_timestamp();
    RAISE NOTICE 'Loading costs...';
    TRUNCATE TABLE costs CASCADE;
    COPY costs
    FROM 'C:/datasets/delivery_assessment/costs.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ','
    );
    end_time := clock_timestamp();
    RAISE NOTICE 'Load Time: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '.................................';

    -- 7. Load rules
    start_time := clock_timestamp();
    RAISE NOTICE 'Loading rules...';
    TRUNCATE TABLE rules CASCADE;
    COPY rules
    FROM 'C:/datasets/delivery_assessment/rules.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ','
    );
    end_time := clock_timestamp();
    RAISE NOTICE 'Load Time: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '.................................';

    -- 8. Load volume_forecast
    start_time := clock_timestamp();
    RAISE NOTICE 'Loading volume_forecast...';
    TRUNCATE TABLE volume_forecast CASCADE;
    COPY volume_forecast
    FROM 'C:/datasets/delivery_assessment/volume_forecast.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ','
    );
    end_time := clock_timestamp();
    RAISE NOTICE 'Load Time: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '.................................';

    batch_end_time := clock_timestamp();
    RAISE NOTICE 'DATA LOADED SUCCESSFULLY in % seconds',
        EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '..............................................';
        RAISE NOTICE 'ERROR OCCURRED DURING LOADING DATA';
        RAISE NOTICE 'Error Message: %', SQLERRM;
        RAISE NOTICE 'SQLSTATE: %', SQLSTATE;
        RAISE;

END;
$$;

CALL data_load();
