# Ecommerce Dataset
## Explore the dataset 
- Để có thể hiểu hơn về các câu lệnh querry bên dưới, ta có thể xem xét cấu trúc ban đầu của tập dữ liệu. 
![image](https://github.com/user-attachments/assets/020ee3d4-921b-455f-a585-ed6957a9481f)
- Thấy được rằng tập dữ liệu chứa các tệp dữ liệu nhỏ bên trong, hãy cùng xem cấu trúc của dữ liệu: 
<img src="https://github.com/user-attachments/assets/5e1da5e3-85ad-4c9e-b3b6-5f89e48e4370" alt="..." width="800" />                                                                                              ---

- Thấy được rằng cấu trúc của tập dữ liệu là hình số 3, vậy nên để có thể lấy được những dữ liệu phía bên trong của các tập lớn thì ta phải gọi các tập lớn ra trước. Sử dụng câu lệnh Unnest. Cách thức thực hiện:
1.	Gọi dữ liệu từ nhóm dữ liệu của  Google Analysis 
2.	Sử dụng Unnest để phân tách dữ liệu 
3.	Tạo lập CTE, sử dụng Join, Group by,  Case when để tính toán 
- Dưới đây là một số những yêu cầu để có thể phân tích tập dữ liệu

Query 01: Calculate total visit, pageview, transaction for Jan, Feb and March 2017 (order by month)
 
Query 02: Bounce rate per traffic source in July 2017 (Bounce_rate = num_bounce/total_visit) (order by total_visit DESC)
 
Query 03: Revenue by traffic source by week, by month in June 2017
 
Query 04: Average number of pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017.
 
Query 05: Average number of transactions per user that made a purchase in July 2017
 
Query 06: Average amount of money spent per session. Only include purchaser data in July 2017
 
Query 07: Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017. Output should show product name and the quantity was ordered.

Query 08: Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017. For example, 100% product view then 40% add_to_cart and 10% purchase.
Add_to_cart_rate = number product add to cart/number product view. Purchase_rate = number product purchase/number product view. The output should be calculated in product level.
<img src="https://github.com/user-attachments/assets/6a807236-2d7a-4ddf-bb6f-60920edd282d" alt="..." width="800" /> 
## Mục đích thực hiện:
Sử dụng các câu lệnh trong SQL để tổng hợp dữ liệu, biết được tổng số lượng lượt xem, tổng số lượng giao dịch qua từng tháng. Tính được trung bình lượt truy cập mỗi tháng, trung bình lượt giao dịch mỗi tháng. Xây dựng Cohort map, xem được tỉ lệ mua hàng của khách hàng qua từng thời kỳ 
## Insight:
Từ 3 tháng đầu năm 2017, thấy được tỉ lệ để hàng vào giỏ đều tăng từ 28.47% lên 37.29% qua 2 tháng, tăng 8.82%. Trong khi đó tỉ lệ mua hàng tăng từ 8.31% lên đến 12.64%, tăng 4.33%. Thấy được rằng khách hàng đang dần biết đến sản phẩm và tin tưởng mua, tuy nhiên tỉ lệ mua hàng còn rất thấp, với 100 người xem thì chỉ có 11-12 người tin tưởng mua  

# Bicycle Manufacture
## Explore the Dataset
- Với tập dữ liệu này, sẽ không cần phải Unnest nữa, tuy nhiên cần đọc kỹ Data Dictionary, để có thể biết dữ liệu đang nằm ở đâu

Q1: Calc Quantity of items, Sales value & Order quantity by each Subcategory in L12M

Q2: Calc % YoY growth rate by SubCategory & release top 3 cat with highest grow rate. Can use metric: quantity_item. Round results to 2 decimal

Q3: Ranking Top 3 TeritoryID with biggest Order quantity of every year. If there's TerritoryID with same quantity in a year, do not skip the rank number

Q4: Calc Total Discount Cost belongs to Seasonal Discount for each SubCategory

Q5: Retention rate of Customer in 2014 with status of Successfully Shipped (Cohort Analysis)

Q6: Trend of Stock level & MoM diff % by all product in 2011. If %gr rate is null then 0. Round to 1 decimal

Q7: Calc Ratio of Stock / Sales in 2011 by product name, by month. Order results by month desc, ratio desc. Round Ratio to 1 decimal mom yoy
Q8: No of order and value at Pending status in 2014
## Mục đích thực hiện:
Tính toán được tổng số lượng sản phẩm, tổng doanh thu cũng như tổng số lượng đặt hàng theo từng Sub Category. Ranking top 3 các sản phẩm có lượng Order cao trong năm. Thống kê được sự tăng trưởng của các Sub Category qua từng năm. Tạo lập được bảng biểu thị sự tăng trưởng Retention Rate của khách hàng trong từng thời kỳ
## Retention Rate:
Để tạo dựng được bảng Cohort ta cần có cái nhìn tổng quan về kết quả mình muốn tạo ra. Kết quả cuối cùng sẽ có hình dáng giống như hình tam giác bên dưới

<img src="https://github.com/user-attachments/assets/2a128a04-d198-4238-8322-9f2489d8b6d3" alt="..." width="800" /> 

Chúng ta cần tính toán số lượng khách hàng mua lần đầu tại từng tháng, sau mỗi tháng còn lại bao nhiêu khách hàng vẫn còn mua hàng. Cách làm chi tiết được viết tại đây: ( )



