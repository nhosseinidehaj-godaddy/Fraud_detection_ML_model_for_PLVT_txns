### sql queries 

### query_1
### Run the following query (in alation and save the result as gpv_amnt_2.csv):


select txn1.business_uuid, txn0.tender_uuid as txn_uuid, txn1.tender_id, txn1.create_utc_ts as txn_date, txn1.order_total_amt_usd as txn_amnt
from bi.dna_approved.transactions txn1

-- in case you need txn_uuid in addition to tender_id
join (select tb.tender_uuid,
             tb.tender_base_id
     FROM bi.poynt_spectrum.tender_base_cln  tb
      where
      tb.snap_date = (SELECT MAX(snap_date) FROM bi.poynt_spectrum.tender_base_cln where region = 'US')
     AND
      tb.region = 'US'
      and tb.parent_id is null ) as txn0
on txn0.tender_base_id = txn1.tender_id

where
date(txn1.create_utc_ts)>='2023-07-14' -- this date should be 15 days before the start date of the diver population
and txn1.isgpv = true
and txn1.type_desc = 'MERCHANT'
and txn1.acquirer_code = '%'

and txn1.business_uuid in (select business_uuid
from bi.dna_approved.transactions
where
date(create_utc_ts)>='2023-08-01' and date(create_utc_ts)<'2023-11-01' -- time period of the driver population
and isgpv = true
and type_desc = 'MERCHANT'
and acquirer_code = '%') -- for businesses in the driver population
