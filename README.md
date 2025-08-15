# Bank Management System (SQL Server)

A fully functional backend banking system implemented in **SQL Server**, demonstrating the use of **triggers**, **stored procedures**, and **user-defined functions** to handle account creation, KYC verification, and transaction processing.

---

## 📌 Overview
This project simulates core banking operations:
- Account creation with KYC verification
- Transaction handling (credit and debit)
- Automated balance updates
- Transaction history logging
- Relational database design with constraints and automation

---

## 🗄 Database Schema

The system consists of **four main tables**:

### 1. `Account_opening_form`
Stores new account applications before approval.

| Field | Type | Notes |
|-------|------|-------|
| ID | INT (PK) | Unique application ID |
| DATE | DATE | Default: Current Date |
| ACCOUNT_TYPE | VARCHAR | Default: 'SAVINGS' |
| ACCOUNT_HOLDER_NAME | VARCHAR | - |
| DOB | DATE | Date of Birth |
| AADHAR_NUMBER | CHAR(12) | Unique |
| MOBILE_NUMBER | CHAR(15) | Unique |
| ACCOUNT_OPENING_BALANCE | DECIMAL | Minimum: 1000 |
| ADDRESS1 | VARCHAR | - |
| KYC_STATUS | VARCHAR | Default: 'PENDING' |

---

### 2. `BANK`
Stores active, approved bank accounts.

| Field | Type | Notes |
|-------|------|-------|
| ACCOUNT_NUMBER | INT (PK) | Auto-generated, starts from 10000 |
| ACCOUNT_TYPE | VARCHAR | - |
| ACCOUNT_OPENING_DATE | DATE | - |
| CURRENT_BALANCE | DECIMAL | - |

---

### 3. `ACCOUNT_HOLDER_DETAILS`
Stores account holder personal information.

| Field | Type | Notes |
|-------|------|-------|
| ACCOUNT_NUMBER | INT (PK, FK) | Linked to BANK |
| ACCOUNT_HOLDER_NAME | VARCHAR | - |
| DOB | DATE | - |
| AADHAR_NUMBER | CHAR(12) | Unique |
| MOBILE_NUMBER | CHAR(15) | Unique |

---

### 4. `TRANSACTION_DETAILS`
Logs all transactions.

| Field | Type | Notes |
|-------|------|-------|
| ACCOUNT_NUMBER | INT (FK) | Linked to BANK |
| PAYMENT_TYPE | VARCHAR | 'DEBIT' / 'CREDIT' |
| TRANSACTION_AMOUNT | DECIMAL | - |
| DATE_OF_TRANSACTION | DATE | Default: Current Date |

---

## ⚙️ Core Features

### 🔹 Automatic Account Creation
- Trigger: **`TR_FOR_INSERT_INTO_ACC_OPENING_FORM`**
- Executes when KYC is approved.
- Auto-generates account numbers sequentially from **10000**.
- Inserts details into `BANK` and `ACCOUNT_HOLDER_DETAILS`.

### 🔹 Transaction Management
- Trigger: **`TR_UPDATE_BALANCE`**
- Updates balances automatically on `TRANSACTION_DETAILS` insert.
- Supports **DEBIT** and **CREDIT**.
- Maintains a timestamped transaction log.

---

## 🛠 Usage

### 1️⃣ Create a New Account Application
```sql
INSERT INTO Account_opening_form 
(ID, ACCOUNT_HOLDER_NAME, DOB, AADHAR_NUMBER, MOBILE_NUMBER, ACCOUNT_OPENING_BALANCE, ADDRESS1)
VALUES 
(1, 'Gaurav', '1990-01-01', '123456789012', '9876543210', 1500, 'Mohali');
