USE pizza_runner;
                                                
                                                --   A. Pizza Metrics
                             
                             
-- 1. How many pizzas were ordered?

SELECT COUNT(order_id) AS Pizza_Orders FROM customer_order_cleaned;

-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT(order_id)) AS Distinct_Orders FROM customer_order_cleaned;

-- 3. How many successful orders were delivered by each runner?

SELECT COUNT(*) AS successful_orders FROM runner_orders_cleaned WHERE cancellation IS NULL;

-- 4. How many of each type of pizza was delivered?

SELECT c.pizza_id,p.pizza_name, COUNT(p.pizza_id) AS delivered 
FROM customer_order_cleaned c 
JOIN runner_orders_cleaned r 
ON r.order_id = c.order_id 
JOIN pizza_names p 
ON p.pizza_id = c.pizza_id 
WHERE 
	cancellation is NULL
 GROUP BY pizza_id, pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT c.customer_id, p.pizza_name,
COUNT(p.pizza_name) AS order_count
FROM pizza_names p JOIN customer_order_cleaned c ON
c.pizza_id = p.pizza_id GROUP BY  c.customer_id, pizza_name, c.customer_id
ORDER BY customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?

SELECT c.order_id, count(c.pizza_id) pizza_per_order from customer_order_cleaned c JOIN
runner_orders_cleaned r on r.order_id = c.order_id WHERE cancellation is NULL
GROUP BY c.order_id;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

Select customer_id, 
sum(case when Cleaned_exclusions is not null or Cleaned_Extras is not null then 1 else 0 end) as changes_made, -- 1 OR 1-> 1
sum(case when Cleaned_exclusions is null and Cleaned_Extras is null then 1 else 0 end) as changes_not_made -- 0 AND 0 -> 0
from customer_order_cleaned left join runner_orders_cleaned using(order_id)
where cancellation is null
group by customer_id
Order by customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT DISTINCT(count(pizza_id)), c.customer_id FROM customer_order_cleaned c LEFT JOIN
runner_orders_cleaned r USING(order_id) WHERE c.Cleaned_exclusions is NOT NULL
AND c.CLeaned_Extras is NOT NULL AND r.cancellation is NULL
GROUP BY c.customer_id;

-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT COUNT(order_id) AS pizza_volume, EXTRACT(hour FROM order_time) AS hour_of_day FROM customer_order_cleaned 
GROUP BY hour_of_day ORDER BY hour_of_day;
       
-- 10. What was the volume of orders for each day of the week?

SELECT count(order_id) AS pizza_volume, DAYNAME(order_time) AS order_weak FROM customer_order_cleaned GROUP BY order_weak; 

											   
                                               -- B. Runner and Customer Experience
                                               
										 
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT (WEEK(registration_date)) AS registration_weak, COUNT(runner_id) as runner_assigned FROM runners GROUP BY registration_weak;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT ROUND(AVG(TIMESTAMPDIFF(MINUTE, c.order_time, r.pick_up)),1) AS pickup_diff, r.runner_id 
FROM customer_order_cleaned c
JOIN runner_orders_cleaned r USING(order_id)
WHERE cancellation IS NULL GROUP BY r.runner_id;
    
-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

SELECT  c.order_id, COUNT(c.pizza_id) as pizza_count, ROUND(AVG(TIMESTAMPDIFF(MINUTE, c.order_time, r.pick_up)),1)
AS pickup_diff
FROM customer_order_cleaned c JOIN runner_orders_cleaned r USING(order_id) WHERE cancellation IS NULL
GROUP BY  c.order_id;

-- 4. What was the average distance travelled for each customer?

SELECT c.customer_id, ROUND(AVG(r.distance),1) FROM customer_order_cleaned c join runner_orders_cleaned r USING(order_id)
WHERE cancellation IS NULL GROUP BY c.customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?

SELECT (MAX(duration) - MIN(duration)) as duration_difference FROM runner_orders_cleaned;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT runner_id, order_id, ROUND(AVG((Distance) / (Duration/60)),1) AS average_speedKMPH FROM runner_orders_cleaned WHERE cancellation IS NULL 
GROUP BY runner_id, order_id;

-- 7. What is the successful delivery percentage for each runner?

SELECT runner_id, 100* (SUM(CASE WHEN cancellation IS NULL THEN 1
ELSE 0 END)/ COUNT(*)) AS success_percentage FROM runner_orders_cleaned
GROUP BY runner_id;


			
										 -- C. Ingredient Optimisation
                                         
                                         
-- 1. What are the standard ingredients for each pizza?

SELECT  COUNT(ept.topping_id) AS topping_count, ept.topping_id, pt.topping_name FROM 
exploded_pizza_toppings ept JOIN pizza_toppings pt 
USING(topping_id) GROUP BY topping_name, ept.topping_id 
ORDER BY topping_count DESC;

-- 2. What was the most commonly added extra?

SELECT CLeaned_Extras, COUNT(c.CLeaned_Extras) FROM customer_order_cleaned c JOIN
pizza_toppings pt ON pt.topping_id = c.CLeaned_Extras 
GROUP BY CLeaned_Extras; 
 
 -- 3. What was the most common exclusion?
 
SELECT pt.topping_name, COUNT(c.CLeaned_exclusions) as most_occured
FROM customer_order_cleaned c INNER JOIN pizza_toppings pt 
ON  c.CLeaned_exclusions = pt.topping_id 
GROUP BY pt.topping_name;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- A. Meat Lovers
-- B. Meat Lovers - Exclude Beef
-- C. Meat Lovers - Extra Bacon
-- D. Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

SELECT
	tco.order_id,
    tco.pizza_id,
    pn.pizza_name,
    tco.Cleaned_exclusions,
    tco.CLeaned_Extras,
    CASE
		WHEN tco.pizza_id = 1 AND tco.Cleaned_exclusions IS NULL AND tco.CLeaned_Extras IS NULL THEN 'Meat Lovers'
        WHEN tco.pizza_id = 2 AND tco.Cleaned_exclusions IS NULL AND tco.CLeaned_Extras IS NULL THEN 'Vegetarian'
        WHEN tco.pizza_id = 1 AND tco.Cleaned_exclusions = '4' AND tco.CLeaned_Extras IS NULL THEN 'Meat Lovers - Exclude Cheese'
        WHEN tco.pizza_id = 2 AND tco.Cleaned_exclusions = '4' AND tco.CLeaned_Extras IS NULL THEN 'Vegetarian - Exclude Cheese'
        WHEN tco.pizza_id = 1 AND tco.Cleaned_exclusions IS NULL AND tco.CLeaned_Extras = '1' THEN 'Meat Lovers - Extra Bacon'
        WHEN tco.pizza_id = 2 AND tco.Cleaned_exclusions IS NULL AND tco.CLeaned_Extras = '1' THEN 'Vegetarian - Extra Bacon'
        WHEN tco.pizza_id = 1 AND tco.Cleaned_exclusions = '4' AND tco.CLeaned_Extras = '1, 5' THEN 'Meat Lovers - Exclude Cheese - Extra Bacon and Chicken'
        WHEN tco.pizza_id = 1 AND tco.Cleaned_exclusions = '2, 6' AND tco.CLeaned_Extras = '1, 4' THEN 'Meat Lovers - Exclude BBQ Sauce and Mushroom - Extra Bacon and Cheese'
	END AS order_item
FROM customer_order_cleaned tco
JOIN pizza_names pn ON tco.pizza_id = pn.pizza_id ORDER BY order_id;

/* 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami" */

SELECT order_id,
pizza_name,
CASE
	WHEN pizza_id=1 AND (CLeaned_Extras IS NULL ) AND (Cleaned_exclusions IS NULL) THEN 'Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami'
	WHEN pizza_id=2 AND (CLeaned_Extras IS NULL) AND (Cleaned_exclusions IS NULL)THEN 'Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce'
	WHEN (pizza_id=2) AND (CLeaned_Extras='1') AND (Cleaned_exclusions IS NULL) THEN '2XCheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce'
	WHEN (pizza_id=1) AND (CLeaned_Extras='1') AND (Cleaned_exclusions IS NULL) THEN '2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami'
	WHEN (pizza_id=1) AND (CLeaned_Extras='1, 5') AND (Cleaned_exclusions='4') THEN '2xBacon, BBQ Sauce, Beef, 2xChicken, Mushrooms, Pepperoni, Salami'
	WHEN (pizza_id=1) AND (CLeaned_Extras='1, 4') AND (Cleaned_exclusions='2, 6') THEN '2xBacon, Beef, 2xCheese, Chicken, Pepperoni, Salami'
	WHEN pizza_id=1 AND (CLeaned_Extras IS NULL) AND (Cleaned_exclusions='4') THEN 'Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami'
	WHEN pizza_id=2 AND (CLeaned_Extras IS NULL) AND (Cleaned_exclusions='4')THEN 'Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce'
END ingredients
FROM customer_order_cleaned
NATURAL JOIN pizza_names
NATURAL JOIN exploded_pizza_toppings;


-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

SELECT
    ept.topping_id,
    pt.topping_name,
    pn.pizza_name,
    COUNT(ept.topping_id) AS qnt_ingredient
FROM
    exploded_pizza_toppings ept
JOIN customer_order_cleaned c USING (pizza_id)
JOIN pizza_toppings pt ON pt.topping_id = ept.topping_id
LEFT JOIN runner_orders_cleaned roc ON roc.order_id = c.order_id
JOIN pizza_names pn ON pn.pizza_id = c.pizza_id
WHERE
    cancellation IS NULL
GROUP BY
    ept.topping_id, pt.topping_name, pn.pizza_name
ORDER BY
    qnt_ingredient DESC;

        
														-- D. Pricing and Ratings
                                                        

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT SUM(total_cost) AS final_sum FROM(
SELECT pn.pizza_name, COUNT(pizza_name) AS pizza_qnt, c.order_id, (CASE WHEN pizza_name = "Meatlovers" THEN 12 *COUNT(pizza_name) ELSE 10* COUNT(pn.pizza_name)  
END) AS total_cost
FROM pizza_names pn JOIN customer_order_cleaned c USING(pizza_id) JOIN runner_orders_cleaned roc ON roc.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY pizza_name, c.order_id) AS TOTAL;


-- 2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra

SELECT pn.pizza_name, COUNT(pizza_name) AS pizza_qnt, c.order_id,  c.CLeaned_Extras,
(CASE WHEN pizza_name = "Meatlovers" AND c.CLeaned_Extras = ('1, 4') THEN 12 *COUNT(pizza_name) + 2
WHEN pizza_name = "Meatlovers" AND  c.CLeaned_Extras is NULL THEN 12 *COUNT(pizza_name) 
WHEN pizza_name = "Meatlovers" AND c.CLeaned_Extras IS NOT NULL THEN  12 *COUNT(pizza_name) + COUNT(c.CLeaned_Extras)
WHEN pizza_name = "Vegetarian" AND  c.CLeaned_Extras is NULL THEN 10 *COUNT(pizza_name)
WHEN pizza_name = "Vegetarian" AND  c.CLeaned_Extras is NOT NULL THEN 10 *COUNT(pizza_name) + COUNT(c.CLeaned_Extras)
 
END) AS total_cost
FROM pizza_names pn JOIN customer_order_cleaned c USING(pizza_id) JOIN runner_orders_cleaned roc ON roc.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY pizza_name, c.order_id, c.Cleaned_exclusions, c.CLeaned_Extras;

/* 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
how would you design an additional table for this new dataset - \
generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5. */

SELECT c.customer_id, roc.runner_id AS delivery_partner, AVG(ROUND((Distance / Duration*60), 0)) AS speed,
CASE 
    WHEN AVG(ROUND((Distance / Duration * 60), 0)) >= 70 THEN '5' 
    WHEN AVG(ROUND((Distance / Duration * 60), 0)) >= 60 THEN '4'
    WHEN AVG(ROUND((Distance / Duration * 60), 0)) >= 50 THEN '3'
    WHEN AVG(ROUND((Distance / Duration * 60), 0)) >= 40 THEN '2' 
    ELSE '1'
END AS my_rating

FROM runner_orders_cleaned roc JOIN customer_order_cleaned c USING(order_id) 
WHERE roc.cancellation IS NULL
GROUP BY roc.runner_id, customer_id;

/* 4 -- Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas */
WITH avg_speed AS (SELECT runner_id, order_id, Duration,  ROUND(AVG((Distance) / (Duration/60)),1) AS average_speedKMPH FROM runner_orders_cleaned WHERE cancellation IS NULL 
GROUP BY runner_id, order_id, Duration),

tbop AS (SELECT ROUND(AVG(TIMESTAMPDIFF(MINUTE, c.order_time, r.pick_up)),1) AS pickup_diff, r.runner_id, MINUTE(c.order_time) AS order_time, MINUTE(r.pick_up) AS pickup_time
FROM customer_order_cleaned c
JOIN runner_orders_cleaned r USING(order_id)
WHERE cancellation IS NULL GROUP BY r.runner_id, c.order_time, r.pick_up),

ratings AS (SELECT c.customer_id, roc.runner_id AS delivery_partner, AVG(ROUND((Distance / Duration*60), 0)) AS speed,
CASE 
    WHEN AVG(ROUND((Distance / Duration * 60), 0)) >= 70 THEN '5' 
    WHEN AVG(ROUND((Distance / Duration * 60), 0)) >= 60 THEN '4'
    WHEN AVG(ROUND((Distance / Duration * 60), 0)) >= 50 THEN '3'
    WHEN AVG(ROUND((Distance / Duration * 60), 0)) >= 40 THEN '2' 
    ELSE '1'
END AS my_rating

FROM runner_orders_cleaned roc JOIN customer_order_cleaned c USING(order_id) 
WHERE roc.cancellation IS NULL
GROUP BY roc.runner_id, customer_id) 

SELECT avg_speed.order_id, avg_speed.runner_id, ratings.my_rating, avg_speed.average_speedKMPH, tbop.pickup_diff, tbop.order_time, tbop.pickup_time,
avg_speed.Duration, ratings.customer_id FROM avg_speed JOIN ratings ON avg_speed.runner_id = ratings.delivery_partner
JOIN tbop ON avg_speed.runner_id = tbop.runner_id;




/* 5 If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
- how much money does Pizza Runner have left over after these deliveries? */

SELECT SUM(total_cost) AS final_sum FROM(
SELECT pn.pizza_name, COUNT(pizza_name) AS pizza_qnt, c.order_id, (CASE WHEN pizza_name = "Meatlovers" THEN 12 *COUNT(pizza_name) - 0.30 ELSE 10* COUNT(pn.pizza_name) - 0.30
END) AS total_cost
FROM pizza_names pn JOIN customer_order_cleaned c USING(pizza_id) JOIN runner_orders_cleaned roc ON roc.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY pizza_name, c.order_id) AS TOTAL;

 