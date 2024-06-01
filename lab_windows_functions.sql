-- Challenge 1
-- This challenge consists of three exercises that will test your ability to use the SQL RANK() function. You will use it to rank films by 
--  their length, their length within the rating category, and by the actor or actress who has acted in the greatest number of films.
use sakila;
-- Rank films by their length and create an output table that includes the title, length, and rank columns only. 
-- Filter out any rows with null or zero values in the length column.
select title, length,
rank() over (order by length desc ) as 'rank'
from film
where length is not null
order by length desc;
-- Rank films by length within the rating category and create an output table that includes the title, length, rating and rank columns only. 
-- Filter out any rows with null or zero values in the length column.
select title, length, rating,
rank() over (partition by rating order by length desc ) as 'rank'
from film
where length is not null;
-- Produce a list that shows for each film in the Sakila database, the actor or actress who has acted in the greatest number of films, 
-- as well as the total number of films in which they have acted. Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.


with output as 
(select film_actor.actor_id
, count(*) as film_count 
from film_actor
group by actor_id
)
, qwe as (
select film.title, actor.first_name, actor.last_name, film_count
, max(film_count) over (partition by film.title) as max_film_count
from film
inner join film_actor
using (film_id)
inner join actor 
using (actor_id)
inner join output
using (actor_id)
order by film_count desc)

select * from qwe 
where film_count = max_film_count
;

-- Challenge 2
-- This challenge involves analyzing customer activity and retention in the Sakila database to gain insight into business performance. 
-- By analyzing customer behavior over time, businesses can identify trends and make data-driven decisions to improve customer retention and 
-- increase revenue.

-- The goal of this exercise is to perform a comprehensive analysis of customer activity and retention by conducting an analysis on the 
-- monthly percentage change in the number of active customers and the number of retained customers. Use the Sakila database and progressively 
-- build queries to achieve the desired outcome.

-- Step 1. Retrieve the number of monthly active customers, i.e., the number of unique customers who rented a movie in each month.

with month as 
(select *, month(return_date) as Month from rental)

select month, count(distinct rental.customer_id) as num_of_clients from rental
inner join month
using (rental_id)
where month is not null
group by month

;
select * from rental;
-- lag(count(distinct rental.customer_id)) over (partition by month) as lag_count
-- Step 2. Retrieve the number of active users in the previous month.
with month as 
(select *, month(rental_date) as month from rental)

select month,
lag(count(distinct rental.customer_id)) over (order by month) as lag_count
from month
inner join rental
	using (rental_id)
group by month
;


-- Step 3. Calculate the percentage change in the number of active customers between the current and previous month.
with month as (
select *, month(rental_date) as month from rental)

select month, 
count(distinct rental.customer_id) as current_month,
lag(count(distinct rental.customer_id)) over (order by month) as previous_month 
from month
inner join rental
	using (rental_id)
;

with monthly_data as (
select month(rental_date) as month,
count(distinct customer_id) as nos_of_custs 
from rental
group by month(rental_date)
)

select nos_of_custs, month,
lag(nos_of_custs) over (order by month) as previous_month_custs,
round((nos_of_custs - lag(nos_of_custs) over (order by month))/lag(nos_of_custs) over (order by month) * 100, 1) as percent_change 
from monthly_data
;

-- Step 4. Calculate the number of retained customers every month, i.e., customers who rented movies in the current and previous months.
-- custs that rented last month:
with month as (
select customer_id, month(rental_date) as rental_month
from rental
),

unique_customers_by_month as (
    select 
        rental_month, 
        customer_id
    from 
        month
    group by 
        rental_month, 
        customer_id
),

cust_month_8 as (
select rental_month, customer_id 
from unique_customers_by_month
where rental_month = 8
),

cust_month_7 as (
select rental_month, customer_id 
from unique_customers_by_month
where rental_month  = 7
)

select count(cust_month_8.customer_id) from cust_month_8
inner join cust_month_7
where cust_month_8.customer_id = cust_month_7.customer_id


-- select * from unique_customers_by_month
;


-- select count(customer_id) over (order by rental_month) 
-- from unique_customers_by_month
-- where customer_id = lag(customer_id) over (order by month) 

    with month as (
    select customer_id, month(rental_date) as rental_month
    from rental
),

unique_customers_by_month as (
    select 
        rental_month, 
        customer_id
    from 
        month
    group by 
        rental_month, 
        customer_id
),

previous_month_customers as (
    select 
        customer_id, 
        rental_month,
        lag(rental_month) over (partition by customer_id order by rental_month) as prev_rental_month
    from 
        unique_customers_by_month
)
select * from previous_month_customers
;
select 
    rental_month as current_month,
    count(customer_id) as retained_customers
from 
    previous_month_customers
where 
    prev_rental_month = rental_month - 1
group by 
    rental_month
order by 
    rental_month;
