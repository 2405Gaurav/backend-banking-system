-- =================================================================================================
-- BANK MANAGEMENT SYSTEM (Advanced SQL Implementation)
-- Author: Gaurav
-- Date: 2025-07-14
-- Version: 2.0
-- =================================================================================================
-- OVERVIEW:
-- This SQL script implements a fully functional, real-world inspired **Bank Management System**
-- with automation using Triggers, Procedures, and Constraints.
-- It demonstrates:
--     1. Database normalization principles (3NF)
--     2. Referential integrity with FOREIGN KEYS
--     3. Business logic enforcement via CHECK constraints
--     4. Automation with AFTER UPDATE & AFTER INSERT TRIGGERS
--     5. Stored Procedures for reporting and operations
--     6. Sample queries for analysis
--
-- TABLES:
--     1. Account_opening_form  --> Captures customer application details
--     2. BANK                  --> Maintains account core details
--     3. ACCOUNT_HOLDER_DETAILS--> Stores personal info of approved customers
--     4. TRANSACTION_DETAILS   --> Transaction history
--
-- BUSINESS RULES:
--     - Aadhar Number must be unique (national identity verification)
--     - Minimum opening balance for Savings account: 1000 INR
--     - KYC approval is mandatory before account activation
--     - All account numbers auto-generate sequentially starting from 10000
--     - Transactions auto-update current balance
--     - DEBIT cannot exceed current balance (business safety rule)
--
-- EXTRA FEATURES:
--     - INDEXES for faster lookups
--     - PROCEDURE for monthly passbook
--     - FUNCTION to get account balance instantly
--     - SAMPLE REPORT queries for analytics
-- =================================================================================================

-- =============================
-- 1. DATABASE CREATION
-- =============================
CREATE DATABASE bankM;
USE bankM;

-- =============================
-- 2. TABLE: Account_opening_form
-- =============================
CREATE TABLE Account_opening_form (
    ID INT PRIMARY KEY,
    DATE DATE DEFAULT GETDATE(),
    ACCOUNT_TYPE VARCHAR(20) DEFAULT 'SAVINGS' CHECK (ACCOUNT_TYPE IN ('SAVINGS', 'CURRENT')),
    ACCOUNT_HOLDER_NAME VARCHAR(100) NOT NULL,
    DOB DATE NOT NULL,
    AADHAR_NUMBER VARCHAR(12) NOT NULL UNIQUE,
    MOBILE_NUMBER VARCHAR(15) NOT NULL UNIQUE,
    ACCOUNT_OPENING_BALANCE DECIMAL(10,2) CHECK (ACCOUNT_OPENING_BALANCE >= 1000),
    ADDRESS1 VARCHAR(255) NOT NULL,
    KYC_STATUS VARCHAR(20) DEFAULT 'PENDING' CHECK (KYC_STATUS IN ('PENDING', 'APPROVED', 'REJECTED'))
);

-- Index for quick aadhar lookups
CREATE INDEX idx_aadhar ON Account_opening_form (AADHAR_NUMBER);

-- =============================
-- 3. TABLE: BANK
-- =============================
CREATE TABLE BANK (
    ACCOUNT_NUMBER INT IDENTITY(10000,1) PRIMARY KEY,
    ACCOUNT_TYPE VARCHAR(20),
    ACCOUNT_OPENING_DATE DATE,
    CURRENT_BALANCE DECIMAL(10,2) CHECK (CURRENT_BALANCE >= 0)
);

-- =============================
-- 4. TABLE: ACCOUNT_HOLDER_DETAILS
-- =============================
CREATE TABLE ACCOUNT_HOLDER_DETAILS (
    ACCOUNT_NUMBER INT PRIMARY KEY,
    ACCOUNT_HOLDER_NAME VARCHAR(100) NOT NULL,
    DOB DATE NOT NULL,
    AADHAR_NUMBER VARCHAR(12) UNIQUE NOT NULL,
    MOBILE_NUMBER VARCHAR(15) NOT NULL,
    FOREIGN KEY (ACCOUNT_NUMBER) REFERENCES BANK(ACCOUNT_NUMBER)
);

-- =============================
-- 5. TABLE: TRANSACTION_DETAILS
-- =============================
CREATE TABLE TRANSACTION_DETAILS (
    TRANSACTION_ID INT IDENTITY(1,1) PRIMARY KEY,
    ACCOUNT_NUMBER INT NOT NULL,
    PAYMENT_TYPE VARCHAR(20) CHECK (PAYMENT_TYPE IN ('DEBIT', 'CREDIT')),
    TRANSACTION_AMOUNT DECIMAL(10,2) CHECK (TRANSACTION_AMOUNT > 0),
    DATE_OF_TRANSACTION DATE DEFAULT GETDATE(),
    FOREIGN KEY (ACCOUNT_NUMBER) REFERENCES BANK(ACCOUNT_NUMBER)
);

-- Index for transaction history lookups
CREATE INDEX idx_txn_account_date ON TRANSACTION_DETAILS (ACCOUNT_NUMBER, DATE_OF_TRANSACTION);

-- =============================
-- 6. TRIGGER: Auto-create account upon KYC approval
-- =============================
CREATE TRIGGER TR_FOR_INSERT_INTO_ACC_OPENING_FORM
ON Account_opening_form
AFTER UPDATE
AS
BEGIN
    DECLARE @status VARCHAR(20),
            @Account_type VARCHAR(20),
            @Account_HolderName VARCHAR(100),
            @DOB DATE,
            @AadharNumber VARCHAR(12),
            @MobileNumber VARCHAR(15),
            @Account_opening_balance DECIMAL(10,2);

    SELECT @status = KYC_STATUS, 
           @Account_type = ACCOUNT_TYPE, 
           @Account_HolderName = ACCOUNT_HOLDER_NAME,
           @DOB = DOB, 
           @AadharNumber = AADHAR_NUMBER, 
           @MobileNumber = MOBILE_NUMBER, 
           @Account_opening_balance = ACCOUNT_OPENING_BALANCE
    FROM inserted;

    IF @status = 'APPROVED'
    BEGIN
        -- Insert into BANK
        INSERT INTO BANK (ACCOUNT_TYPE, ACCOUNT_OPENING_DATE, CURRENT_BALANCE)
        VALUES (@Account_type, GETDATE(), @Account_opening_balance);

        -- Insert into ACCOUNT_HOLDER_DETAILS
        INSERT INTO ACCOUNT_HOLDER_DETAILS (ACCOUNT_NUMBER, ACCOUNT_HOLDER_NAME, DOB, AADHAR_NUMBER, MOBILE_NUMBER)
        VALUES (@@IDENTITY, @Account_HolderName, @DOB, @AadharNumber, @MobileNumber);
    END;
END;

-- =============================
-- 7. TRIGGER: Auto-update balance on transaction
-- =============================
CREATE TRIGGER TR_UPDATE_BALANCE
ON TRANSACTION_DETAILS
AFTER INSERT
AS
BEGIN
    DECLARE @AccountNumber INT,
            @TransactionAmount DECIMAL(10,2),
            @PaymentType VARCHAR(20);

    SELECT @AccountNumber = ACCOUNT_NUMBER,
           @TransactionAmount = TRANSACTION_AMOUNT,
           @PaymentType = PAYMENT_TYPE
    FROM inserted;

    -- Prevent overdraft
    IF @PaymentType = 'DEBIT' AND EXISTS (
        SELECT 1 FROM BANK WHERE ACCOUNT_NUMBER = @AccountNumber AND CURRENT_BALANCE < @TransactionAmount
    )
    BEGIN
        RAISERROR('Insufficient funds for this transaction.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF @PaymentType = 'DEBIT'
    BEGIN
        UPDATE BANK
        SET CURRENT_BALANCE = CURRENT_BALANCE - @TransactionAmount
        WHERE ACCOUNT_NUMBER = @AccountNumber;
    END
    ELSE IF @PaymentType = 'CREDIT'
    BEGIN
        UPDATE BANK
        SET CURRENT_BALANCE = CURRENT_BALANCE + @TransactionAmount
        WHERE ACCOUNT_NUMBER = @AccountNumber;
    END;
END;

-- =============================
-- 8. FUNCTION: Get Account Balance
-- =============================
CREATE FUNCTION fn_get_balance (@AccountNumber INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @balance DECIMAL(10,2);
    SELECT @balance = CURRENT_BALANCE FROM BANK WHERE ACCOUNT_NUMBER = @AccountNumber;
    RETURN @balance;
END;

-- =============================
-- 9. PROCEDURE: Monthly Passbook
-- =============================
CREATE PROCEDURE sp_passbook
    @AccountNumber INT,
    @Month INT,
    @Year INT
AS
BEGIN
    SELECT TRANSACTION_ID, PAYMENT_TYPE, TRANSACTION_AMOUNT, DATE_OF_TRANSACTION
    FROM TRANSACTION_DETAILS
    WHERE ACCOUNT_NUMBER = @AccountNumber
      AND MONTH(DATE_OF_TRANSACTION) = @Month
      AND YEAR(DATE_OF_TRANSACTION) = @Year
    ORDER BY DATE_OF_TRANSACTION;
END;

-- =============================
-- 10. SAMPLE DATA INSERTION
-- =============================
INSERT INTO Account_opening_form (ID, ACCOUNT_HOLDER_NAME, DOB, AADHAR_NUMBER, MOBILE_NUMBER, ACCOUNT_OPENING_BALANCE, ADDRESS1)
VALUES (1, 'Gaurav Sharma', '1990-01-01', '123456789012', '9876543210', 1500, 'Mohali');

INSERT INTO Account_opening_form (ID, ACCOUNT_HOLDER_NAME, DOB, AADHAR_NUMBER, MOBILE_NUMBER, ACCOUNT_OPENING_BALANCE, ADDRESS1)
VALUES (2, 'Rahul Mehta', '1985-07-20', '987654321098', '9876543211', 2500, 'Chandigarh');

-- Approve accounts
UPDATE Account_opening_form
SET KYC_STATUS = 'APPROVED'
WHERE ID IN (1, 2);

-- Transactions
INSERT INTO TRANSACTION_DETAILS (ACCOUNT_NUMBER, PAYMENT_TYPE, TRANSACTION_AMOUNT)
VALUES (10000, 'DEBIT', 500);

INSERT INTO TRANSACTION_DETAILS (ACCOUNT_NUMBER, PAYMENT_TYPE, TRANSACTION_AMOUNT)
VALUES (10000, 'CREDIT', 1000), (10001, 'CREDIT', 800);

-- =============================
-- 11. SAMPLE REPORT QUERIES
-- =============================
-- a) Get top 5 accounts by balance
SELECT TOP 5 ACCOUNT_NUMBER, CURRENT_BALANCE
FROM BANK
ORDER BY CURRENT_BALANCE DESC;

-- b) Get total credits and debits per account
SELECT ACCOUNT_NUMBER,
       SUM(CASE WHEN PAYMENT_TYPE = 'CREDIT' THEN TRANSACTION_AMOUNT ELSE 0 END) AS Total_Credit,
       SUM(CASE WHEN PAYMENT_TYPE = 'DEBIT' THEN TRANSACTION_AMOUNT ELSE 0 END) AS Total_Debit
FROM TRANSACTION_DETAILS
GROUP BY ACCOUNT_NUMBER;

-- c) Get account balance using function
SELECT dbo.fn_get_balance(10000) AS Balance_For_Account_10000;
