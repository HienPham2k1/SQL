# SQL
## Explore the dataset
Cách thức thực hiện:
1.	Gọi dữ liệu từ nhóm dữ liệu của  Google Analysis 
2.	Sử dụng Unnest để phân tách dữ liệu 
3.	Tạo lập CTE, sử dụng Join, Group by,  Case when để tính toán 
Dưới đây là kết quả hiển thị:
Query 01: Calculate total visit, pageview, transaction for Jan, Feb and March 2017 (order by month)
 
Query 02: Bounce rate per traffic source in July 2017 (Bounce_rate = num_bounce/total_visit) (order by total_visit DESC)
 
Query 3: Revenue by traffic source by week, by month in June 2017
 
Query 04: Average number of pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017.
 
Query 05: Average number of transactions per user that made a purchase in July 2017
 
Query 06: Average amount of money spent per session. Only include purchaser data in July 2017
 
Query 07: Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017. Output should show product name and the quantity was ordered.
 

Query 08: Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017. For example, 100% product view then 40% add_to_cart and 10% purchase.
Add_to_cart_rate = number product add to cart/number product view. Purchase_rate = number product purchase/number product view. The output should be calculated in product level.
 

## Mục đích thực hiện:
Sử dụng các câu lệnh trong SQL để tổng hợp dữ liệu, biết được tổng số lượng lượt xem, tổng số lượng giao dịch qua từng tháng. Tính được trung bình lượt truy cập mỗi tháng, trung bình lượt giao dịch mỗi tháng. Xây dựng Cohort map, xem được tỉ lệ mua hàng của khách hàng qua từng thời kỳ 
## Insight:
Từ 3 tháng đầu năm 2017, thấy được tỉ lệ để hàng vào giỏ đều tăng từ 28.47% lên 37.29% qua 2 tháng, tăng 8.82%. Trong khi đó tỉ lệ mua hàng tăng từ 8.31% lên đến 12.64%, tăng 4.33%. Thấy được rằng khách hàng đang dần biết đến sản phẩm và tin tưởng mua, tuy nhiên tỉ lệ mua hàng còn rất thấp, với 100 người xem thì chỉ có 11-12 người tin tưởng mua  

