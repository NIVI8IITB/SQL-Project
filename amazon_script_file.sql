SELECT * FROM amazon.amazon;

-- FEATURE ENGINEERING
-- Feature engineering has been done on product table which shows the details of product sold 
-- To be more specific it tells the time, day and month included for sales
ALTER TABLE product
ADD COLUMN timeofday VARCHAR(10);
select * from product;
ALTER TABLE product
DROP COLUMN timeofday;

--updated product table
UPDATE product
SET timeofday =
    CASE
        WHEN HOUR(Time) >= 6 AND HOUR(Time) < 12 THEN 'Morning'
        WHEN HOUR(Time) >= 12 AND HOUR(Time) < 18 THEN 'Afternoon'
        ELSE 'Evening'
    END
limit 1000;
-- Add a new column named timeofday to give insight of sales in the Morning, Afternoon and Evening
-- Below command is useful for the temporary modification of table
select *, 
CASE 
   WHEN HOUR(Time) >=6 AND HOUR(Time) < 12 THEN 'MORNING'
   WHEN HOUR(Time) >=12 AND HOUR(Time) <18 THEN 'AFTERNOON'
   ELSE 'EVENING'
END AS timeofday
FROM product;


-- Add a new column named dayname that contains the extracted days of the week on which the given transaction took place (Mon, Tue, Wed, Thur, Fri).
ALTER TABLE product
ADD COLUMN day_name VARCHAR(3);
UPDATE product
SET day_name = UPPER(LEFT(DAYNAME(Date), 3))
limit 1000;

-- Add a new column named monthname that contains the extracted months of the year on which the given transaction took place (Jan, Feb, Mar)
ALTER TABLE product
ADD COLUMN month_name VARCHAR(10);
UPDATE product
SET month_name = UPPER(LEFT(MONTHNAME(Date), 3))
limit 1000;
select * from product;

-- BUSINESS QUESTIONS TO ANSWER 
-- 1) what is the count of distinct cities in dataset
select count(distinct city) as distinct_city from amazon.amazon;

-- 2) For each branch, what is the corresponding city?
select Branch,city from amazon.amazon group by Branch,city;

-- 3) What is the count of distinct product lines in the dataset?
select count(distinct `Product line`) as distinct_product_line from amazon.amazon;

-- 4) Which payment method occurs most frequently?
select Payment, count(Payment) as mode_of_payment from amazon.amazon group by Payment limit 1;

-- 5) Which product line has the highest sales?
-- The gross margin percentage indicates how efficiently a company is managing its production costs relative to its revenue. 
-- A higher gross margin percentage indicates better profitability, as it means that a larger percentage of revenue is retained as gross profit. 
-- Conversely, a lower gross margin percentage suggests that a smaller portion of revenue is retained as gross profit, which may indicate 
-- challenges in managing production costs or pricing strategies
select `Product line`, avg(Total) as total_average_purchase 
from amazon.amazon 
group by `Product line` 
order by total_average_purchase desc
limit 1;

select distinct(month_name) from product;
-- 6) How much revenue is generated each month?
select sum(s.`gross income`)as Total_revenue,p.month_name from product p inner join sales s on 
p.`Invoice ID`=s.`Invoice ID` group by p.month_name;

-- 7) In which month did the cost of goods sold reach its peak?
select p.month_name, s.cogs from product p inner join sales s on 
p.`Invoice ID`=s.`Invoice ID` order by s.cogs desc limit 1;

-- 8) Which product line generated the highest revenue?
select sum(s.`gross income`)as Total_revenue,p.`Product line` from product p inner join sales s on 
p.`Invoice ID`=s.`Invoice ID` group by p.`Product line` order by Total_revenue desc limit 1;

-- 9) In which city was the highest revenue recorded?
select sum(s.`gross income`)as Total_revenue, c.city from customer c inner join sales s on 
c.`Invoice ID`=s.`Invoice ID` group by c.city order by Total_revenue desc limit 1;
 
 -- 10) Which product line incurred the highest Value Added Tax?
 select `Product line`,max(`Tax 5%`) as highest_VAT from product group by `Product line` order by highest_VAT desc limit 1 ;
 
 -- 11) For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."
 SELECT
    `Product line`,saless, avg_sales,
   CASE
        WHEN saless > avg_sales THEN 'Good'
        ELSE 'Bad'
    END AS sales_status
FROM (
    SELECT
        `Product line`,
        SUM(Total) AS saless,
        AVG(Total) AS avg_sales
    FROM
        product
    GROUP BY
        `Product line`
) AS subquery_alias;

-- 12) Identify the branch that exceeded the average number of products sold?
SELECT T1.branch_name
FROM (
SELECT c.Branch as branch_name, count(p.Quantity), sum(p.Quantity) as number_prod_sold , floor(avg(p.Quantity)) as avg_product_sold
from product p inner join customer c 
on c.`Invoice ID`= p.`Invoice ID` 
group by c.Branch) as T1
WHERE number_prod_sold > avg_product_sold;

-- 13) Which product line is most frequently associated with each gender?
SELECT
    c.Gender,
    p.`Product line`,
    COUNT(*) AS frequency
FROM
   product p inner join customer c 
   on c.`Invoice ID`= p.`Invoice ID`
GROUP BY
    c.Gender,
    p.`Product line`
ORDER BY
    c.Gender,
    frequency DESC;
    
-- 14) Calculate the average rating for each product line.
select p.`Product line`, round(avg(s.Rating),1) as avgerage_rating
from  product p inner join sales s
on p.`Invoice ID`= s.`Invoice ID` 
group by  p.`Product line`;

-- 15) Count the sales occurrences for each time of day on every weekday.
SELECT
    timeofday, day_name, sum(Total) as sales
FROM
   product 
GROUP BY
    timeofday, day_name
ORDER BY 
    timeofday, day_name;

-- 16) Identify the customer type contributing the highest revenue?
select c.`Customer type`, sum(s.`gross income`) as total_revenue
FROM customer c 
INNER JOIN sales s 
on c.`Invoice ID`= s.`Invoice ID` 
group by c.`Customer type`
order by total_revenue desc
limit 1;

-- 17) Determine the city with the highest VAT percentage?
select c.City, sum(p.`Tax 5%`) as total_VAT_perc
FROM customer c 
INNER JOIN product p
on c.`Invoice ID`= p.`Invoice ID` 
group by c.City
order by total_VAT_perc desc
limit 1;

-- 18) Identify the customer type with the highest VAT payments?
select c.`Customer type`, sum(p.`Tax 5%`) as total_VAT_perc
FROM customer c 
INNER JOIN product p
on c.`Invoice ID`= p.`Invoice ID` 
group by c.`Customer type`
order by total_VAT_perc desc
limit 1;

-- 19) What is the count of distinct customer types in the dataset?
select count(distinct `Customer type`) as distinct_customer from customer;

-- 20) What is the count of distinct payment methods in the dataset?
select count(distinct Payment) as distinct_payment from customer;

-- 21) Which customer type occurs most frequently?
select `Customer type`, count(`Customer type`) as frequency from customer group by `Customer type`
order by frequency desc
limit 1;

-- 22) Identify the customer type with the highest purchase frequency?
SELECT
    c.`Customer type`,
    COUNT(p.Quantity) AS purchase_frequency
FROM
    customer c 
INNER JOIN product p
on c.`Invoice ID`= p.`Invoice ID`
GROUP BY
   c.`Customer type`
ORDER BY
    purchase_frequency DESC
LIMIT 1;

-- 23) Determine the predominant gender among customers?
select Gender, count(Gender) as frequency from customer group by Gender 
order by frequency desc limit 1;

-- 24) Examine the distribution of genders within each branch?
select Branch, Gender, count(*) as distribution from customer
group by Branch, Gender
order by Branch, Gender;

-- 25) Identify the time of day when customers provide the most ratings?
-- This can be identified by knowing the maximum sales happen at the particular(timeofday)
select timeofday, count(*) as busiest_time from product p group by timeofday order by busiest_time desc limit 1;

-- 26) Determine the time of day with the highest customer ratings for each branch?
with highest_customer_rating as 
(
select Branch, max(Rating) as maximum_rat, timeofday from customer c inner join product p 
on c.`Invoice ID`= p.`Invoice ID` inner join sales s on p.`Invoice ID`= s.`Invoice ID`
group by Branch, timeofday
order by Branch
)
select * from highest_customer_rating
where maximum_rat=10;

-- 27) Identify the day of the week with the highest average ratings?
with highest_average as 
(
select day_name, round(avg(Rating),1) as rat
from product p inner join sales s 
on p.`Invoice ID`= s.`Invoice ID`
group by day_name
)
select * from highest_average
where rat=7.2;

-- 28) Determine the day of the week with the highest average ratings for each branch?
with highest_customer_rating as 
(
select Branch, max(Rating) as maximum_rat, day_name from customer c inner join product p 
on c.`Invoice ID`= p.`Invoice ID` inner join sales s on p.`Invoice ID`= s.`Invoice ID`
group by Branch, day_name
order by Branch
)
select * from highest_customer_rating
where maximum_rat=10;


