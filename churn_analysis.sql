create database project1;
use project1;
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    age INT,
    signup_date DATE,
    contract_type VARCHAR(20) CHECK (contract_type IN ('Monthly', 'Annual', 'Prepaid')),
    churn_status BOOLEAN
);

CREATE TABLE monthly_usage_data (
    usage_id INT PRIMARY KEY,
    customer_id INT,
    month DATE,
    data_usage_gb FLOAT,
    call_minutes INT,
    sms_count INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE billing (
    bill_id INT PRIMARY KEY,
    customer_id INT,
    bill_date DATE,
    bill_amount DECIMAL(10,2),
    payment_status VARCHAR(20) CHECK (payment_status IN ('Paid', 'Pending', 'Failed')),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE customer_support (
    ticket_id INT PRIMARY KEY,
    customer_id INT,
    issue_type VARCHAR(50) CHECK (issue_type IN ('Network', 'Billing', 'Service', 'Other')),
    resolution_time_days INT,
    resolved_status BOOLEAN,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Insert sample data into customers table
INSERT INTO customers (customer_id, name, age, signup_date, contract_type, churn_status) VALUES
(1, 'Customer_1', 25, '2022-03-15', 'Monthly', 0),
(2, 'Customer_2', 34, '2020-07-22', 'Annual', 1),
(3, 'Customer_3', 45, '2021-12-05', 'Prepaid', 0),
(4, 'Customer_4', 28, '2023-05-19', 'Monthly', 1),
(5, 'Customer_5', 39, '2019-11-11', 'Annual', 0);
INSERT INTO customers (customer_id, name, age, signup_date, contract_type, churn_status) VALUES
(6, 'Customer_6', 30, '2021-05-25', 'Monthly', 0),
(7, 'Customer_7', 41, '2020-10-10', 'Annual', 1),
(8, 'Customer_8', 29, '2023-02-18', 'Prepaid', 1),
(9, 'Customer_9', 37, '2018-06-30', 'Monthly', 0),
(10, 'Customer_10', 50, '2017-11-05', 'Annual', 1);

-- Insert sample data into usage table
INSERT INTO monthly_usage_data (usage_id, customer_id, month, data_usage_gb, call_minutes, sms_count) VALUES
(1, 1, '2024-01-10', 20.5, 1200, 50),
(2, 3, '2024-02-15', 5.3, 800, 20),
(3, 5, '2024-03-12', 50.7, 1500, 100),
(4, 2, '2024-01-20', 35.2, 1100, 80),
(5, 4, '2024-02-28', 10.1, 500, 30);
INSERT INTO monthly_usage_data (usage_id, customer_id, month, data_usage_gb, call_minutes, sms_count) VALUES
(6, 6, '2024-03-10', 25.6, 1300, 45),
(7, 7, '2024-04-05', 12.3, 700, 15),
(8, 8, '2024-05-18', 55.2, 1600, 120),
(9, 9, '2024-06-25', 32.1, 1400, 75),
(10, 10, '2024-07-02', 8.9, 400, 10);

-- Insert sample data into billing table
INSERT INTO billing (bill_id, customer_id, bill_date, bill_amount, payment_status) VALUES
(1, 1, '2024-01-01', 55.75, 'Paid'),
(2, 3, '2024-02-01', 20.00, 'Failed'),
(3, 5, '2024-03-01', 75.30, 'Paid'),
(4, 2, '2024-01-15', 33.40, 'Pending'),
(5, 4, '2024-02-12', 45.00, 'Paid');
INSERT INTO billing (bill_id, customer_id, bill_date, bill_amount, payment_status) VALUES
(6, 6, '2024-03-22', 67.50, 'Paid'),
(7, 7, '2024-04-08', 29.90, 'Failed'),
(8, 8, '2024-05-15', 82.60, 'Paid'),
(9, 9, '2024-06-28', 41.20, 'Pending'),
(10, 10, '2024-07-05', 12.75, 'Paid');

-- Insert sample data into customer_support table
INSERT INTO customer_support (ticket_id, customer_id, issue_type, resolution_time_days, resolved_status) VALUES
(1, 1, 'Billing', 2, 1),
(2, 3, 'Network', 5, 0),
(3, 5, 'Service', 1, 1),
(4, 2, 'Other', 7, 0),
(5, 4, 'Network', 3, 1);
INSERT INTO customer_support (ticket_id, customer_id, issue_type, resolution_time_days, resolved_status) VALUES
(6, 6, 'Billing', 4, 1),
(7, 7, 'Service', 2, 0),
(8, 8, 'Network', 6, 1),
(9, 9, 'Other', 5, 0),
(10, 10, 'Billing', 3, 1);

--  the data is now ready to analyze customer churn with sql

-- 1. Identifying the churned customers : Customers who have already left
SELECT * 
FROM customers
WHERE churn_status = 1;

-- 2. Finding High-Risk Churn Customers
/* we can identify customers who haven't churned yet but have 3 signs of churning soon
1. Low Usage
2. Frequent Payment Failures
3. Multiple Support Complaints
*/
SELECT 
    c.customer_id,
    c.name,
    c.contract_type,
    AVG(u.data_usage_gb) AS avg_data_usage,
    COUNT(DISTINCT b.bill_id) AS total_bills,
    SUM(CASE WHEN b.payment_status = 'Failed' THEN 1 ELSE 0 END) AS failed_payments,
    COUNT(cs.ticket_id) AS support_tickets
FROM customers c
LEFT JOIN monthly_usage_data u ON c.customer_id = u.customer_id
LEFT JOIN billing b ON c.customer_id = b.customer_id
LEFT JOIN customer_support cs ON c.customer_id = cs.customer_id
WHERE c.churn_status = 0
GROUP BY c.customer_id, c.name, c.contract_type
HAVING AVG(u.data_usage_gb) < 10 
   OR SUM(CASE WHEN b.payment_status = 'Failed' THEN 1 ELSE 0 END) >= 1
   OR COUNT(cs.ticket_id) > 2;

-- 3. Checking which contract has the highest churn rate
SELECT contract_type, 
       COUNT(*) AS total_customers, 
       SUM(CASE WHEN churn_status = 1 THEN 1 ELSE 0 END) AS churned_customers,
       ROUND(SUM(CASE WHEN churn_status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM customers
GROUP BY contract_type
ORDER BY churn_rate DESC;

-- 4. Finding whose payments was last unpaid and churned later
SELECT c.customer_id, c.name, b.bill_date, b.bill_amount, b.payment_status
FROM customers c
JOIN billing b ON c.customer_id = b.customer_id
WHERE c.churn_status = 1 
  AND b.payment_status = 'Failed'
ORDER BY b.bill_date DESC;

-- 5. Most Common issues for the churned customers
SELECT cs.issue_type, COUNT(*) AS total_complaints
FROM customer_support cs
JOIN customers c ON cs.customer_id = c.customer_id
WHERE c.churn_status = 1
GROUP BY cs.issue_type
ORDER BY total_complaints DESC;

-- 6. Compare usage between churned customers and active customers
SELECT 
    c.churn_status,
    ROUND(AVG(u.data_usage_gb), 2) AS avg_data_usage,
    ROUND(AVG(u.call_minutes), 2) AS avg_call_minutes,
    ROUND(AVG(u.sms_count), 2) AS avg_sms_count
FROM customers c
JOIN monthly_usage_data u ON c.customer_id = u.customer_id
GROUP BY c.churn_status;

-- 7. Did unresolved or delayed issues push customers away?
SELECT 
    c.churn_status,
    ROUND(AVG(cs.resolution_time_days), 2) AS avg_resolution_time,
    SUM(CASE WHEN cs.resolved_status = 0 THEN 1 ELSE 0 END) AS unresolved_issues
FROM customers c
JOIN customer_support cs ON c.customer_id = cs.customer_id
GROUP BY c.churn_status;

-- 8. Frequent Churned Customers Combination of contract and issue types
SELECT 
    c.contract_type,
    cs.issue_type,
    COUNT(*) AS churned_with_issue
FROM customers c
JOIN customer_support cs ON c.customer_id = cs.customer_id
WHERE c.churn_status = 1
GROUP BY c.contract_type, cs.issue_type
ORDER BY churned_with_issue DESC;
