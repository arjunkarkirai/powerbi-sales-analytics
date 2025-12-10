## Sales Analysis
-- Total revenue, average order value, profit calculations
-- Calcualte total Revenue:
select sum(net_revenue) as total_revenue
from my_project.vw_sales_record;

-- Average_order_value:
select sum(net_revenue)/count(sale_id) as AOV
from my_project.vw_sales_record;

-- Total profit_calculatio:
select sum(profit) as toal_profit
from my_project.vw_sales_record;

# Total profit by year
select year(sale_date) as year_by_profit, sum(profit)
from my_project.vw_sales_record
group by year(sale_date);

-- profit_calcualtion by product:
select 
#sale_id,
product_name,
sum(profit) as total_profit
from my_project.vw_sales_record
group by  product_name
order by total_profit;

-- YoY, MoM trends
# Compare revenue this year vs last year for the same month.
select 
this.monthly_Sales as current_month,
this.total_revenue as current_revenue,
last.total_revenue as last_year_revenue,
coalesce((this.total_revenue-last.total_revenue)/nullif(last.total_revenue,0)*100,null) as YOY_Growdth
-- using self join to compare the latest year month and previous year month and comparing the years too.
from my_project.view_month this
left join my_project.view_month last
on date_format(str_to_date(this.monthly_Sales, '%y-%m'), '%m')=
date_format(str_to_date(last.monthly_Sales, '%y-%m'), '%m')
and 
date_format(str_to_date(this.monthly_Sales, '%y-%m'),'%y')=
date_format(str_to_date(last.monthly_Sales, '%y-%m'),'%y')+1
order by this.monthly_Sales;


-- Sales by region, channel, category
-- profit, total revenue by region
select
region, sum(profit) as profit_by_region, sum(net_revenue) as total_Revenue_region
from my_project.vw_sales_record
group by region;

-- by channel
select
channel, sum(profit) as profit_by_region, sum(net_revenue) as total_Revenue_region
from my_project.vw_sales_record
group by channel;

-- by category
select
categoryproduct_per, sum(profit) as profit_by_region, sum(net_revenue) as total_Revenue_region
from my_project.vw_sales_record
group by category;

-- Total Sales by category, channel and region
select v2.category,v2.channel, v2.region, sum(v1.total_sales) as sales
from my_project.product_per v1
right join my_project.vw_sales_record v2
on v1.category=v2.category
Group by v2.category,v2.channel, v2.region;

# Customer Analytics
-- Customer lifetime value (CLV)
-- CLV=Average Order Value×Purchase Frequency×Average Customer Lifespan (in years)
select 
customer_id, customer_name, gender,age,
(Total_spending/Total_Transaction) as AOV,
((Total_Transaction/ datediff(latest_purchase_date,sign_up_date))/365)as Customer_life_span,
((Total_spending/Total_Transaction)*((Total_Transaction/ datediff(latest_purchase_date,sign_up_date))/365)) as CLV
from my_project. customer_value
order by CLV;

-- High-value customer identification
select 
customer_id, customer_name, gender,age,
(Total_spending/Total_Transaction) as AOV,
((Total_Transaction/ datediff(latest_purchase_date,sign_up_date))/365)as Customer_life_span,
((Total_spending/Total_Transaction)*((Total_Transaction/ datediff(latest_purchase_date,sign_up_date))/365)) as CLV
from my_project. customer_value
order by CLV desc;
-- New vs returning customer segmentation
#with customer_segmentation as(
select
s.customer_id,
c.customer_name,
s.sale_date,
min(s.sale_date) over(partition by s.customer_id) as customer_first_purchase,
case
when s.sale_date=min(s.sale_date) over (partition by s.customer_id) then 'New Customer'
else 'Returning Customer'
end as customer_segment
from my_project.sales s
join my_project.customer c
on s.customer_id= c.customer_id;

select sum(v.profit), c.gender
from my_project.vw_sales_record v 
join my_project.sales s 
on v.sale_id=s.sale_id
join my_project.customer c
on s.customer_id=c.customer_id
group by c.gender;


#Product Analytics
-- Best-selling products
with product_Sales_summary as(
select
p.product_id,
p.product_name,
count(s.product_id) as total_product_sold
from my_project.sales s
join my_project.product p
on s.product_id=p.product_id
group by p.product_id, p.product_name
)
select
product_name, total_product_sold,
dense_rank() over(order by total_product_sold desc) as product_salse_rank
from product_Sales_summary
order by product_salse_rank;

-- Least-performing items
with product_summary as
(
select 
p.product_id,
p.product_name,
count(s.product_id) as total_unit_sold
from my_project.sales s
join my_project.product p
on s.product_id=p.product_id
group by p.product_id,p.product_name
)
select product_name, total_unit_sold,
dense_rank() over (order by total_unit_sold asc) as lest_performing_items
from product_summary
order by lest_performing_items;

-- Low-stock alerts
select product_id, product_name,stock_qty,
case
when stock_qty <100 then 'Low_stock'
when stock_qty >100 and stock_qty < 300 then 'Need Attention'
else 'Good Stock'
end as stock_alert
from my_project.product_per;

-- Product margin analysis
select product_name,
sum(net_revenue) as total_revenue,
sum(profit) as total_profit,
(sum(profit)/ sum(net_revenue))*100 as profit_margine,
case
when (sum(profit)/ sum(net_revenue))*100 > 90 then 'Good Profit'
when (sum(profit)/ sum(net_revenue))*100 < 90 and (sum(profit)/ sum(net_revenue))*100>70 then 'Above Average Profit'
when (sum(profit)/ sum(net_revenue))*100 < 70 and (sum(profit)/ sum(net_revenue))*100 > 50 then 'Average profit'
else 'Below Average'
end as Remarks
from my_project.vw_sales_record
group by product_name;

#Return Analysis
-- Return rate by product & category
select 
product_id, product_name,
(total_returns/ nullif(total_units_sold,0))*100 as return_rate_per_product
from my_project.product_per;

-- By category
select 
category,
sum(total_returns) as total_returncat,
sum(total_units_sold) as total_units_soldcat,
(sum(total_returns)/ nullif(sum(total_units_sold),0))*100 as return_rate_per_product
from my_project.product_per
group by category;

-- Loss impact due to returns
select 
v1.product_name, v1.total_returns,v1.unit_price ,
-- 1. Total Revenue Lost (Money Refunded)
(v1.total_returns)*(v1.unit_price) as net_amount_refunded,
-- 2. Total Cost Incurred (The true profit loss, assuming the item can't be resold)
(v1.total_returns*v1.cost_price) as total_cost_of_returns,
-- 3. The Combined Financial Impact (Most Comprehensive Loss Metric)
(v1.total_returns*(v1.unit_price+v1.cost_price)) as total_impact_on_income 
from my_project.product_per v1;

-- Defective vs customer-choice returns
-- Count product returned becasue of any one cause
select 
count(s.product_id) as number_of_return, r.reason
from my_project.sales s
join my_project.returns_pro r 
on s.sale_id=r.sale_id
group by r.reason;

-- Calculate Financial Loss for Defective Items
-- count only the defective products(marked as defective and broken)
with return_summary as
(select 
s.product_id, count(s.sale_id) as defective_item_return
from my_project.sales s
join my_project.returns_pro p
on s.sale_id=p.sale_id
where p.reason in ('Defective', 'Broken')
group by s.product_id
)
select 
v.product_id, ps.defective_item_return,
(v.unit_price*ps.defective_item_return) as loss_on_unit_item,
(v.cost_price*ps.defective_item_return) as loss_on_buying,
(ps.defective_item_return*(v.unit_price+v.cost_price))as total_loss
from return_summary ps
inner join my_project.product_per v on 
ps.product_id=v.product_id;

# Marketing Analytics
-- Campaign ROI
select
campaign_id,
sum(budget) as total_budget,
sum(revenue_generated) as total_incone,
((sum(revenue_generated)-sum(budget))/sum(budget))* 100 as ROI
from my_project.campaign
group by campaign_id;

-- Segment performance
select 
segment,
sum(budget)as total_cost,
sum(revenue_generated) as total_income,
((sum(revenue_generated)-sum(budget))/sum(budget))*100 as per_Segment
from my_project.campaign
group by segment
order by per_segment desc;







