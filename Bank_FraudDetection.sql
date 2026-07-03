
 --  Fraud Detection Based on Rapid Successive Transactions


--  1. DDL: SCHEMA 
DROP TABLE IF EXISTS Transactions, Loans, Accounts, Employees, Customers, Branches CASCADE;
Create Database Bank;
Use Bank;
CREATE TABLE Branches (
    branch_id     SERIAL PRIMARY KEY,
    branch_name   VARCHAR(50) NOT NULL,
    city          VARCHAR(50) NOT NULL
);

CREATE TABLE Customers (
    customer_id   SERIAL PRIMARY KEY,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(100) UNIQUE NOT NULL,
    phone         VARCHAR(15) UNIQUE
);

CREATE TABLE Employees (
    employee_id   SERIAL PRIMARY KEY,
    branch_id     INT REFERENCES Branches(branch_id),
    full_name     VARCHAR(100) NOT NULL,
    role          VARCHAR(30) DEFAULT 'Clerk'
);

CREATE TABLE Accounts (
    account_id    SERIAL PRIMARY KEY,
    customer_id   INT REFERENCES Customers(customer_id) ON DELETE CASCADE,
    branch_id     INT REFERENCES Branches(branch_id),
    account_type  VARCHAR(20) CHECK (account_type IN ('SAVINGS','CURRENT')),
    balance       NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    opened_date   DATE DEFAULT (CURRENT_DATE)
);

CREATE TABLE Transactions (
    transaction_id   SERIAL PRIMARY KEY,
    account_id       INT REFERENCES Accounts(account_id) ON DELETE CASCADE,
    txn_type         VARCHAR(10) CHECK (txn_type IN ('DEPOSIT','WITHDRAW')),
    amount           NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    txn_timestamp    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Loans (
    loan_id        SERIAL PRIMARY KEY,
    customer_id    INT REFERENCES Customers(customer_id),
    principal      NUMERIC(14,2) NOT NULL,
    interest_rate  NUMERIC(4,2) DEFAULT 8.5,
    start_date     DATE DEFAULT (CURRENT_DATE),
    status         VARCHAR(15) DEFAULT 'ACTIVE'
);

-- 2. DML: SAMPLE DATA
INSERT INTO Branches (branch_name, city) VALUES
('MG Road','Bengaluru'),('Okkiyampet','Chennai'),('Andheri','Mumbai');

INSERT INTO Customers (full_name, email, phone) VALUES
('Hari','hari@mail.com','9000000001'),
('Priya ','priya@mail.com','9000000002'),
('Rahul','rahul@mail.com','9000000003'),
('Sneha ','sneha@mail.com','9000000004'),
('Vikram ','vikram@mail.com','9000000005');

INSERT INTO Employees (branch_id, full_name, role) VALUES
(1,'Kiran Shah','Manager'),(2,'Divya Menon','Clerk'),(3,'Sameer Khan','Manager');

INSERT INTO Accounts (customer_id, branch_id, account_type, balance) VALUES
(1,1,'SAVINGS',50000),(2,1,'CURRENT',120000),(3,2,'SAVINGS',30000),
(4,2,'SAVINGS',75000),(5,3,'CURRENT',200000);

INSERT INTO Transactions (account_id, txn_type, amount, txn_timestamp) VALUES
(1,'DEPOSIT',10000,'2025-01-05 10:00'),(1,'WITHDRAW',2000,'2025-01-06 11:00'),
(2,'DEPOSIT',50000,'2025-01-07 09:30'),(2,'WITHDRAW',15000,'2025-01-07 09:31'),
(3,'DEPOSIT',5000,'2025-02-01 14:00'),(4,'DEPOSIT',20000,'2025-02-10 16:00'),
(4,'WITHDRAW',5000,'2025-02-11 08:00'),(5,'DEPOSIT',100000,'2025-03-01 12:00'),
(1,'DEPOSIT',3000,'2025-03-15 13:00'),(2,'DEPOSIT',10000,'2025-03-20 10:00');

INSERT INTO Loans (customer_id, principal, interest_rate, status) VALUES
(1,200000,8.0,'ACTIVE'),(3,500000,7.5,'ACTIVE'),(5,100000,9.0,'CLOSED');

-- 3. Basic queries --
-- Display all customers
SELECT * FROM Customers;

-- Display only Savings accounts
SELECT *FROM Accounts WHERE account_type='SAVINGS';

-- Sort customers by highest balance
SELECT * FROM Accounts ORDER BY balance DESC;

-- Display first 5 transactions
SELECT * FROM Transactions LIMIT 5;

-- Aggregation Functions --

-- Count total customers
SELECT COUNT(*) FROM Customers;

-- Total balance across all accounts
SELECT SUM(balance) FROM Accounts;

-- Average account balance
SELECT AVG(balance) FROM Accounts;

-- Highest balance
SELECT MAX(balance) FROM Accounts;

-- Lowest balance
SELECT MIN(balance) FROM Accounts;

-- 5 – Joins with GROUP BY & HAVING 

-- Total Balance Available in Each Branch
SELECT b.branch_id,b.branch_name,SUM(a.balance) AS total_branch_balance FROM Branches b
JOIN Accounts a ON b.branch_id = a.branch_id
GROUP BY b.branch_id, b.branch_name;

--  Number of Customers in Each Branch

SELECT b.branch_id,b.branch_name,COUNT(a.customer_id) AS total_customers FROM Branches b
JOIN Accounts a ON b.branch_id = a.branch_id
GROUP BY b.branch_id, b.branch_name;

-- Branches Having Deposits Greater Than ₹100000
SELECT b.branch_name,SUM(t.amount) AS total_deposits FROM Branches b
JOIN Accounts a ON b.branch_id = a.branch_id
JOIN Transactions t ON a.account_id = t.account_id
WHERE t.txn_type = 'DEPOSIT' GROUP BY b.branch_name
HAVING SUM(t.amount) >= 100000;

-- Average Account Balance by Branch
SELECT b.branch_name,AVG(a.balance) AS average_balance FROM Branches b
JOIN Accounts a ON b.branch_id = a.branch_id
GROUP BY b.branch_name;

-- Total Deposit and Withdrawal Amount by Branch
SELECT
    b.branch_name,
    SUM(CASE
            WHEN t.txn_type='DEPOSIT'
            THEN t.amount
            ELSE 0
        END) AS total_deposit,

    SUM(CASE
            WHEN t.txn_type='WITHDRAW'
            THEN t.amount
            ELSE 0
        END) AS total_withdrawal

FROM Branches b JOIN Accounts a ON b.branch_id = a.branch_id
JOIN Transactions t ON a.account_id = t.account_id
GROUP BY b.branch_name;

-- 6- SubQuery
-- Customers Having Above Average Account Balance
SELECT c.customer_id,c.full_name,a.account_id,a.balance
FROM Customers c JOIN Accounts a ON c.customer_id = a.customer_id
WHERE a.balance >(SELECT AVG(balance)FROM Accounts);

-- Account with the Highest Balance
SELECT account_id,customer_id,balance
FROM Accounts WHERE balance =( SELECT MAX(balance) FROM Accounts);

-- Customers Without Loans
SELECT customer_id,full_name,email FROM Customers
WHERE customer_id NOT IN(SELECT customer_id FROM Loans);

-- Customers Having Multiple Accounts
SELECT customer_id,full_name FROM Customers WHERE customer_id IN
(
SELECT customer_id FROM Accounts 
GROUP BY customer_id HAVING COUNT(account_id) > 1
);


-- 7. VIEWS

-- Account summary using view table
CREATE OR REPLACE VIEW vw_account_summary AS
SELECT a.account_id, c.full_name, b.branch_name, a.account_type, a.balance
FROM Accounts a
JOIN Customers c ON a.customer_id = c.customer_id
JOIN Branches b ON a.branch_id = b.branch_id;
select * from vw_account_summary;


CREATE OR REPLACE VIEW vw_monthly_branch_summary AS
SELECT
    b.branch_name,
    DATE_FORMAT(t.txn_timestamp, '%Y-%m') AS txn_month,
    SUM(CASE
            WHEN t.txn_type = 'DEPOSIT' THEN t.amount
            ELSE 0
        END) AS total_deposits,
    SUM(CASE
            WHEN t.txn_type = 'WITHDRAW' THEN t.amount
            ELSE 0
        END) AS total_withdrawals
FROM Transactions t
JOIN Accounts a
    ON t.account_id = a.account_id
JOIN Branches b
    ON a.branch_id = b.branch_id
GROUP BY
    b.branch_name,
    DATE_FORMAT(t.txn_timestamp, '%Y-%m');

select * from vw_monthly_branch_summary ;


-- 8. STORED PROCEDURES 
DELIMITER $$

CREATE PROCEDURE TransferMoney(
    IN p_from_account BIGINT,
    IN p_to_account BIGINT,
    IN p_amount DECIMAL(12,2)
)
BEGIN
    DECLARE v_balance DECIMAL(12,2);

    -- Get sender balance
    SELECT balance
    INTO v_balance
    FROM Accounts
    WHERE account_id = p_from_account;

    -- Check sufficient balance
    IF v_balance < p_amount THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient funds.';
    END IF;

    -- Debit sender
    UPDATE Accounts
    SET balance = balance - p_amount
    WHERE account_id = p_from_account;

    -- Credit receiver
    UPDATE Accounts
    SET balance = balance + p_amount
    WHERE account_id = p_to_account;

    -- Record withdrawal
    INSERT INTO Transactions(account_id, txn_type, amount)
    VALUES (p_from_account, 'WITHDRAW', p_amount);

    -- Record deposit
    INSERT INTO Transactions(account_id, txn_type, amount)
    VALUES (p_to_account, 'DEPOSIT', p_amount);

END$$

DELIMITER ;

-- Usage: CALL sp_transfer_funds(1, 3, 5000);
SELECT * FROM Accounts;
-- Before calling stored procedure that is before transferring the money

SELECT account_id, balance FROM Accounts WHERE account_id IN (1, 2);
CALL TransferMoney(1, 2, 5000);

-- After calling the stored procedure from accountid  1 to account id  2  amount is  transferred
SELECT account_id, balance FROM Accounts WHERE account_id IN (1, 2);

-- 9. TRIGGERS 

-- Stores the history of balance changes made to accounts.

CREATE TABLE IF NOT EXISTS Audit_Log (
    log_id SERIAL PRIMARY KEY,
    account_id INT,
    action VARCHAR(20),
    old_balance NUMERIC,
    new_balance NUMERIC,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
SELECT * FROM Audit_Log;


-- Whenever an account balance changes,store the old and new balance inside Audit_Log.


DELIMITER $$

CREATE TRIGGER trg_balance_audit
AFTER UPDATE ON Accounts
FOR EACH ROW
BEGIN

    IF OLD.balance <> NEW.balance THEN

        INSERT INTO Audit_Log
        (
            account_id,
            action,
            old_balance,
            new_balance
        )
        VALUES
        (
            NEW.account_id,
            'BALANCE_UPDATED',
            OLD.balance,
            NEW.balance
        );
    END IF;
END$$
DELIMITER ;

/*===========================================================
Before Updating Account Balance
===========================================================*/

SELECT
account_id,
balance
FROM Accounts
WHERE account_id=1;

/*===========================================================
Update Account Balance

Trigger Automatically Executes
===========================================================*/

UPDATE Accounts
SET balance=55000
WHERE account_id=1;

/*===========================================================
After Updating Account
===========================================================*/

SELECT
account_id,
balance
FROM Accounts
WHERE account_id=1;
--  10.TCL 
-- Transfer ₹5000 from Account 1 to Account 2. Save all changes permanently.
START TRANSACTION;

UPDATE Accounts
SET balance = balance - 5000
WHERE account_id = 1;

UPDATE Accounts
SET balance = balance + 5000
WHERE account_id = 2;

COMMIT;

SELECT account_id, balance
FROM Accounts
WHERE account_id IN (1,2);

-- Rollback only a portion of the transaction.

START TRANSACTION;
UPDATE Accounts
SET balance = balance - 5000
WHERE account_id = 1;
SAVEPOINT after_first_transfer;
UPDATE Accounts
SET balance = balance + 5000
WHERE account_id = 2;

ROLLBACK TO SAVEPOINT after_first_transfer;

COMMIT;


-- Fraud Detection Scenario 
-- Insert 4 records
/*===========================================================
Demo Data for Fraud Detection
Purpose:
Create transactions with different time gaps
===========================================================*/

INSERT INTO Transactions(account_id, txn_type, amount, txn_timestamp)
VALUES
(5,'DEPOSIT',50000,'2025-06-01 10:00:00'),

-- 20 seconds later
(5,'WITHDRAW',5000,'2025-06-01 10:00:20'),

-- 45 seconds later
(5,'DEPOSIT',7000,'2025-06-01 10:01:05'),

-- 5 minutes later
(5,'WITHDRAW',3000,'2025-06-01 10:06:05');




/*
Fraud Detection using Time Gap

Purpose:
Identify suspicious transactions based on the
time difference between consecutive transactions
for the same account.

Concepts Used:
✔ CTE
✔ Window Function (LAG)
✔ TIMESTAMPDIFF()
✔ CASE
===========================================================*/

WITH transaction_history AS
(
    SELECT
        transaction_id,
        account_id,
        txn_type,
        amount,
        txn_timestamp,

        LAG(txn_timestamp)
        OVER
        (
            PARTITION BY account_id
            ORDER BY txn_timestamp
        ) AS previous_transaction

    FROM Transactions
)

SELECT account_id,transaction_id,txn_type,amount,previous_transaction,txn_timestamp,
TIMESTAMPDIFF(SECOND,previous_transaction,txn_timestamp) AS seconds_gap,
    CASE
        WHEN previous_transaction IS NULL
        THEN 'First Transaction'
        WHEN TIMESTAMPDIFF
        (
            SECOND,
            previous_transaction,
            txn_timestamp
        ) <=30
        THEN 'High Risk'
        WHEN TIMESTAMPDIFF
        (
            SECOND,
            previous_transaction,
            txn_timestamp
        ) <=60
        THEN ' Medium Risk'
        ELSE ' Normal'
    END AS fraud_risk
FROM transaction_history
ORDER BY
account_id,
txn_timestamp;
