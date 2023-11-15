This repo includes all the SQL queries to extract the data and all the codes (Jupyter notebooks) to build the training data, train the ML model, and evaluate the ML model for the detection of fraudulent Paylinks&Virtual_Terminal (PLVT) transactions.

The fraud detection model is trained based on both transaction_level and merchant_level features.

First we show how to build all the transaction_level features step by step.

For example, here, I will build transaction_level features for all Card_Not_Present (CNP) successful transactions from 2023-01-01 to 2023-07-31.

First, we need to build a driver table, including business_uuid, txn_uuid, tender_id, txn_date for our driver population (in this example all successful CNP transactions from 2023-01-01 to 2023-07-31).
To build a driver table we first run query_1 located in src/queries (in Alation) and save the results as gpv_amnt_2.csv, and then run this cell 

Now, for each txn in our driver table, we need to build gpv features, which are 
Lifetime GPV (amount), Lifetime num. gpv txns (count), 
Last 14 day GPV (amount), Last 14 day num. gpv txns (count),
Last 7 day GPV (amount), Last 7 day num. gpv txns (count),
Last 3 day GPV (amount), Last 3 day num. gpv txns (count),
Last 1 day GPV (amount), Last 1 day num. gpv txns (count)

The gpv features except the lifetime gpv features will be built using this cell

To build lifetime gpv features we first run query_2 located in src/queries (in Alation) and save the results as gpv_lifetime_amnt_num.csv, and then run this cell

Next, we need to build payout features, which are
successful lifetime payouts (count) and successful lifetime payouts (amount)

