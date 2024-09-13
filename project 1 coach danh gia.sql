--lưu ý chung: cần trình bày xuống dòng các field cho dễ nhìn hơn


--q1
WITH raw AS(
  SELECT PARSE_DATETIME('%Y%m%d',date) AS datetime_column, totals.visits,totals.pageviews,totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`),
months1 AS(
  SELECT FORMAT_DATE('%Y%m',datetime_column) AS months,SUM(visits),SUM(pageviews),SUM(transactions)
  FROM raw
  WHERE EXTRACT(MONTH FROM datetime_column)=1
  GROUP BY FORMAT_DATE('%Y%m',datetime_column)),
months2 AS(
  SELECT FORMAT_DATE('%Y%m',datetime_column) AS months,SUM(visits),SUM(pageviews),SUM(transactions)
  FROM raw
  WHERE EXTRACT(MONTH FROM datetime_column)=2
  GROUP BY FORMAT_DATE('%Y%m',datetime_column)),
months3 AS(
  SELECT FORMAT_DATE('%Y%m',datetime_column) AS months,SUM(visits),SUM(pageviews),SUM(transactions)
  FROM raw
  WHERE EXTRACT(MONTH FROM datetime_column)=3
  GROUP BY FORMAT_DATE('%Y%m',datetime_column))
SELECT *
FROM months1
UNION ALL
SELECT *
FROM months2
UNION ALL
SELECT*
FROM months3
ORDER BY months;

--mình chỉ tách ra thành các CTE dựa trên sự khác biệt về logic lấy data chứ k tách theo month như vậy
--nếu yêu cầu 12 month mà mình tách làm 12 cte thì dài lắm
SELECT
  format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
  SUM(totals.visits) AS visits,
  SUM(totals.pageviews) AS pageviews,
  SUM(totals.transactions) AS transactions,
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
GROUP BY 1
ORDER BY 1;

--sử dụng aggregate function, mình sum theo từng month, thì kế quả ra nó sẽ group lại theo từng month

--q2
WITH raw AS(
  SELECT trafficSource.source,SUM(totals.visits) AS total_visits,SUM(totals.bounces) AS total_no_of_bounces
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` 
  GROUP BY trafficSource.source
  ORDER BY total_visits DESC)
SELECT *,ROUND((raw.total_no_of_bounces*100.00/raw.total_visits),3) AS bounce_rate
FROM raw;

--main query và cte nên tách ra, chứ k sẽ rất khó nhìn
-->
SELECT
    trafficSource.source as source,
    sum(totals.visits) as total_visits,
    sum(totals.Bounces) as total_no_of_bounces,
    (sum(totals.Bounces)/sum(totals.visits))* 100 as bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY source
ORDER BY total_visits DESC;


--q3
WITH raw AS(
      SELECT trafficSource.source,product.productRevenue,PARSE_DATETIME('%Y%m%d',date) AS datetime_column
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    UNNEST (hits) hits,
    UNNEST (hits.product) product 
    WHERE product.productRevenue is not null),
jun AS(
    SELECT 'Month' as time_type,
    FORMAT_DATE('%Y%m',datetime_column) AS time,source,ROUND(SUM(productRevenue)/1000000,4) AS revenue
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

-->
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
--nên order by time_type, để month vs week đc xếp thành các cụm riêng biệt

--q4
WITH raw AS(
    SELECT totals.pageviews,fullVisitorId,totals.transactions,
    PARSE_DATETIME('%Y%m%d',date) AS datetime_column,product.productRevenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`, 
    UNNEST (hits) hits,
    UNNEST (hits.product) product)
SELECT FORMAT_DATE('%Y%m',datetime_column) AS time,
      (SELECT SUM(pageviews)/COUNT( DISTINCT fullVisitorId) 
      FROM raw
      WHERE productRevenue is not null AND EXTRACT(MONTH FROM datetime_column)=6)AS avg_pageviews_purchase,
      (SELECT SUM(pageviews)/COUNT( DISTINCT fullVisitorId) 
      FROM raw
      WHERE transactions is null AND EXTRACT(MONTH FROM datetime_column)=6) AS avg_pageviews_non_purchase
FROM raw
WHERE EXTRACT(MONTH FROM datetime_column)=6
GROUP BY FORMAT_DATE('%Y%m',datetime_column)
UNION ALL
SELECT FORMAT_DATE('%Y%m',datetime_column) AS time,
      (SELECT SUM(pageviews)/COUNT( DISTINCT fullVisitorId) 
      FROM raw
      WHERE productRevenue is not null AND EXTRACT(MONTH FROM datetime_column)=7)AS avg_pageviews_purchase,
      (SELECT SUM(pageviews)/COUNT( DISTINCT fullVisitorId) 
      FROM raw
      WHERE transactions is null AND EXTRACT(MONTH FROM datetime_column)=7) AS avg_pageviews_non_purchase
FROM raw
WHERE EXTRACT(MONTH FROM datetime_column)=7
GROUP BY FORMAT_DATE('%Y%m',datetime_column)
ORDER BY time;

--câu 4 này ghi khó nhìn qué, nhìn vào k biết từng cụm đang lấy data gì
--ng đọc sẽ pass qua luôn

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

--câu 4 này lưu ý là mình nên dùng full join, bởi vì trong câu này, phạm vi chỉ từ tháng 6-7, nên chắc chắc sẽ có pur và nonpur của cả 2 tháng
--mình inner join thì vô tình nó sẽ ra đúng. nhưng nếu đề bài là 1 khoảng thời gian dài hơn, 2-3 năm chẳng hạn, nó cũng tháng chỉ có nonpur mà k có pur
--thì khi đó inner join nó sẽ làm mình bị mất data, thay vì hiện số của nonpur và pur thì nó để trống



--q5
WITH raw AS(
    SELECT fullVisitorId,totals.transactions,
        PARSE_DATETIME('%Y%m%d',date) AS datetime_column,product.productRevenue 
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST (hits) hits,
    UNNEST (hits.product) product 
    WHERE product.productRevenue is not null )

SELECT FORMAT_DATE('%Y%m',datetime_column) AS time, --mình có thể xử lý month từ phía trên luôn
      SUM(transactions)/COUNT(DISTINCT fullVisitorId) AS Avg_total_transactions_per_user
FROM raw
GROUP BY 1;-- ghi by 1 hoặc time cho ngắn gọn

--feedback cho câu5&6, giữa cte và main query nên ghi cách ra
-->
select
    format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
    sum(totals.transactions)/count(distinct fullvisitorid) as Avg_total_transactions_per_user
from `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    ,unnest (hits) hits,
    unnest(product) product
where  totals.transactions>=1
and product.productRevenue is not null
group by month;


--q6
WITH raw AS(
  SELECT totals.visits,
        PARSE_DATETIME('%Y%m%d',date) AS datetime_column,product.productRevenue 
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST (hits) hits,
    UNNEST (hits.product) product 
    WHERE product.productRevenue is not null 
        AND totals.transactions IS NOT NULL 
        AND totals.visits IS NOT NULL)

SELECT FORMAT_DATE('%Y%m',datetime_column) AS time,
      SUM(productRevenue)/COUNT(visits)/1000000 AS avg_revenue_by_user_per_visit
FROM raw
GROUP BY FORMAT_DATE('%Y%m',datetime_column);

-->
select
    format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
    ((sum(product.productRevenue)/sum(totals.visits))/power(10,6)) as avg_revenue_by_user_per_visit
from `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
  ,unnest(hits) hits
  ,unnest(product) product
where product.productRevenue is not null
and totals.transactions>=1
group by month;


--q7
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

--đây là cách ghi của mình
-->
with buyer_list as(
    SELECT
        distinct fullVisitorId
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    , UNNEST(hits) AS hits
    , UNNEST(hits.product) as product
    WHERE product.v2ProductName = "YouTube Men's Vintage Henley"
    AND totals.transactions>=1
    AND product.productRevenue is not null
)

SELECT
  product.v2ProductName AS other_purchased_products,
  SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
, UNNEST(hits) AS hits
, UNNEST(hits.product) as product
JOIN buyer_list using(fullVisitorId)
WHERE product.v2ProductName != "YouTube Men's Vintage Henley"
 and product.productRevenue is not null
GROUP BY other_purchased_products
ORDER BY quantity DESC;


--q8
WITH raw AS(
   SELECT fullVisitorId,eCommerceAction.action_type,product.productRevenue,
        PARSE_DATETIME('%Y%m%d',date) AS datetime_column
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST (hits) hits,
    UNNEST (hits.product) product),
view AS(
    SELECT FORMAT_DATE('%Y%m',datetime_column) AS time,COUNT(fullVisitorId)AS num_product_view
    FROM raw
    WHERE (EXTRACT(MONTH FROM datetime_column)=1 AND action_type = '2') 
    OR(EXTRACT(MONTH FROM datetime_column)=2 AND action_type = '2')
    OR(EXTRACT(MONTH FROM datetime_column)=3 AND action_type = '2') 
    GROUP BY FORMAT_DATE('%Y%m',datetime_column)),
addtocard AS(
    SELECT FORMAT_DATE('%Y%m',datetime_column) AS time,COUNT(fullVisitorId)AS num_addtocart
    FROM raw
    WHERE (EXTRACT(MONTH FROM datetime_column)=1 AND action_type = '3') 
    OR(EXTRACT(MONTH FROM datetime_column)=2 AND action_type = '3')
    OR(EXTRACT(MONTH FROM datetime_column)=3 AND action_type = '3') 
    GROUP BY FORMAT_DATE('%Y%m',datetime_column)),
purchase AS(
    SELECT FORMAT_DATE('%Y%m',datetime_column) AS time,COUNT(fullVisitorId)AS num_purchase
    FROM raw
    WHERE (EXTRACT(MONTH FROM datetime_column)=1 AND action_type = '6'AND productRevenue is not null) 
    OR(EXTRACT(MONTH FROM datetime_column)=2 AND action_type = '6'AND productRevenue is not null)
    OR(EXTRACT(MONTH FROM datetime_column)=3 AND action_type = '6'AND productRevenue is not null) 
    GROUP BY FORMAT_DATE('%Y%m',datetime_column)),

--feedback chung: giữa các ghi nên cte nên cách ra, mình có thể dùng table_suffix để filter thời gian
--thay vì phải ghi lặp đi lặp lại như trên, mà ghi logic như vậy cũng hơi dài

total AS(
    SELECT v.*,a.num_addtocart,p.num_purchase
    FROM view AS v
    JOIN addtocard AS a
    ON v.time=a.time
    JOIN purchase AS p
    ON p.time=v.time)
SELECT*,
    ROUND((num_addtocart*100.00/num_product_view),2) AS add_to_cart_rate,
    ROUND((num_purchase*100.00/num_product_view),2) AS purchase_rate
FROM total;

-->
--bài yêu cầu tính số sản phầm, mình nên count productName hay productSKU thì sẽ hợp lý hơn là count action_type
--k nên xài inner join, nếu table1 có 10 record,table2 có 5 record,table3 có 1 record, thì sau khi inner join, output chỉ ra 1 record

--Cách 1:dùng CTE
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

--bài này k nên inner join, vì nếu như bảng purchase k có data thì sẽ k mapping đc vs bảng productview, từ đó kết quả sẽ k có luôn, mình nên dùng left join
--lấy số product_view làm gốc, nên mình sẽ left join ra 2 bảng còn lại

--Cách 2: bài này mình có thể dùng count(case when) hoặc sum(case when)

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



                                                            ---good---