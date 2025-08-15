# 🏦 Advanced Bank Management System — SQL Server Implementation

## 📌 Overview  
This project is a **fully functional backend banking database system** designed and implemented in **SQL Server** by **Gaurav**.  
It simulates **real-world banking operations** including account creation, KYC verification, and transaction management, while ensuring **data integrity**, **business rule enforcement**, and **performance optimization**.

It demonstrates **advanced SQL concepts**:
- Normalized schema (3NF)
- **Constraints** (CHECK, UNIQUE, FOREIGN KEY)
- **Triggers** for automation
- **Stored Procedures** for reusable business logic
- **Functions** for quick data retrieval
- **Indexes** for query performance
- **Reporting queries** for analytics

---

## 🗂 Database Schema

The system consists of **four core tables** and supporting triggers, procedures, and functions:

### 1️⃣ `Account_opening_form` — Application Table
Stores **new account applications** before KYC verification.  
**Fields:**
- `ID` *(Primary Key)*
- `DATE` *(Default: Current date)*
- `ACCOUNT_TYPE` *(Default: SAVINGS, ENUM: SAVINGS, CURRENT)*
- `ACCOUNT_HOLDER_NAME`
- `DOB`
- `AADHAR_NUMBER` *(Unique, 12 digits)*
- `MOBILE_NUMBER` *(Unique, 15 digits)*
- `ACCOUNT_OPENING_BALANCE` *(Minimum: 1000)*
- `ADDRESS1`
- `KYC_STATUS` *(PENDING / APPROVED / REJECTED)*

---

### 2️⃣ `BANK` — Active Accounts
Stores **all approved bank accounts**.  
**Fields:**
- `ACCOUNT_NUMBER` *(Auto-generated starting from 10000)*
- `ACCOUNT_TYPE`
- `ACCOUNT_OPENING_DATE`
- `CURRENT_BALANCE`

---

### 3️⃣ `ACCOUNT_HOLDER_DETAILS` — Personal Data
Stores **personal details** of account holders for approved accounts.  
**Fields:**
- `ACCOUNT_NUMBER` *(PK & FK to BANK)*
- `ACCOUNT_HOLDER_NAME`
- `DOB`
- `AADHAR_NUMBER` *(Unique)*
- `MOBILE_NUMBER`

---

### 4️⃣ `TRANSACTION_DETAILS` — Ledger
Keeps a record of **all transactions**.  
**Fields:**
- `TRANSACTION_ID` *(PK, Auto Increment)*
- `ACCOUNT_NUMBER` *(FK to BANK)*
- `PAYMENT_TYPE` *(DEBIT / CREDIT)*
- `TRANSACTION_AMOUNT` *(> 0)*
- `DATE_OF_TRANSACTION` *(Default: Current date)*

---

## ⚙️ Automation & Business Logic

### 🔹 Trigger 1 — Auto Account Creation (`TR_FOR_INSERT_INTO_ACC_OPENING_FORM`)
- Fires when **KYC_STATUS** changes to `APPROVED`.
- Automatically:
  - Creates a new **BANK** account.
  - Generates `ACCOUNT_NUMBER` sequentially.
  - Inserts details into **ACCOUNT_HOLDER_DETAILS**.

---

### 🔹 Trigger 2 — Auto Balance Update (`TR_UPDATE_BALANCE`)
- Fires after every transaction.
- Automatically:
  - Updates the `CURRENT_BALANCE`.
  - Prevents **overdrafts** (DEBIT cannot exceed available balance).

---

### 🔹 Function — `fn_get_balance`
- Returns the **current balance** for a given account.
- Useful for quick balance checks.

---

### 🔹 Procedure — `sp_passbook`
- Generates a **monthly passbook statement** for an account.
- Includes date, type, and amount of each transaction.

---

## 💡 Business Rules Implemented
- Minimum opening balance for savings account = **₹1000**.
- Unique **Aadhar** and **Mobile number** for each account holder.
- KYC approval **mandatory** before account creation.
- All transactions are **timestamped**.
- Balance automatically updated with **DEBIT/CREDIT** rules.
- No overdraft allowed unless **overdraft facility** is explicitly implemented.

---

## 🚀 How It Works

### **1. Create a New Application**
```sql
INSERT INTO Account_opening_form 
(ID, ACCOUNT_HOLDER_NAME, DOB, AADHAR_NUMBER, MOBILE_NUMBER, ACCOUNT_OPENING_BALANCE, ADDRESS1)
VALUES 
(1, 'Gaurav', '2003-05-24', '123456789012', '9876543210', 1500, 'Mohali');
