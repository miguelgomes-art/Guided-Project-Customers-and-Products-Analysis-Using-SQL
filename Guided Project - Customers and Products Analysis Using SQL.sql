/*
Introduction
The goal of this project is to analyze data from a sales records database for scale model cars and extract information for decision-making.

Questions
Question 1: Which products should we order more of or less of?
Question 2: How should we tailor marketing and communication strategies to customer behaviors?
Question 3: How much can we spend on acquiring new customers?
*/
PRAGMA table_info(stores);

-- Checking connection
PRAGMA table_info('customers');
/*
It contains eight tables:

	Customers: customer data
	Employees: all employee information
	Offices: sales office information
	Orders: customers' sales orders
	OrderDetails: sales order line for each sales order
	Payments: customers' payment records
	Products: a list of scale model cars
	ProductLines: a list of product line categories

Write a query to display the following table: Select each table name as a string; Select the number of attributes as an integer (count the number of attributes per table); Select the number of rows using the COUNT(*) function; Use the compound-operator UNION ALL to bind these rows together.
*/
SELECT 'Customers' AS table_name, count(*) AS number_of_attributes, 
       (SELECT count(*)  FROM Customers) AS number_of_rows
  FROM pragma_table_info('customers')
UNION ALL
SELECT 'Employees' AS table_name, count(*) AS number_of_attributes, 
       (SELECT count(*)  FROM employees) AS number_of_rows
  FROM pragma_table_info('employees')
UNION ALL
SELECT 'Offices' AS table_name, count(*) AS number_of_attributes, 
       (SELECT count(*)  FROM offices) AS number_of_rows
  FROM pragma_table_info('offices')
UNION ALL
SELECT 'Orderdetails' AS table_name, count(*) AS number_of_attributes, 
       (SELECT count(*)  FROM orderdetails) AS number_of_rows
  FROM pragma_table_info('orderdetails')
UNION ALL
SELECT 'Orders' AS table_name, count(*) AS number_of_attributes, 
       (SELECT count(*)  FROM orders) AS number_of_rows
  FROM pragma_table_info('orders')
UNION ALL
SELECT 'Payments' AS table_name, count(*) AS number_of_attributes, 
       (SELECT count(*)  FROM payments) AS number_of_rows
  FROM pragma_table_info('payments')
UNION ALL
SELECT 'Productlines' AS table_name, count(*) AS number_of_attributes, 
       (SELECT count(*)  FROM productlines) AS number_of_rows
  FROM pragma_table_info('productlines')
UNION ALL
SELECT 'Products' AS table_name, count(*) AS number_of_attributes, 
       (SELECT count(*)  FROM products) AS number_of_rows
  FROM pragma_table_info('products');
  
-- Question 1: Which Products Should We Order More of or Less of? --
/*Write a query to compute the low stock for each product using a correlated subquery.
Round down the result to the nearest hundredth (i.e., two digits after the decimal point).
Select 'productCode', and group the rows.
Keep only the top ten of products by low stock.
*/ 

SELECT p.productCode, p.productName, p.productLine, ROUND((SUM(o.quantityOrdered)/p.quantityInStock),2) AS low_stock
  FROM products AS p, orderdetails AS o
 WHERE EXISTS (
	   SELECT 1
	     FROM orderdetails AS o
		WHERE p.productCode = o.productCode
 )
 GROUP BY p.productCode
 ORDER BY low_stock DESC
 LIMIT 10;
 
-- Write a query to compute the product performance for each product.--

SELECT productCode, SUM(quantityOrdered * priceEach) AS product_performance
  FROM orderdetails AS o
 GROUP BY productCode
 ORDER BY productCode DESC
 LIMIT 10;

SELECT p.productCode,SUM(o.quantityOrdered*o.priceEach) AS product_performance
 FROM   products p,orderdetails o
WHERE  EXISTS(
	   SELECT 1
         FROM orderdetails o
        WHERE p.productCode=o.productCode
)
Group By p.productCode
ORDER BY p.productCode DESC;

 WITH CTE_priority_products AS
 (
 SELECT p.productCode,round((SUM(o.quantityOrdered)/p.quantityInStock),2) AS low_stock
FROM   products p,orderdetails o
WHERE  EXISTS (
			  SELECT 1
                FROM orderdetails o
               WHERE p.productCode=o.productCode
)
Group By p.productCode
ORDER BY low_stock DESC
LIMIT 10),

CTE_product_performance AS
(
SELECT o.productCode,SUM(o.quantityOrdered*o.priceEach) AS product_performance
  FROM orderdetails o
 GROUP BY o.productCode
 ORDER BY product_performance DESC
)

SELECT pp.productCode,pp.low_stock,cpp.product_performance
  FROM CTE_priority_products pp ,CTE_product_performance cpp
  WHERE pp.productCode=cpp.productCode;
  
  /*Question 2: How Should We Match Marketing and Communication Strategies to Customer Behavior?*

Write a query to join the 'products', 'orders', and 'orderdetails' tables to have customers and products information in the same place.

Select 'customerNumber'.

Compute, for each customer, the profit, which is the sum of 'quantityOrdered' multiplied by 'priceEach' minus 'buyPrice': SUM(quantityOrdered * (priceEach - buyPrice)).

This query helps you understand the profit contribution of each customer, which can be useful for tailoring marketing and communication strategies.*/

SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber;
 
 /*Finding the VIP and Less Engaged Customers

The main query selects customer details along with their total profit from the CTE VIP customers */

WITH CTE_Profit AS
(
SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber)
 
SELECT c.contactLastName, c.contactFirstName, c.city, c.country, cp.profit
  FROM customers AS c
  JOIN CTE_profit AS CP
    ON c.customerNumber = cp.customerNumber
 ORDER BY profit DESC
 LIMIT 5;
 
 --Least enagaged customers
 
 WITH CTE_Profit AS
(
SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber)
 
SELECT c.contactLastName, c.contactFirstName, c.city, c.country, cp.profit
  FROM customers AS c
  JOIN CTE_profit AS CP
    ON c.customerNumber = cp.customerNumber
 ORDER BY profit ASC
 LIMIT 5;
 
 /*
 Write a query to compute the average of customer profits using the CTE on the previous screen.

The result provides a list of customers with their contact information, city, country, and average profit per order.

Question 3: How much can we spend on acquiring new customers?
*/

WITH CTE_Profit AS
(
SELECT o.customerNumber,count(o.customerNumber) AS total_customers,
 SUM(quantityOrdered * (priceEach - buyPrice))  AS  profit
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber)
 
 SELECT round(AVG(cp.profit),2) AS avg_profit
   FROM customers c
   JOIN CTE_profit cp
     ON c.customerNumber = cp.customerNumber;
	 
/*
This project examines product performance and customer profitability through SQL. It investigates inventory enhancement by recognizing leading low-stock, high-performing items and categorizing customers based on profit generation. 
By utilizing Common Table Expressions (CTEs), it computes Customer Lifetime Value (LTV) to guide marketing and acquisition tactics. Important takeaways include: 
Giving priority to products for replenishment. 
Recognizing VIP and customers with minimal engagement. 
Determining the average profit per customer to assess acquisition budgets. 
Perfect for companies looking for data-oriented approaches to enhance income and customer loyalty
*/