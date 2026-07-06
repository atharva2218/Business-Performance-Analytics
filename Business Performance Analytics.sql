use Ecommerce_Analytics


select * from dbo.order_items_clean
select * from dbo.orders_clean
select * from dbo.products_clean
select * from dbo.refunds_clean
select * from dbo.web_pageviews_clean
select * from dbo.web_sessions_clean





-- PRODUCTS TABLE

update dbo.products_clean
set product_name = LOWER(TRIM(product_name))



-- FIXING THE REFUNDS
-- DATA HANDLING FILLING THE MISSING RECORDS IN THE CREATED_AT OF THE REFUNDS

select
order_item_refund_id,
order_item_id,
order_id,
refund_amount_usd,

case 
	when created_at is NUll Then 'Missing_TimeStamp' else cast(created_at as varchar(50)) end as adjusted_timestamp

from dbo.refunds_clean


-- FIXING THE WEBPAGES 

update dbo.web_pageviews_clean
set pageview_url = LOWER(TRIM(pageview_url));




-- FIXING THE WEB_SESSIONS_CLEAN


-- CHECKING THE DUPLICATE VALUES


with dup_cte as (
select *,
ROW_NUMBER()over(PARTITION BY website_session_id
                  order by website_session_id)as row_num
                  
from dbo.web_sessions_clean
)
select * from dup_cte 
where row_num > 1





-- 
with dup_cte as (
select *,
ROW_NUMBER()over(PARTITION BY website_session_id
                  order by website_session_id)as row_num
                  
from dbo.web_sessions_clean
)
delete from dup_cte
where row_num > 1



-- UTM SOURCE
update dbo.web_sessions_clean
SET utm_source = coalesce(utm_source , 'organic')


select 
utm_source
from dbo.web_sessions_clean


select TRIM(utm_source)
from dbo.web_sessions_clean

-- Removing the spaces and setting into the UTM_SOURCE
update dbo.web_sessions_clean
set utm_source = TRIM(utm_source)


-- Lowering the cases
update dbo.web_sessions_clean
set utm_source = lower(utm_source)

UPDATE dbo.web_sessions_clean
SET utm_source = 'organic'
WHERE utm_source = 'nan';

-- Checking the count of the UTM_SOURCE
SELECT 
    utm_source, 
    COUNT(*) AS total_sessions
FROM dbo.web_sessions_clean
GROUP BY utm_source;


--  UTM CAMPAIGN

update dbo.web_sessions_clean
set utm_campaign = Trim(utm_campaign)


update dbo.web_sessions_clean
set utm_campaign = lower(utm_campaign)


update dbo.web_sessions_clean
set utm_campaign = 'no_campaign'
where utm_campaign is NULL


select
utm_campaign,
count(*) as Campaign_Count
from dbo.web_sessions_clean
group by utm_campaign



select utm_campaign from dbo.web_sessions_clean



-- UTM CONTENT

select utm_content, count(*) as Content_Count
from dbo.web_sessions_clean
group by utm_content


update dbo.web_sessions_clean
set utm_content = TRIM(utm_content) 

update dbo.web_sessions_clean
set utm_content = 'no_content'
where utm_content is NULL


-- HTTP REFER
select http_referer, count(*) as count
from dbo.web_sessions_clean
group by http_referer


update dbo.web_sessions_clean
set http_referer = lower(TRIM(http_referer))



update dbo.web_sessions_clean
set http_referer = 'direct_traffic'
where http_referer is NULL



-- ADDING THE PRIMARY KEY
alter table dbo.order_items_clean
add primary key (order_item_id)

alter table dbo.orders_clean
add primary key (order_id)

alter table dbo.products_clean
add primary key (product_id)

alter table dbo.refunds_clean
add primary key (order_item_refund_id)

alter table dbo.web_pageviews_clean
add primary key (website_pageview_id)


alter table dbo.web_sessions_clean
add primary key (website_session_id)


-- ADDING THE FOREIGN KEY

-- order_items_table
alter table dbo.order_items_clean
add foreign key (order_id) references dbo.orders_clean (order_id)

alter table dbo.order_items_clean
add foreign key (product_id) references dbo.products_clean (product_id)


-- order_tables


alter table dbo.orders_clean
add foreign key (website_session_id) references dbo.web_sessions_clean (website_session_id)


alter table dbo.orders_clean
alter column website_session_id int


sp_help 'dbo.web_sessions_clean'
sp_help 'dbo.orders_clean'

EXEC sp_helpconstraint 'dbo.web_sessions_clean';
EXEC sp_help 'dbo.orders_clean';


-- order_refunds_table

alter table dbo.refunds_clean
add foreign key (order_id) references dbo.orders_clean (order_id)


alter table dbo.refunds_clean
add foreign key (order_item_id) references dbo.order_items_clean (order_item_id)


-- web_pageviews_clean
alter table dbo.web_pageviews_clean
add foreign key (website_session_id) references dbo.web_sessions_clean (website_session_id)


--------------------------------------------------- KPIS ---------------------------------------------------


-- Total Website Sessions

select count(website_session_id) as Total_Website_Sessions
from
dbo.web_sessions_clean

-- Total Orders
select * from dbo.orders_clean


select count(order_id) as Total_Orders
from dbo.orders_clean;

-- Total Conversion

with total_conversion as (

select count(o.order_id) as Total_orders,
count(w.website_session_id) as Total_Website_Sessions

from dbo.web_sessions_clean w

left join dbo.orders_clean o on
w.website_session_id = o.website_session_id
)
select
(cast (Total_orders as float)/Total_Website_Sessions * 100) as Total_Conversion

from total_conversion;



-- Total Gross Revenue
select * from dbo.orders_clean

select sum(price_usd) as Total_Gross_Revenue
from dbo.orders_clean;

-- Total Margin(Net Profit)
select (cast(sum(price_usd - cogs_usd )as float) / sum(price_usd) * 100)  as Total_Margin
from dbo.orders_clean



-- Monthly Revenue and Volume

select
year(created_at) as Years,
month(created_at) as Months,
count(order_id) as Total_orders,
sum(price_usd) as Total_Revenue
from dbo.orders_clean

group by year(created_at) , month(created_at)
order by Years,Months


-- Top Selling Product
select * from dbo.products_clean


select 
primary_product_id,
count(order_id) as Total_orders,
sum(price_usd) as Total_Revenue

from dbo.orders_clean
group by primary_product_id
order by total_revenue desc


-- AOV

select (sum(price_usd) / count(order_id)) as AOV
from dbo.orders_clean



------------------------------------- BUSINESS QUESTIONS -------------------------------------

-- Business Question: Before we invest more in marketing, I want to know how our website traffic has evolved over time

select 
year(created_at) as Years,
month(created_at) as months,
count(website_session_id) as Session_count

from dbo.web_sessions_clean
group by year(created_at), month(created_at)
order by years , months

-- Business Question: Which marketing channels are driving the highest website traffic to our e-commerce platform?

select utm_source,count(*) as Website_traffic
from dbo.web_sessions_clean
group by utm_source
order by Website_traffic desc


-- Business Question: Which marketing channel has the highest conversion rate from website sessions to completed orders?

select * from dbo.orders_clean
select * from dbo.web_sessions_clean    


select 
w.utm_campaign,
count(distinct w.website_session_id) as Total_Sessions,
count(distinct o.order_id) as Total_Orders,
round(cast(count(distinct o.order_id) as float)/ count(distinct w.website_session_id)*100 , 2) as Total_conversion_Rate

from dbo.web_sessions_clean w
left join dbo.orders_clean o
on o.website_session_id = w.website_session_id
group by w.utm_campaign

order by Total_conversion_Rate


-- Business Question: Which device type (Desktop or Mobile) generates the highest website traffic and conversion rate?

select w.device_type,
count(distinct w.website_session_id) as Total_Sessions,
count(distinct o.order_id) as Total_Orders,
round(cast(count(distinct o.order_id) as float)/count(distinct w.website_session_id) * 100 , 2) as Total_Conversion_Rate

from dbo.web_sessions_clean w

left join dbo.orders_clean o on
o.website_session_id = w.website_session_id

group by w.device_type
order by Total_Conversion_Rate desc

-- Business Question: Which traffic source performs best on each device type?

select w.utm_source,
w.device_type,
count(distinct w.website_session_id) as Total_Sessions,
count(distinct o.order_id) as Total_Orders,
round(cast (count(distinct o.order_id ) as float) / count(distinct w.website_session_id)*100 , 2) as Conversion_Rate

from dbo.web_sessions_clean w
left join dbo.orders_clean o on
o.website_session_id = w.website_session_id

group by w.utm_source,
w.device_type
order by Conversion_Rate desc



-- Business Question: Which products generate the highest revenue?
select * from dbo.products_clean
select * from dbo.orders_clean

select p.product_name,
count(distinct o.order_id) as Total_Orders,
sum(o.price_usd) as Total_Revenue

from dbo.products_clean p

left join dbo.orders_clean o on
o.primary_product_id = p.product_id


group by p.product_name
order by Total_Revenue desc


-- Business Question: Which products generate the highest profit for the business?

with Highest_Profit as 
(
select p.product_name as product_names,
sum(o.price_usd) as selling_price,
sum(o.cogs_usd) as cost_price

from dbo.products_clean p
join dbo.orders_clean o on
o.primary_product_id = p.product_id

group by  p.product_name

)

select
product_names, selling_price, cost_price,

(selling_price - cost_price) as Profit

from Highest_Profit
order by Profit desc 



-- Business Question: How have monthly revenue and profit changed over time?

with monthly_revenue as (

select
year(o.created_at) as Years,
month(o.created_at) as Monthss,
count(distinct o.order_id) as Total_Orders,
sum(o.price_usd) as Total_Revenue,
sum(o.cogs_usd) as Total_Cost

from dbo.orders_clean o

group by year(o.created_at) , month(o.created_at)
)


select Years , Monthss ,  Total_Orders ,  Total_Revenue , Total_Cost,
(Total_Revenue - Total_Cost) as Profit

from monthly_revenue
order by Years , Monthss desc

-- Business Question: How has the Average Order Value (AOV) changed over time

with aov_overtime as 
(
select
year(created_at) as yearss,
month(created_at) as monthss,
count(distinct order_id) as Total_orders,
sum(price_usd) as Total_Revenue

from dbo.orders_clean

group by year(created_at), month(created_at)

)


select 
yearss,
monthss,
Total_Revenue,
Total_orders,

(Total_Revenue / Total_orders) as AOV
from aov_overtime
order by yearss,monthss desc;


-- Business Question: Which products have the highest refund rates?

select * from dbo.order_items_clean
select * from dbo.products_clean
select * from dbo.refunds_clean;


with highest_refund_product as (

select
p.product_id as Prod_Id,
p.product_name as Prod_name,
count(r.order_item_refund_id) as Total_Refund_Items,
count(distinct oi.order_item_id) as Total_Order_Items

from dbo.order_items_clean oi

left join dbo.refunds_clean r on
r.order_item_id = oi.order_item_id

join dbo.products_clean p
on 
p.product_id = oi.product_id


GROUP BY
    p.product_id,
    p.product_name)

SELECT
    Prod_Id,
    Prod_name,
    Total_Order_Items,
    Total_Refund_Items,

    ROUND(
        CAST(Total_Refund_Items AS FLOAT)
        / Total_Order_Items * 100,
        2
    ) AS Refund_Rate_Percentage

FROM highest_refund_product

ORDER BY Refund_Rate_Percentage DESC;


-- Business Question: Which landing pages receive the highest website traffic
select * from dbo.web_pageviews_clean
select * from dbo.orders_clean


select count(distinct website_pageview_id) Total_Website_Sessions , pageview_url

from dbo.web_pageviews_clean
group by pageview_url
order by Total_Website_Sessions desc

-- Business Question: Which landing pages have the highest conversion rates


WITH landing_pages AS
(
    SELECT
        wp.website_session_id,
        wp.pageview_url AS Landing_Page,
        ROW_NUMBER() OVER
        (
            PARTITION BY wp.website_session_id
            ORDER BY wp.created_at
        ) AS rn
    FROM dbo.web_pageviews_clean wp
)

SELECT
    lp.Landing_Page,
    COUNT(DISTINCT lp.website_session_id) AS Total_Sessions,
    COUNT(DISTINCT o.order_id) AS Total_Orders,

    ROUND(
        CAST(COUNT(DISTINCT o.order_id) AS FLOAT)
        / COUNT(DISTINCT lp.website_session_id) * 100,
        2
    ) AS Conversion_Rate

FROM landing_pages lp

LEFT JOIN dbo.orders_clean o
    ON lp.website_session_id = o.website_session_id

WHERE lp.rn = 1

GROUP BY lp.Landing_Page
ORDER BY Conversion_Rate DESC;



-- Business Question: Which marketing channels generate the highest Average Order Value (AOV)


select 
w.utm_source,
AVG(o.price_usd) as AOV

from dbo.orders_clean o
join dbo.web_sessions_clean w on

w.website_session_id = o.website_session_id

group by w.utm_source
order by AOV desc


-- Business Question: Which referral sources generate the highest website traffic, orders, and conversion rates

select * from dbo.orders_clean
select * from dbo.web_sessions_clean


select
w.http_referer,
count(distinct w.website_session_id) as Total_Sessions,
count(distinct o.order_id) as Total_Orders,

round(
       cast(count(distinct o.order_id) as float)/ count( distinct  w.website_session_id)*100 , 2) as Conversion_Rate

from dbo.web_sessions_clean w

left join dbo.orders_clean o on
o.website_session_id = w.website_session_id

group by w.http_referer
order by Conversion_Rate desc




-- Business Question: Which referral sources generate the highest revenue

select * from dbo.orders_clean
select * from dbo.web_sessions_clean;

with source_highest_rev
as
(
select 
w.http_referer as Referer,
count(o.order_id) as Total_Orders,
sum(o.price_usd) as Total_Revenue

from dbo.web_sessions_clean w


join dbo.orders_clean o on
o.website_session_id = w.website_session_id

group by w.http_referer

)

select 
Referer,
Total_Orders,
Total_Revenue

from source_highest_rev
order by Total_Revenue desc;




-- Business Question: Which device type generates the highest revenue, profit, and Average Order Value (AOV)?

with device_type as 
(
select
w.device_type as Device_Type,
count(distinct o.order_id) as Total_Orders,
sum(o.cogs_usd) as Total_COGS,
sum(o.price_usd) as Total_Revenue

from dbo.web_sessions_clean w
join dbo.orders_clean o on
o.website_session_id = w.website_session_id

group by w.device_type

)

select
Device_Type,
Total_Orders,
Total_COGS,
Total_Revenue,

round(cast(Total_Revenue as float)/ Total_Orders , 2) as AOV,
(Total_Revenue - Total_COGS ) as profit

from device_type
order by profit desc;


-- Business Question: Which products rank highest based on total revenue

with rank_product as (
select p.product_name as Product_Name,
count(distinct o.order_id) as Total_orders,
sum(o.price_usd) as Total_Revenue

from dbo.products_clean p

join dbo.orders_clean o
on
o.primary_product_id = p.product_id

group by p.product_name

)

select 
Product_Name,
Total_orders,
Total_Revenue,

DENSE_RANK()over(order by Total_Revenue desc ) as rev_rnk

from rank_product;


-- Business Question: How has monthly revenue changed compared to the previous month

select * from dbo.orders_clean;

with monthly_Revenue as(

select
year(created_at) as years,
month(created_at) as months,
sum(price_usd) as Total_Revnue

from dbo.orders_clean

group by 
year(created_at) ,
month(created_at)

)

select
years,
months,
Total_Revnue,

lag(Total_Revnue)
over(order by years ,months ) as Previous_Month_Revenue,

Total_Revnue - lag(Total_Revnue)OVER(
       ORDER BY Years, Months
    ) AS Revenue_Change



from monthly_Revenue
order by Total_Revnue desc



-- Business Question: By the end of March, how much total revenue have we generated since the beginning of the year?

with running_total as(

select
year(created_at) as years,
month(created_at) as months,
sum(price_usd) as Total_Revnue

from dbo.orders_clean

group by 
year(created_at) ,
month(created_at)

)

select
years,
months,
Total_Revnue,

sum(Total_Revnue)over(order by years,
months ) as Cumulative_Total

from running_total

order by years , months


-- Business Question: Month-over-Month (MoM) Revenue Growth %
with monthly_Revenue as(

select
year(created_at) as years,
month(created_at) as months,
sum(price_usd) as Total_Revnue

from dbo.orders_clean

group by 
year(created_at) ,
month(created_at)

)

select
years,
months,
Total_Revnue,

lag(Total_Revnue)
over(order by years ,months ) as Previous_Month_Revenue,

Total_Revnue - lag(Total_Revnue)OVER(
       ORDER BY Years, Months
    ) AS Revenue_Change,
ROUND(
        (
            (Total_Revnue -
             LAG(Total_Revnue) OVER (ORDER BY Years, Months))
            /
            NULLIF(
                LAG(Total_Revnue) OVER (ORDER BY Years, Months),
                0
            )
        ) * 100,
        2
    ) AS MoM_Growth_Percentage



from monthly_Revenue
order by Total_Revnue desc

SELECT @@SERVERNAME;



select count(distinct user_id)
from dbo.web_sessions_clean