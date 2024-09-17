--The Dataset is divided into disks, so when you want to get data, you have to call its dicks location.
--Q1.Calculate total visit, pageview, transaction for Jan, Feb and March 2017 (order by month)
--we've just using CTE depend on the logic to collect data
SELECT
  format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
  SUM(totals.visits) AS visits,
  SUM(totals.pageviews) AS pageviews,
  SUM(totals.transactions) AS transactions,
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
GROUP BY 1
ORDER BY 1;



--Q2.Bounce rate per traffic source in July 2017 (Bounce_rate = num_bounce/total_visit) (order by total_visit DESC)
SELECT
    trafficSource.source as source,
    sum(totals.visits) as total_visits,
    sum(totals.Bounces) as total_no_of_bounces,
    (sum(totals.Bounces)/sum(totals.visits))* 100 as bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY source
ORDER BY total_visits DESC;


--Q3.Revenue by traffic source by week, by month in June 2017
WITH raw AS(
    SELECT trafficSource.source,product.productRevenue,PARSE_DATETIME('%Y%m%d',date) AS datetime_column
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
      UNNEST (hits) hits,
      UNNEST (hits.product) product 
    WHERE product.productRevenue is not null),
jun AS(
    SELECT 'Month' as time_type,
      FORMAT_DATE('%Y%m',datetime_column) AS time,source,
      ROUND(SUM(productRevenue)/1000000,4) AS revenue
    FROM raw
    GROUP BY time_type,FORMAT_DATE('%Y%m',datetime_column),source),
week AS(
    SELECT 'Week' as time_type,
      FORMAT_DATE('%Y%V',datetime_column) AS time,source,ROUND(SUM(productRevenue)/1000000,4) AS revenue
    FROM raw
    GROUP BY time_type,FORMAT_DATE('%Y%V',datetime_column),source) 
SELECT *
FROM jun
UNION ALL
SELECT*
FROM week
ORDER BY source;

-->  If we set order by time_type, month and week will separate
with 
month_data as(
  SELECT
    "Month" as time_type,
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    trafficSource.source AS source,
    SUM(p.productRevenue)/1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    unnest(hits) hits,
    unnest(product) p
  WHERE p.productRevenue is not null
  GROUP BY 1,2,3
  order by revenue DESC
),

week_data as(
  SELECT
    "Week" as time_type,
    format_date("%Y%W", parse_date("%Y%m%d", date)) as week,
    trafficSource.source AS source,
    SUM(p.productRevenue)/1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    unnest(hits) hits,
    unnest(product) p
  WHERE p.productRevenue is not null
  GROUP BY 1,2,3
  order by revenue DESC
)

select * from month_data
union all
select * from week_data;


--Q4.Average number of pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017.
with 
purchaser_data as(
  select
      format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
      (sum(totals.pageviews)/count(distinct fullvisitorid)) as avg_pageviews_purchase,
  from `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
    ,unnest(hits) hits
    ,unnest(product) product
  where _table_suffix between '0601' and '0731'
  and totals.transactions>=1
  and product.productRevenue is not null
  group by month
),

non_purchaser_data as(
  select
      format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
      sum(totals.pageviews)/count(distinct fullvisitorid) as avg_pageviews_non_purchase,
  from `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
      ,unnest(hits) hits
    ,unnest(product) product
  where _table_suffix between '0601' and '0731'
  and totals.transactions is null
  and product.productRevenue is null
  group by month
)

select
    pd.*,
    avg_pageviews_non_purchase
from purchaser_data pd
full join non_purchaser_data using(month)
order by pd.month;

--Q5.Average number of transactions per user that made a purchase in July 2017
WITH raw AS(
    SELECT fullVisitorId,totals.transactions,
           PARSE_DATETIME('%Y%m%d',date) AS datetime_column,product.productRevenue 
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
        UNNEST (hits) hits,
        UNNEST (hits.product) product 
    WHERE product.productRevenue is not null )

SELECT FORMAT_DATE('%Y%m',datetime_column) AS time, 
       SUM(transactions)/COUNT(DISTINCT fullVisitorId) AS Avg_total_transactions_per_user
FROM raw
GROUP BY 1;

--Q6. Average amount of money spent per session. Only include purchaser data in July 2017 (HINT:avg_spend_per_session = total revenue/ total visit)
Select
    format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
    ((sum(product.productRevenue)/sum(totals.visits))/power(10,6)) as avg_revenue_by_user_per_visit
From `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
  ,unnest(hits) hits
  ,unnest(product) product
Where product.productRevenue is not null
      and totals.transactions>=1
Group by month;


--Q7.Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017. 
--Output should show product name and the quantity was ordered.
WITH list AS(
      SELECT DISTINCT fullVisitorId,
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST (hits) hits,
    UNNEST (hits.product) product
    WHERE product.v2ProductName="YouTube Men's Vintage Henley" 
    AND product.productRevenue IS NOT NULL 
),
others AS(
  SELECT  fullVisitorId,product.v2ProductName,product.productQuantity
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST (hits) hits,
    UNNEST (hits.product) product
    WHERE product.v2ProductName<>"YouTube Men's Vintage Henley" 
    AND product.productRevenue IS NOT NULL 
)
SELECT o.v2ProductName,SUM(o.productQuantity) AS quantity
FROM list AS l
JOIN others AS o 
ON l.fullVisitorId=o.fullVisitorId
GROUP BY o.v2ProductName
ORDER BY quantity DESC;

--Q8.Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017. 
--For example, 100% product view then 40% add_to_cart and 10% purchase.
--Add_to_cart_rate = number product  add to cart/number product view. 
--Purchase_rate = number product purchase/number product view. The output should be calculated in product level.

--Cách 1: Using CTE
with
product_view as(
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    count(product.productSKU) as num_product_view
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  , UNNEST(hits) AS hits
  , UNNEST(hits.product) as product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  AND hits.eCommerceAction.action_type = '2'
  GROUP BY 1
),

add_to_cart as(
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    count(product.productSKU) as num_addtocart
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  , UNNEST(hits) AS hits
  , UNNEST(hits.product) as product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  AND hits.eCommerceAction.action_type = '3'
  GROUP BY 1
),

purchase as(
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    count(product.productSKU) as num_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  , UNNEST(hits) AS hits
  , UNNEST(hits.product) as product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  AND hits.eCommerceAction.action_type = '6'
  and product.productRevenue is not null   --phải thêm điều kiện này để đảm bảo có revenue
  group by 1
)

select
    pv.*,
    num_addtocart,
    num_purchase,
    round(num_addtocart*100/num_product_view,2) as add_to_cart_rate,
    round(num_purchase*100/num_product_view,2) as purchase_rate
from product_view pv
left join add_to_cart a on pv.month = a.month
left join purchase p on pv.month = p.month
order by pv.month;

--Cách 2: Using count(case when) OR sum(case when)

with product_data as(
select
    format_date('%Y%m', parse_date('%Y%m%d',date)) as month,
    count(CASE WHEN eCommerceAction.action_type = '2' THEN product.v2ProductName END) as num_product_view,
    count(CASE WHEN eCommerceAction.action_type = '3' THEN product.v2ProductName END) as num_add_to_cart,
    count(CASE WHEN eCommerceAction.action_type = '6' and product.productRevenue is not null THEN product.v2ProductName END) as num_purchase
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
,UNNEST(hits) as hits
,UNNEST (hits.product) as product
where _table_suffix between '20170101' and '20170331'
and eCommerceAction.action_type in ('2','3','6')
group by month
order by month
)

select
    *,
    round(num_add_to_cart/num_product_view * 100, 2) as add_to_cart_rate,
    round(num_purchase/num_product_view * 100, 2) as purchase_rate
from product_data;



                                                            
