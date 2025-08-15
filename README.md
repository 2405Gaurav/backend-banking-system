# Bank Management System

A comprehensive backend banking system implemented in SQL Server that demonstrates the use of triggers, stored procedures, and functions for managing bank accounts and transactions.

## Database Schema

The system consists of four main tables:

### 1. Account_opening_form
- Primary table for new account applications
- Fields:
  - `ID` (Primary Key)
  - `DATE` (Default: Current date)
  - `ACCOUNT_TYPE` (Default: 'SAVINGS')
  - `ACCOUNT_HOLDER_NAME`
  - `DOB` (Date of Birth)
  - `AADHAR_NUMBER` (Unique, 12 digits)
  - `MOBILE_NUMBER` (Unique, 15 digits)
  - `ACCOUNT_OPENING_BALANCE` (Minimum: 1000)
  - `ADDRESS1`
  - `KYC_STATUS` (Default: 'PENDING')

### 2. BANK
- Stores active bank accounts
- Fields:
  - `ACCOUNT_NUMBER` (Auto-generated, starts from 10000)
  - `ACCOUNT_TYPE`
  - `ACCOUNT_OPENING_DATE`
  - `CURRENT_BALANCE`

### 3. ACCOUNT_HOLDER_DETAILS
- Stores account holder information
- Fields:
  - `ACCOUNT_NUMBER` (Primary Key)
  - `ACCOUNT_HOLDER_NAME`
  - `DOB`
  - `AADHAR_NUMBER` (Unique)
  - `MOBILE_NUMBER`

### 4. TRANSACTION_DETAILS
- Records all transactions
- Fields:
  - `ACCOUNT_NUMBER` (Foreign Key)
  - `PAYMENT_TYPE`
  - `TRANSACTION_AMOUNT`
  - `DATE_OF_TRANSACTION` (Default: Current date)

## Key Features

### Automatic Account Creation
- Trigger `TR_FOR_INSERT_INTO_ACC_OPENING_FORM` automatically creates bank accounts when KYC status is approved
- Generates account numbers sequentially starting from 10000
- Copies relevant information to BANK and ACCOUNT_HOLDER_DETAILS tables

### Transaction Management
- Trigger `TR_UPDATE_BALANCE` automatically updates account balances on transactions
- Supports both DEBIT and CREDIT transactions
- Maintains transaction history with timestamps

## Usage

1. Create a new account application:
```sql
INSERT INTO Account_opening_form (ID, ACCOUNT_HOLDER_NAME, DOB, AADHAR_NUMBER, MOBILE_NUMBER, ACCOUNT_OPENING_BALANCE, ADDRESS1)
VALUES (1, 'Yash Dhiman', '1990-01-01', '123456789012', '9876543210', 1500, 'Mohali');
```

2. Approve KYC:
```sql
UPDATE Account_opening_form
SET KYC_STATUS = 'APPROVED'
WHERE ID = 1;
```

3. Perform transactions:
```sql
-- Debit transaction
INSERT INTO TRANSACTION_DETAILS (ACCOUNT_NUMBER, PAYMENT_TYPE, TRANSACTION_AMOUNT)
VALUES (10000, 'DEBIT', 500.0);

-- Credit transaction
INSERT INTO TRANSACTION_DETAILS (ACCOUNT_NUMBER, PAYMENT_TYPE, TRANSACTION_AMOUNT)
VALUES (10000, 'CREDIT', 1000.0);
```

## Requirements
- SQL Server Management Studio
- SQL Server 2012 or later

## Setup
1. Create the database:
```sql
create database bankM;
use bankM;
```

2. Execute the provided SQL script to create all tables and triggers

## Notes
- Minimum account opening balance: 1000
- Account numbers are auto-generated starting from 10000
- KYC approval is required before account activation
- All transactions are automatically timestamped
