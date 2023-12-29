This repo includes the followings to build an ML model for the detection of fraudulent Paylinks&Virtual_Terminal (PLVT) transactions.
1. [SQL_queries](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql), which consists of 15 SQL queries to extract the required data 
2. [Jupyter Notebook](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/PLVT_fraud_detection_model_notebook.ipynb), which consists of all the python codes to build the training data (features and target variables), train the ML model, and evaluate the model 

# Building features (independent variables):
The fraud detection model is trained based on both transaction_level and merchant_level features.
First we show how to build all the transaction_level features step by step.
## transaction_level features:
Here, we will build transaction_level features for all Card_Not_Present (CNP) successful transactions from 2023-01-01 to 2023-07-31.

First, we build a driver table, including business_uuid, txn_uuid, tender_id, and txn_date for our driver population (i.e., all successful CNP transactions from 2023-01-01 to 2023-07-31).
To build a driver table we first run query_1 located in [query_1](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql) in Alation and save the results as gpv_amnt_2.csv, and then run this Jupytor notebook cell [driver table cell](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/PLVT_fraud_detection_model_notebook.ipynb#driver_table)

Next, for each txn in our driver table, we build gpv features, which are: 
Last 14 day GPV (amount), Last 14 day num. gpv txns (count),
Last 7 day GPV (amount), Last 7 day num. gpv txns (count),
Last 3 day GPV (amount), Last 3 day num. gpv txns (count),
Last 1 day GPV (amount), Last 1 day num. gpv txns (count),
Lifetime GPV (amount), Lifetime num. gpv txns (count)

The gpv features, except for the lifetime gpv features, will be built using this Jupytor notebook cell [gpv features cell](path/to/notebook.ipynb#gpv features)
To build lifetime gpv features we first run query_2 located in [query_2](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql) in Alation and save the results as gpv_lifetime_amnt_num.csv, and then run this Jupytor notebook cell [lifetime_gpv features cell](path/to/https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/PLVT_fraud_detection_model_notebook.ipynb#lifetime_gpv features)

Next, for each txn in our driver table, we build payout features, which are:
successful lifetime payouts (count)
successful lifetime payouts (amount)
To build payout features we first run query_3 located in [query_3](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql) in Alation and save the results as payout.csv, and then run this Jupytor notebook cell [payout features cell](path/to/https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/PLVT_fraud_detection_model_notebook.ipynb#payout features)


Next, for each txn in our driver table, we build chargeback features, which are:
Last 14 day CBK (amount)
Last 14 day num. CBK (count)
Last 7 day CBK (amount)
Last 7 day num. CBK (count)
Last 3 day CBK (amount)
Last 3 day num. CBK (count)
Last 1 day CBK (amount)
Last 1 day num. CBK (count)
To build chargeback features we first run query_4 located in [query_4](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql) in Alation and save the results as chargeback.csv, and then run this Jupytor notebook cell [chargeback features cell](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/PLVT_fraud_detection_model_notebook.ipynb#chargeback features)

Next, for each txn in our driver table, we build decline features, which are
Lifetime declined txns (amount)
Lifetime num. declined txns (count)
Last 14 day declined txn (amount)
Last 14 day declined num. txns (count)
Last 7 day declined txn (amount)
Last 7 day declined num. txns (count)
Last 3 day declined txn (amount)
Last 3 day declined num. txns (count)
Last 1 day declined txn (amount)
Last 1 day declined num. txns (count)
To build decline features we first run query_5 located in [query_5](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql) in Alation and save the results as decline_txns_above5.csv, and then run this Jupytor notebook cell [decline features cell](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/PLVT_fraud_detection_model_notebook.ipynb#decline features)

Next, for each txn in our driver table, we build this feature: 
Time since first transaction attempt (in days) 
first_txn_attempt_date
To build this feature we first run query_6 located in [query_6](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql) in Alation and save the results as first_txn_attempt_date.csv, and then run this Jupytor notebook cell [first_txn_attempt_date cell](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/PLVT_fraud_detection_model_notebook.ipynb#first_txn_attempt_date)

Next, for each txn in our driver table, we build these features: 
Time since account (or business) creation (in days), 
Transaction sub-type (Virtual Terminal (VT), paylink, Ecomm), 
Godaddy_service_type_name (WM_OLS, Woo_Commerce, Standalone, Invoicing), 
Acquisition channel (GD, Poynt direct, partners)
To build these feature we first run query_7 located in [query_7](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql) in Alation and save the results as txn_subtype.csv, and then run this Jupytor notebook cell [txn_subtype cell](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/PLVT_fraud_detection_model_notebook.ipynb#txn_subtype)

Next, for each business in our driver table, we build this feature: 
Merchant website provided (Yes/No)
To build this feature we first run query_8 located in [query_8](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql) in Alation and save the results as business_url.csv, and then run this Jupytor notebook cell [business_url cell](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/PLVT_fraud_detection_model_notebook.ipynb#business_url)

Next, we show how to build all the merchant_level features step by step.
## merchant_level features:
merchant_level features include both GD_payment features and GD_shopper features.

First, for each business, we build these features: 
number of unique bank accounts of the merchanet at the transaction date
is bank_account_routing_num is risky or not 
To build these features we run query_9 located in [query_9](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql) in Alation and save the results as bank_features.csv


Next, to bulid the remaining merchant_level features (including GD_shopper features and GD_payment features), run a master query_10 located in [query_10](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql) in Alation and save the results as merchant_features.csv


# Building target variable (dependent variable):

Now we build the target variable by labeling merchants as fraudulent or not. We first label a merchant, and then all the transactions of the merchant will be labled accordingly. 

First, for each business, we build these features:
total gpv and merchant status (run query_11 located in [query_11](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql) in Alation and save the results as gpv.csv)
total chargeback (run query_12 located in [query_12](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql) in Alation and save the results as CB.csv)
total loss (run query_12 located in [query_12](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql) in Alation and save the results as Loss.csv)
total decline (run query_12 located in [query_12](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql) in Alation and save the results as decline.csv)
closing reason (run query_12 located in [query_12](https://github.com/nhosseinidehaj-godaddy/Fraud_detection_ML_model_for_PLVT_txns/blob/main/src/queries.sql) in Alation and save the results as closing_reason.csv)





















