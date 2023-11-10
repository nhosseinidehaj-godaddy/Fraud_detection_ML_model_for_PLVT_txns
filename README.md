This repo includes all the SQL queries to extract the data and all the codes (Jupyter notebooks) to build the training data, train the ML model, and evaluate the ML model for the detection of fraudulent Paylinks&Virtual_Terminal (PLVT) transactions.

The fraud detection model is trained based on both transaction_level and merchant_level features.

First we show how to build all the transaction_level features step by step.

For example, here, I will build transaction_level features for all Card_Not_Present (CNP) successful transactions from 2023-01-01 to 2023-07-31.

First, we need to build a driver table, including business_uuid, txn_uuid, tender_id, txn_date for our driver population (in this example all successful CNP transactions from 2023-01-01 to 2023-07-31).
To build a driver table we need to run query_1 located in src/queries in Alation and save the results as gpv_amnt_2. 
