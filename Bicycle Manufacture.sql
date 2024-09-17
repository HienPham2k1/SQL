--Q1.Calc Quantity of items, Sales value & Order quantity by each Subcategory in Last 12 months
select format_datetime('%b %Y', a.ModifiedDate) month
      ,c.Name
      ,sum(a.OrderQty) qty_item
      ,sum(a.LineTotal) total_sales
      ,count(distinct a.SalesOrderID) order_cnt
FROM `adventureworks2019.Sales.SalesOrderDetail` a 
left join `adventureworks2019.Production.Product` b
  on a.ProductID = b.ProductID
left join `adventureworks2019.Production.ProductSubcategory` c
  on b.ProductSubcategoryID = cast(c.ProductSubcategoryID as string)
where date(a.ModifiedDate) between   (date_sub(date(a.ModifiedDate), INTERVAL 12 month)) and '2014-06-30'
group by 1,2
order by 2,1;


--Q2.Calc % YoY growth rate by SubCategory & release top 3 cat with highest grow rate. Can use metric: quantity_item. Round results to 2 decimal
with 
sale_info as (
  SELECT 
      FORMAT_TIMESTAMP("%Y", a.ModifiedDate) as yr
      , c.Name
      , sum(a.OrderQty) as qty_item

  FROM `adventureworks2019.Sales.SalesOrderDetail` a 
  LEFT JOIN `adventureworks2019.Production.Product` b on a.ProductID = b.ProductID
  LEFT JOIN `adventureworks2019.Production.ProductSubcategory` c on cast(b.ProductSubcategoryID as int) = c.ProductSubcategoryID

  GROUP BY 1,2
  ORDER BY 2 asc , 1 desc
),

sale_diff as (
  select *
  , lead (qty_item) over (partition by Name order by yr desc) as prv_qty
  , round(qty_item / (lead (qty_item) over (partition by Name order by yr desc)) -1,2) as qty_diff
  from sale_info
  order by 5 desc 
),

rk_qty_diff as (
  select *
      ,dense_rank() over( order by qty_diff desc) dk
  from sale_diff
  order by dk DESC
)

select distinct Name
      , qty_item
      , prv_qty
      , qty_diff
from rk_qty_diff 
where dk <=3;

--Q3.Ranking Top 3 TeritoryID with biggest Order quantity of every year. If there's TerritoryID with same quantity in a year, do not skip the rank number

WITH raw AS(
  SELECT FORMAT_DATETIME('%Y',c.ModifiedDate) AS period
    ,a.TerritoryID
    ,SUM(c.OrderQty) AS item_cnt  
  FROM `adventureworks2019.Sales.SalesTerritory` a
  JOIN `adventureworks2019.Sales.SalesOrderHeader` b
  ON a.TerritoryID=b.TerritoryID
  JOIN `adventureworks2019.Sales.SalesOrderDetail` c
  ON b.SalesOrderID=c.SalesOrderID
  GROUP BY a.TerritoryID
      ,FORMAT_DATETIME('%Y',c.ModifiedDate)),

total AS(
  SELECT *, DENSE_RANK()OVER(PARTITION BY period ORDER BY raw.item_cnt DESC) AS rk
  FROM raw
  ORDER BY period DESC,rk)

SELECT *
FROM total
WHERE rk IN (1,2,3);


--q4
WITH price AS(
  SELECT a.ProductID,a.UnitPrice,a.OrderQty,b.DiscountPct     --chị select nguyên 1 dây ngang như vậy mà k cách ra sẽ khó nhìn, 
        ,FORMAT_DATETIME('%Y',a.ModifiedDate) AS period      --tới lúc mình muốn chỉnh sửa cũng khó cho mình
  FROM `adventureworks2019.Sales.SalesOrderDetail` a
  JOIN `adventureworks2019.Sales.SpecialOffer` b
  ON a.SpecialOfferID=b.SpecialOfferID
  WHERE b.Type='Seasonal Discount')

SELECT price.period,c.Subcategory AS name
      ,SUM(UnitPrice*OrderQty*DiscountPct)
FROM price 
JOIN `adventureworks2019.Sales.Product` c
ON price.ProductID=c.ProductID
GROUP BY price.period,c.Subcategory;

--đây là cách e trình bày
select 
    FORMAT_TIMESTAMP("%Y", ModifiedDate)
    , Name
    , sum(disc_cost) as total_cost
from (
      select distinct a.*
      , c.Name
      , d.DiscountPct, d.Type
      , a.OrderQty * d.DiscountPct * UnitPrice as disc_cost 
      from `adventureworks2019.Sales.SalesOrderDetail` a
      LEFT JOIN `adventureworks2019.Production.Product` b on a.ProductID = b.ProductID
      LEFT JOIN `adventureworks2019.Production.ProductSubcategory` c on cast(b.ProductSubcategoryID as int) = c.ProductSubcategoryID
      LEFT JOIN `adventureworks2019.Sales.SpecialOffer` d on a.SpecialOfferID = d.SpecialOfferID
      WHERE lower(d.Type) like '%seasonal discount%' 
)
group by 1,2;


--q5
WITH info AS(
      SELECT  EXTRACT(MONTH FROM ModifiedDate) months_order
            ,EXTRACT(YEAR FROM ModifiedDate) years
            ,CustomerID
            ,COUNT(DISTINCT SalesOrderID)
      FROM `adventureworks2019.Sales.SalesOrderHeader` 
      WHERE Status = 5 AND EXTRACT(YEAR FROM ModifiedDate)=2014
      GROUP BY EXTRACT(MONTH FROM ModifiedDate)
            ,EXTRACT(YEAR FROM ModifiedDate)
            ,CustomerID),
row_num AS(
      SELECT *,ROW_NUMBER()OVER(PARTITION BY CustomerID ORDER BY months_order) AS row_nb
      FROM info),

first_order AS(
      SELECT DISTINCT months_order AS months_join ,years,CustomerID
      FROM row_num
      WHERE row_nb=1)

,all_join AS(
      SELECT DISTINCT a.months_order,a.years,a.CustomerID,b.months_join
      ,CONCAT('M', a.months_order-b.months_join) as months_diff
      FROM info a
      JOIN first_order b
      ON a.CustomerID=b.CustomerID
      ORDER BY months_diff)
SELECT DISTINCT months_join,all_join.months_diff
      ,COUNT(DISTINCT CustomerID) AS customer_cnt
FROM all_join
GROUP BY 1,2
ORDER BY 1;

--đây là cách e trình bày
with 
info as (
  select  
      extract(month from ModifiedDate) as month_no
      , extract(year from ModifiedDate) as year_no
      , CustomerID
      , count(Distinct SalesOrderID) as order_cnt
  from `adventureworks2019.Sales.SalesOrderHeader`
  where FORMAT_TIMESTAMP("%Y", ModifiedDate) = '2014'
  and Status = 5
  group by 1,2,3
  order by 3,1 
),

row_num as (
  select *
      , row_number() over (partition by CustomerID order by month_no) as row_numb
  from info 
), 

first_order as (
  select *
  from row_num
  where row_numb = 1
), 

month_gap as (
  select 
      a.CustomerID
      , b.month_no as month_join
      , a.month_no as month_order
      , a.order_cnt
      , concat('M - ',a.month_no - b.month_no) as month_diff
  from info a 
  left join first_order b 
  on a.CustomerID = b.CustomerID
  order by 1,3
)

select month_join
      , month_diff 
      , count(distinct CustomerID) as customer_cnt
from month_gap
group by 1,2
order by 1,2;


--q6
WITH raw AS(
    SELECT a.Name
          ,EXTRACT(MONTH FROM b.ModifiedDate) AS months
          ,EXTRACT(YEAR FROM b.ModifiedDate) AS years
          ,SUM(b.StockedQty) AS stock_qty
    FROM `adventureworks2019.Production.Product` a
    JOIN `adventureworks2019.Production.WorkOrder` b
    ON a.ProductID=b.ProductID
    GROUP BY a.Name
          ,EXTRACT(MONTH FROM b.ModifiedDate)
          ,EXTRACT(YEAR FROM b.ModifiedDate) 
    ORDER BY Name,months DESC),
prev AS(
    SELECT*
      , LEAD(stock_qty)OVER(PARTITION BY Name ORDER BY months DESC ) stock_prv
    FROM raw
    WHERE years=2011
    ORDER BY Name),
total AS(
    SELECT *,ROUND((stock_qty-stock_prv)*100.00/stock_prv,2) AS stock_diff
    FROM prev)

SELECT Name,months,years,stock_qty,stock_prv,
  CASE WHEN stock_diff IS NOT NULL THEN stock_diff
        WHEN stock_diff IS NULL THEN 0   --đôi lúc mình k nên then 0, nhìu khi mình trả ra số k nó sẽ bị sai ý nghĩa
                                        --giống như đi thi đc 0 điểm khác với việc k đi thi á
          END 
FROM total;

--q7
WITH sale_infor AS(
    SELECT  EXTRACT(MONTH FROM a.ModifiedDate) AS months
            ,EXTRACT(YEAR FROM a.ModifiedDate) AS years
            ,b.ProductID,b.Name
            ,SUM(a.OrderQty) AS sale_cnt
    FROM `adventureworks2019.Sales.SalesOrderDetail` a
    LEFT JOIN `adventureworks2019.Production.Product` b 
    ON a.ProductID=b.ProductID
    WHERE EXTRACT(YEAR FROM a.ModifiedDate)=2011
     GROUP BY  EXTRACT(MONTH FROM a.ModifiedDate)
              ,EXTRACT(YEAR FROM a.ModifiedDate)
              ,b.ProductID,b.Name),

stock_infor AS(
    SELECT EXTRACT(MONTH FROM c.ModifiedDate) AS months
            ,EXTRACT(YEAR FROM c.ModifiedDate) AS years
            ,c.ProductID
      ,SUM(c.StockedQty) AS stock_cnt
    FROM `adventureworks2019.Production.WorkOrder` c
    WHERE EXTRACT(YEAR FROM ModifiedDate)=2011
    GROUP BY EXTRACT(MONTH FROM c.ModifiedDate) 
            ,EXTRACT(YEAR FROM c.ModifiedDate)
            ,c.ProductID        
    --mình có thể ghi group by months, years, chứ ghi group by nguyên cái hàm nv thì hơi khó nhìn
    ORDER BY months DESC)

SELECT sa.months,sa.years,sa.ProductID,sa.Name,sa.sale_cnt,st.stock_cnt
    ,ROUND(stock_cnt/sale_cnt,1) AS ratio
FROM stock_infor AS st
JOIN sale_infor AS sa     
ON st.ProductID=sa.ProductID
  AND st.months=sa.months
  AND st.years=sa.years
ORDER BY months DESC, ratio DESC;

--nên dùng full join, inner join nó chỉ hện ra những tháng vừa có sale vừa có stock thoi, nên có thể gây mismatch data
--nên bổ sung year = year để tránh trường hợp month của 2011 map với month 2010, ví dụ vậy

with 
sale_info as (
  select 
      extract(month from a.ModifiedDate) as mth 
     , extract(year from a.ModifiedDate) as yr 
     , a.ProductId
     , b.Name
     , sum(a.OrderQty) as sales
  from `adventureworks2019.Sales.SalesOrderDetail` a 
  left join `adventureworks2019.Production.Product` b 
    on a.ProductID = b.ProductID
  where FORMAT_TIMESTAMP("%Y", a.ModifiedDate) = '2011'
  group by 1,2,3,4
), 

stock_info as (
  select
      extract(month from ModifiedDate) as mth 
      , extract(year from ModifiedDate) as yr 
      , ProductId
      , sum(StockedQty) as stock_cnt
  from 'adventureworks2019.Production.WorkOrder'
  where FORMAT_TIMESTAMP("%Y", ModifiedDate) = '2011'
  group by 1,2,3
)

select
      a.*
    , coalesce(b.stock_cnt,0) as stock
    , round(coalesce(b.stock_cnt,0) / sales,2) as ratio
from sale_info a 
full join stock_info b 
  on a.ProductId = b.ProductId
and a.mth = b.mth 
and a.yr = b.yr
order by 1 desc, 7 desc;


--q8
SELECT EXTRACT(YEAR FROM ModifiedDate) AS yr
      ,Status
      ,COUNT(PurchaseOrderID)
      ,SUM(TotalDue)
FROM `adventureworks2019.Purchasing.PurchaseOrderHeader` 
WHERE  Status = 1 AND  EXTRACT(YEAR FROM ModifiedDate)=2014
GROUP BY EXTRACT(YEAR FROM ModifiedDate) 
      ,Status;

-->
select 
    extract (year from ModifiedDate) as yr
    , Status
    , count(distinct PurchaseOrderID) as order_Cnt 
    , sum(TotalDue) as value
from `adventureworks2019.Purchasing.PurchaseOrderHeader`
where Status = 1
and extract(year from ModifiedDate) = 2014
group by 1,2
;



                                                                        ---good---
