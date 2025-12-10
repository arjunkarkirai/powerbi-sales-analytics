/*
 Create schema
 :Created Scheam analytics_system
Create tables
Create foreign key relationships
Import data from excel file using import wizard
*/
create Database My_Project;

# Creating Tables:
create table My_Project.Customer
(
customer_id	int primary key,
customer_name varchar(30),
gender varchar(10),
age int,
city varchar(20),
sign_up_date date,
loyalty_score int
);

create table My_Project.campaign
(
campaign_id int primary key,
segment varchar(30),
start_date date,
end_date date,
budget int,
revenue_generated float
);

create table My_Project.product
(
product_id int primary key,
product_name varchar(25),
category varchar(25),brand varchar(25),	
unit_price float,
cost_price float,
stock_qty int
);

create table My_Project.returns_pro
(
return_id int primary key,
sale_id int,	
return_date date,
reason varchar(100),
foreign key (sale_id) references My_Project.sales(sale_id)
);

CREATE TABLE My_Project.sales (
    sale_id INT PRIMARY KEY,
    product_id INT,
    customer_id INT,
    quantity INT,
    sale_date DATE,
    discount DECIMAL(5,2),
    channel VARCHAR(20),
    region VARCHAR(20),
    FOREIGN KEY (product_id) REFERENCES my_project.product(product_id),
    FOREIGN KEY (customer_id) REFERENCES my_project.customer(customer_id)
    );
    
    
    # Creating Views:
    -- Sales with calculated revenue & profit
    create or replace view my_project.vw_sales_record as 
    select 
    -- sales table 
	s.sale_id,
    s.quantity,
    s.sale_date, 
    s.discount,
    s.channel,
    s.region,
    -- Product Details
    P.product_name,
    P.category,
    P.brand,
    P.unit_price,
    P.cost_price,
    -- Calculated Financial Metrics
    (s.quantity*p.unit_price) as gross_revenue,
    (s.quantity*p.unit_price * (1-s.discount)) as net_revenue,
     ((s.quantity*p.unit_price * (1-s.discount))-(p.cost_price*s.quantity)) as profit
     from my_project.sales s
     join my_project.product p
     on s.product_id=p.product_id;
     
     -- Customer vlue check.
     create view my_project.customer_value as
     select
     c. customer_id,
     c.customer_name,
     c.gender,
     c.age,
     c.city,
     c.sign_up_date,
     c.loyalty_score,
     count(s.sale_id) as Total_Transaction,
     sum(s.quantity*p.unit_price * (1-s.discount)) as Total_Spending,
     max(s.sale_date) as latest_purchase_date,
     datediff(curdate(), max(s.sale_Date)) as Days_Since_last_Purchse
     from my_project.customer c 
     join my_project.sales s 
     on c.customer_id=s.customer_id
     join my_project.product p on s.product_id=p.product_id
     group by c. customer_id,
     c.customer_name,
     c.gender,
     c.age,
     c.city,
     c.sign_up_date,
     c.loyalty_score;
     
     -- Product performance
     create or replace view my_project.product_per as
     select 
     p.product_id,
	p.product_name,
	p.category, 
	p.brand,
	p.unit_price, 
	p.cost_price,
	p.stock_qty,
	sum(s.quantity) as total_units_sold,
	sum(s.quantity * p.unit_price) AS total_sales,
	 sum(s.quantity* p.unit_price-p.cost_price*p.unit_price)AS total_profit,
    count(r.return_id) AS total_returns
    from my_project.product p 
    join my_project.sales s on p.product_id=s.product_id
    join my_project.returns_pro r on s.sale_id=r.sale_id
    group by  p.product_id,
	p.product_name,
	p.category, 
	p.brand,
	p.unit_price, 
	p.cost_price,
	p.stock_qty;
    
    -- Monthly Sales Summary
    CREATE VIEW my_project.view_month as
    select 
    date_format(s.sale_date, '%y-%m') as monthly_Sales,
	sum(s.quantity*p.unit_price)AS total_revenue,
	sum(s.quantity)AS total_units_sold,
	 count(s.sale_id)AS total_orders
     from my_project.sales s 
     join my_project.product p 
     on s.product_id=p.product_id
     group by date_format(s.sale_date, '%y-%m')
     order by monthly_Sales;
    
     
     
     
     
     
    
    