-- -------------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE customer_order_cleaned AS
SELECT
order_id, 
customer_id, 
pizza_id, 
order_time,
CASE
	WHEN exclusions = '' THEN NULL
	WHEN exclusions = 'null' THEN NULL

ELSE exclusions 
End As Cleaned_exclusions, 

CASE 
	WHEN extras =  '' THEN NULL
	WHEN extras =  'null' THEN NULL 
    WHEN extras = 'NaN' THEN NULL
ELSE extras
End AS Cleaned_Extras
from customer_orders;

-- -------------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE runner_orders_pre AS
SELECT 
    order_id,
    runner_id,
    pickup_time,
    cancellation,
    CASE
        WHEN pickup_time = '' OR pickup_time = 'null' THEN NULL
        ELSE pickup_time
    END AS Cleaned_pickup_time,

    CASE
        WHEN distance = 'null' THEN NULL
        ELSE regexp_replace(distance, '[a-z]+', '')
    END AS Distance_Cleaned,

    CASE
        WHEN duration = 'null' THEN NULL
        ELSE regexp_replace(duration, '[a-z]+', '')
    END AS Duration_Cleaned,

    CASE 
        WHEN cancellation = '' OR cancellation = 'null' OR cancellation = 'NaN' THEN NULL
        ELSE cancellation
    END AS cancellation_cleaned

FROM runner_orders;

-- -------------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE runner_orders_cleaned AS
SELECT 
order_id,
runner_id,
Cleaned_pickup_time as pick_up,
cancellation_cleaned as cancellation,
CAST(Distance_Cleaned as DECIMAL(3,1))
    AS Distance,
CAST(Duration_Cleaned as SIGNED INT)
	AS Duration
FROM runner_orders_pre;

ALTER TABLE runner_orders_cleaned
MODIFY COLUMN pick_up TIMESTAMP;

-- ---------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE exploded_pizza_toppings
(pizza_id INT, 
topping_id INT);
INSERT INTO exploded_pizza_toppings
(pizza_id, topping_id) VALUES 
(1,1),
(1,2),
(1,3),
(1,4),
(1,5),
(1,6),
(1,8),
(1,10),
(2,4),
(2,6),
(2,7),
(2,9),
(2,11),
(2,12);

-- -------------------------------------------------------------------------------------------------------------------------------------

drop table customer_orders;
drop table runner_orders;
drop table runners;
drop table pizza_recipes;
drop table runner_orders_pre;

-- -------------------------------------------------------------------------------------------------------------------------------------





