### sql queries 

### query_1 (driver table)
### Run the following query (in alation and save the result as gpv_amnt_2.csv) to get the driver population:


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
date(txn1.create_utc_ts)>='2022-12-14' -- this date should be 15 days before the start date of the diver population
and (txn1.create_utc_ts)<'2023-08-01' -- this date should be the end date of the driver population
and txn1.isgpv = true -- successful txn
and txn1.type_desc = 'MERCHANT'
and txn1.acquirer_code = '%'
and txn1.customer_presence_status_desc!='Present' -- if you only want to consider for CNP txns
and snap_date >= (current_date -1)

-- in order to scan less data you can only do it for the businesses in the driver population
and txn1.business_uuid in (select business_uuid
from bi.dna_approved.transactions
where
date(create_utc_ts)>='2023-01-01' and date(create_utc_ts)<'2023-08-01' -- time period of the driver population
and isgpv = true
and type_desc = 'MERCHANT'
and acquirer_code = '%'
and txn1.customer_presence_status_desc!='Present' -- if you only want to consider for CNP txns
)  

----------------------------------------------------------------------------------------------------------------------------

### query_2 (lifetime_gpv features)
### Run the following query (in alation and save the result as gpv_lifetime_amnt_num.csv) to get the lifetime gpv for each transaction in the driver population:


-- driver table
with driver as (
select txn1.business_uuid, txn1.tender_id, txn1.create_utc_ts as txn_date
from bi.dna_approved.transactions txn1
where
date(create_utc_ts)>='2023-01-01' and date(create_utc_ts)<'2023-08-01' -- time period of the driver population
and txn1.isgpv = true
and txn1.type_desc = 'MERCHANT'
and txn1.acquirer_code = '%'
and txn1.customer_presence_status_desc!='Present' -- if you only want to consider for CNP txns
and txn1.snap_date >= (current_date -1)
)


select business_uuid, tender_id , txn_date, lifetime_gpv_amnt,  lifetime_gpv_count from 
(select txn1.business_uuid, txn1.tender_id , txn1.create_utc_ts as txn_date, txn1.order_total_amt_usd as txn_amnt,

sum(txn_amnt) over (partition by business_uuid ORDER BY txn_date ASC
    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as lifetime_gpv_amnt,
    
count(tender_id) over (partition by business_uuid ORDER BY txn_date ASC
    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as lifetime_gpv_count    

from bi.dna_approved.transactions txn1

where
txn1.isgpv = true
and txn1.type_desc = 'MERCHANT'
and txn1.acquirer_code = '%'

-- in order to scan less data you can only do it for the businesses in the driver population
and txn1.business_uuid in (select business_uuid 
from bi.dna_approved.transactions 
where
date(create_utc_ts)>='2023-01-01' and date(create_utc_ts)<'2023-08-01' -- the driver population
and isgpv = true
and type_desc = 'MERCHANT'
and acquirer_code = '%'
and customer_presence_status_desc!='Present' -- if you only want to consider for CNP txns
) 
and snap_date >= (current_date -1)
)
gpv_txn_lifetime where tender_id in (select distinct tender_id from driver)

----------------------------------------------------------------------------------------------------------------------------

### query_3 (payout features)
### Run the following query (in alation and save the result as payout.csv) to get all the payouts for the businesses in the driver population:


select ao.business_uuid, p.payout_uuid, p.create_utc_ts as payout_date, p.payout_amt_minor*0.01 as payout_amnt
from bi.poynt_spectrum.payout_cln as p
join 
(select owner_uuid as business_uuid, account_uuid from bi.poynt_spectrum.account_organization_cln
where snap_date=(select max(snap_date) from bi.poynt_spectrum.account_organization_cln)
and owner_type='BUSINESS') as ao 
on ao.account_uuid=p.account_uuid

where p.transfer_status = 'SUBMITTED' -- indicate it is successful
and p.account_uuid<>'urn:acc:poynt'
and p.snap_date = (select max(snap_date) from bi.poynt_spectrum.payout_cln)
and p.payout_amt_minor>0

-- in order to scan less data you can only do it for the businesses in the driver population
and ao.business_uuid in (select business_uuid 
from bi.dna_approved.transactions 
where
date(create_utc_ts)>='2023-01-01' and date(create_utc_ts)<'2023-08-01' -- the driver population
and isgpv = true
and type_desc = 'MERCHANT'
and acquirer_code = '%'
and customer_presence_status_desc!='Present' -- if you only want to consider for CNP txns 
)

----------------------------------------------------------------------------------------------------------------------------

### query_4 (chargeback features)
### Run the following query (in alation and save the result as chargeback.csv) to get the last 14day chargebacks for the businesses in the driver population:


select *
from (select d.*
        from (
          select 
          business_uuid, 
          chargeback_uuid,
          casemgmt_chargeback_amt_minor * -0.01 as CB_amnt,
          casemgmt_chargeback_utc_ts as CB_date,
          row_number () over (partition by chargeback_uuid order by update_utc_ts desc) as rows
          from bi.poynt_spectrum.casemgmt_chargeback_cln
          where casemgmt_chargeback_utc_ts >='2022-12-14' -- this date should be 15 days before the start date of the diver population 
          and snap_date >= current_date - 1
          and charge_type_desc = 'CHARGEBACKS'
          ) d where rows=1 ) a


----------------------------------------------------------------------------------------------------------------------------

### query_5 (decline features)
Run the following query (in alation and save the result as decline_txns_above5.csv) to get all the declined transactions for the businesses in the driver population:

select txn1.business_uuid, txn1.tender_id, txn1.create_utc_ts as decline_date, txn1.order_total_amt_usd as decline_amnt
from bi.dna_approved.transactions txn1
where
txn1.action_code IN ('A', 'S') --  -- only focus on auth or sale txn
and txn1.processor_status!='Successful' -- where the processor declined it
and txn1.order_total_amt_usd > 5 -- avoid test merchants
and txn1.type_desc = 'MERCHANT'
and txn1.acquirer_code = '%'

-- in order to scan less data you can only do it for the businesses in the driver population
and txn1.business_uuid in (select business_uuid 
from bi.dna_approved.transactions 
where
date(create_utc_ts)>='2023-01-01' and date(create_utc_ts)<'2023-08-01' -- the driver population
and isgpv = true
and type_desc = 'MERCHANT'
and acquirer_code = '%'
and customer_presence_status_desc!='Present' -- if you only want to consider for CNP txns 
)

----------------------------------------------------------------------------------------------------------------------------

### query_6 (time since first transaction attempt in days)
### Run the following query (in alation and save the result as first_txn_attempt_date.csv) to get the first transaction attemp date for the businesses in the driver population:


select txn1.business_uuid, min(txn1.create_utc_ts) as first_txn_date
from bi.dna_approved.transactions txn1
where
(
((txn1.action_code IN ('A', 'S')) --  -- only focus on auth or sale txn
and (txn1.processor_status!='Successful') -- where the processor declined it
and (txn1.order_total_amt_usd > 5)) -- to avoid test merchants
or
((txn1.isgpv=True) and (txn1.order_total_amt_usd > 5))
)
and txn1.type_desc = 'MERCHANT'
and txn1.acquirer_code = '%' 

-- in order to scan less data you can only do it for the businesses in the driver population
and txn1.business_uuid in (select business_uuid 
from bi.dna_approved.transactions 
where
date(create_utc_ts)>='2023-01-01' and date(create_utc_ts)<'2023-08-01' -- the driver population
and isgpv = true
and type_desc = 'MERCHANT'
and acquirer_code = '%'
and customer_presence_status_desc!='Present' -- if you only want to consider for CNP txns
) 
group by 1;

----------------------------------------------------------------------------------------------------------------------------

### query_7 
### Run the following query (in alation and save the result as txn_subtype.csv) to get txn_subtype, business_create_date, source_package_name, godaddy_service_type_name, and channel for the transactions in the driver population:


select txn1.business_uuid, txn1.tender_id, txn1.create_utc_ts as txn_date, customer_presence_status_desc as txn_subtype, txn1.business_create_date,

txn1.source_package_name, 
case when txn1.source_package_name in ( 'co.poynt.checkout', 'com.godaddy.payabledomain') then 'Online Paylinks'
     when txn1.source_package_name in ('co.poynt.manualentry', 'co.poynt.manual', 'co.poynt.terminal', 'co.poynt.register',
  'com.spoton.poynt.android','com.ethor.poynt', 'com.talech.androidclient', 'co.poynt.posconnector','com.ethor.connect2pos',
  'br.com.userede.redeflex','com.usecopper.connect','co.poynt.lodging','com.shopfastretail.app','com.mindbodyonline.express.poynt',
  'nz.co.vista.serve', 'com.preferredmerchantservices.cashdiscount','com.usecopper.cashier','com.ehopper.pos',
  'com.lcg.paymentlockplus_poynt', 'com.sdgsystems.paymentbridge.moolah', 'com.tei.teipt.payment','com.ehopper.pos.mp',
  'com.ehopper.pos.dev','com.chk.lazeez', 'com.netelement.aptitompos', 'com.chk.foodie',
  'com.northernpos.orderonthegopos', 'com.chk.souk', 'us.softpoint.datapoint','com.touchsuite.lightning.registerpoynt',
  'com.dinamikos.pos_n_go.pnt', 'com.fct.ezpad', 'com.micamp.wavitauto', 'com.wps.terminalapp', 'co.poynt.sample',
  'com.eatos.handheld', 'com.nexgen.tablegame', 'com.signapay.cashdiscount', 'cloud.econduit.poynt2',
  'com.wavit.prod', 'co.poynt.transactionprofiler', 'com.unifiedpayments.giftcards','AlphaPay',  'com.poynt.hq.android') then 'In person'
    when txn1.source_package_name = 'co.poynt.virtualterminal' then 'Virtual Terminal'
    when txn1.source_package_name in ('PosKit iOS','com.godaddy.poskit','com.godaddy.phoenix.payments', 'com.godaday.phoenix.payments',
                                  'commerce.mobile', 'com.godaddy.goapp','com.godaddy.gx.go', 'com.godaddy.polaris') then 'Mobile'
    when txn1.source_package_name = 'co.poynt.invoicing' then 'Invoicing'
    when txn1.source_package_name in ('Godaddy Payment mwp_woo', 'mwp.godaddy-payments', 'mwcs.godaddy-payments') OR txn1.source_package_name like '%WooCommerce%' then 'WooCommerce'
    when txn1.source_package_name in ('gopay.client.int.godaddy.com', 'commerce.onlinestore', 'Godaddy Payment ols') then 'OLS' 
    when txn1.source_package_name = 'wam.paybutton' then 'PayButton'

    else 'Others' end as spn,

txn1.godaddy_service_type_name,
case when txn1.godaddy_service_type_name like '%gopay.client.int.godaddy.com%' then 1 else 0 end as WM_OLS,
case when txn1.godaddy_service_type_name like '%mwp.godaddy-payments%' then 1 else 0 end as Woo_Commerce,
case when ((txn1.godaddy_service_type_name is null) or (godaddy_service_type_name like '%com.sa%'))  then 1 else 0 end as Standalone,
case when (txn1.godaddy_service_type_name like '%hub.godaddy.com%' and txn1.organization_uuid = '5c0b8961-9b40-409d-8f1a-3aa7dc87a624') then 1 else 0 end as Invoicing,


txn1.organization_uuid,   
case when txn1.organization_uuid in ('684a99e3-16d1-4c65-99e4-3588211e97bf', '69c468c3-9ad0-11e4-97fd-0253f1cff731') then 'Poynt_direct'
                      when txn1.organization_uuid in ('5c0b8961-9b40-409d-8f1a-3aa7dc87a624') then 'Godaddy_payments'
                      when txn1.organization_uuid in ( 'a7c3024a-24b9-4b5f-bff7-03aa96f5a25c', '330981ae-f29b-4d9d-8bd0-7b2de7ca6044') then 'Moolah'
                      when txn1.organization_uuid in ( '10ace788-5137-4364-af36-2b041fa1348b') then 'MidPay'
                      when txn1.organization_uuid in ( '932875c0-43a0-4f49-a700-7660c5fca1b4') then 'OrbisPayments'
                      else 'Small_Partners' end as channel,

txn1.merchant_category_code as MCC

from bi.dna_approved.transactions txn1
where
date(txn1.create_utc_ts)>='2023-01-01' and date(txn1.create_utc_ts)<'2023-08-01' -- the driver population
and txn1.isgpv = true
and txn1.type_desc = 'MERCHANT'
and txn1.acquirer_code = '%' 
and txn1.customer_presence_status_desc!='Present' -- if you only want to consider for CNP txns
and snap_date >= (current_date -1)

----------------------------------------------------------------------------------------------------------------------------

### query_8 (business_url)
### Run the following query (in alation and save the result as business_url.csv) to get business_url for the businesses in the driver population:


select business_uuid, business_url
from bi.poynt_spectrum.business_cln
where snap_date >= (current_date -1)

-- in order to scan less data you can only do it for the businesses in the driver population
and business_uuid in (select business_uuid 
from bi.dna_approved.transactions 
where
date(create_utc_ts)>='2023-01-01' and date(create_utc_ts)<'2023-08-01' -- the driver population
and isgpv = true
and type_desc = 'MERCHANT'
and acquirer_code = '%'
and customer_presence_status_desc!='Present' -- if you only want to consider for CNP txns
)

----------------------------------------------------------------------------------------------------------------------------

### query_9 (bank account features) 
### Run the following query (in alation and save the result as bank_features.csv) to get bank account related for all the businesses:


select business_uuid_2 as business_uuid, bank_account_routing_num, bank_account_name, bank_name, bank_account_country, src_create_utc_ts, bank_account_fingerprint
from bi.poynt_spectrum.payfac_bank_account_cln 
join 
(select owner_uuid as business_uuid_2, account_uuid from bi.poynt_spectrum.account_organization_cln
where snap_date=(select max(snap_date) from bi.poynt_spectrum.account_organization_cln)
and owner_type='BUSINESS') as ao 
on bi.poynt_spectrum.payfac_bank_account_cln.bank_account_owner_uuid=ao.account_uuid
WHERE snap_date=(select max(snap_date) from bi.poynt_spectrum.payfac_bank_account_cln)

----------------------------------------------------------------------------------------------------------------------------

### query_10 (master query for GD_shopper features and GD_payment features)
### Run the following master query (in alation and save the result as merchant_features.csv) to get the GD_shopper features and GD_payment features for all the businesses:


-- queries to get GD shopper features
-- query for shopper information
drop table if exists gd1_temp;
create temp table gd1_temp as

select distinct shopper_id, 
shopper_status, acq_report_region_2_name, acq_domestic_international_ind, total_gcr_usd_amt, hvc_customer_tier, domain_portfolio_qty, active_product_cnt, crm_portfolio_type_name, active_venture_count, acq_fraud_flag,
case when shopper_id in (select distinct shopper_id
                             from bi.ba_commerce.cohort_combine_final) then 'identifed_PS' else 'not_identifed_PS' end as Identified_PS_flg,
case when shopper_id  in (select distinct shopper_id from bi.dna_approved.uds_order
                            where pf_id in(1339765,1339759, 1339761)
                            and exclude_reason_desc is null
                            and order_fraud_flag = False
                            and LENGTH(shopper_id) > 3) then 'Hardware Purchased' else 'NA' end as Hardware_flg,
                            
                            
case when shopper_id in (select distinct shopper_id from bi.ba_commerce.final_campaign_table) then 'Sales' else 'Organic' end as PS_Channel,

datediff(year, acq_bill_mst_date, current_date) as tenure_with_GD,
case when product_ownership_name_list like '%Domain%' then 1 else 0 end as Domain_flg,
case when product_ownership_name_list like '%SSL%' then 1 else 0 end as SSL_flg,
case when product_ownership_name_list like '%Hosting%' then 1 else 0 end as Hosting_flg,
case when product_ownership_name_list like '%Email%' then 1 else 0 end as Email_flg,
case when product_ownership_name_list like '%MS%' then 1 else 0 end as MS_flg,
case when product_ownership_name_list like '%Website%' then 1 else 0 end as Website_flg,
case when product_ownership_name_list like '%DNS%' then 1 else 0 end as DNS_flg
from bi.dna_approved.shopper_360_current
;


-- query for wam tier
drop table if exists gd2_temp;
create temp table gd2_temp as

with temp as (
select distinct shopper_id,
case when conversion_order_product_pnl_subline_name in ('Premium', 'Tier 1 Premium') then 'Premium'
     when conversion_order_product_pnl_subline_name in ('Super Premium', 'PayPal Commerce', 'Commerce') then 'Commerce'
     when conversion_order_product_pnl_subline_name in ('Commerce Plus') then 'Commerce Plus'
     when conversion_order_product_pnl_subline_name in ('Economy') then 'Basic'
     when conversion_order_product_pnl_subline_name in ('Deluxe') then 'Standard'
     when conversion_order_product_pnl_subline_name in ('Starter') then 'Starter'
     when conversion_order_product_pnl_subline_name in ('GoCentral Marketing', 'GoCentral SEO') then 'Marketing'
     else 'Others' end as WAM_tiers
from dna_approved.gocentral_websitebuilder_session_tbl)
select distinct shopper_id,
case when shopper_id in (select shopper_id from temp where WAM_tiers='Premium') then 1 else 0 end as WAM_tiers_Premium,
case when shopper_id in (select shopper_id from temp where WAM_tiers='Commerce') then 1 else 0 end as WAM_tiers_Commerce,
case when shopper_id in (select shopper_id from temp where WAM_tiers='Commerce Plus') then 1 else 0 end as WAM_tiers_Commerce_Plus,
case when shopper_id in (select shopper_id from temp where WAM_tiers='Basic') then 1 else 0 end as WAM_tiers_Basic,
case when shopper_id in (select shopper_id from temp where WAM_tiers='Standard') then 1 else 0 end as WAM_tiers_Standard,
case when shopper_id in (select shopper_id from temp where WAM_tiers='Starter') then 1 else 0 end as WAM_tiers_Starter,
case when shopper_id in (select shopper_id from temp where WAM_tiers='Marketing') then 1 else 0 end as WAM_tiers_Marketing,
case when shopper_id in (select shopper_id from temp where WAM_tiers='Others') then 1 else 0 end as WAM_tiers_Others
from temp
;


-- query for website
drop table if exists gd3_temp;
create temp table gd3_temp as

select *,
case when (website=0 and orders>0) then 'more than 100%'
when (website>0 and cast(orders as float)/cast(website as float)>1) then 'more than 100%'
when (website>0 and cast(orders as float)/cast(website as float)>=0.75 and cast(orders as float)/cast(website as float)<1) then '75%to100%'
when (website>0 and cast(orders as float)/cast(website as float)>=0.5 and cast(orders as float)/cast(website as float)<0.75) then '50%to75%'
when (website>0 and cast(orders as float)/cast(website as float)>=0.25 and cast(orders as float)/cast(website as float)<0.50) then '25%to50%'
when (website>0 and cast(orders as float)/cast(website as float)>0 and cast(orders as float)/cast(website as float)<0.25) then 'less then 25%'
else '0'
end as order_website_ratio
from bi.ba_commerce.shopper_website
;


-- query for gmv
drop table if exists gd4_temp;
create temp table gd4_temp as

select distinct shopper_id,
listagg(distinct payment_type_name, ', ') within group (order by payment_type_name) as payment_type_names

from bi.dna_approved.gocentral_ecommerce_orders
where product = 'VNEXT'
group by 1;


drop table if exists gd6_temp;
create temp table gd6_temp as

select distinct shopper_id,
count(distinct domain_name) as domain_cnt,
count(distinct order_number) as total_order,
sum(gmv_in_usd) as GMV_lifetime
from bi.dna_approved.gocentral_ecommerce_orders
where product = 'VNEXT'
group by 1;


-- query for vgroup
drop table if exists gd5_temp;
create temp table gd5_temp as

select distinct shopper_id, 
listagg(distinct vertical, ', ') within group (order by vertical) as vertical
from bi.gmode_spectrum.wam_allvnext_afv1
group by 1
;


drop table if exists gd7_temp;
create temp table gd7_temp as

select distinct shopper_id, 
listagg(distinct vgroup, ', ') within group (order by vgroup) as vgroup
from bi.gmode_spectrum.wam_allvnext_afv1
group by 1
;

-----------------------------------

-- query for hardware
drop table if exists gd8_temp;
create temp table gd8_temp as

select distinct shopper_id, 
listagg(distinct pf_id, ', ') within group (order by pf_id) as pf_id
from bi.dna_approved.uds_order
where 
exclude_reason_desc is null
and order_fraud_flag = False
and LENGTH(shopper_id) > 3
group by 1
;

-----------------------------------


-- Application Variable
drop table if exists av_temp;
create temp table av_temp as

with temp as (
select application_id, 
max(email_age_score) as email_age_score,
max(email_address_advice) as email_address_advice,
max(ip_risk_level) as ip_risk_level,
max(ip_reputation) as ip_reputation,
max(business_verification_score) as business_verification_score,
max(identity_verification_score) as identity_verification_score,
max(business_applicant_link_score) as business_applicant_link_score,
max(additional_variable_key_value) as businessLegalEntityType,
max(lexnex_identity_response_risk_code) as lexnex_identity_response_risk_code,
max(lexnex_business_identity_response_risk_code) as lexnex_business_identity_response_risk_code,
max(cognito_name_similarity_score) as cognito_name_similarity_score,
max(primary_phone_type) as primary_phone_type,
max(primary_phone_status) as primary_phone_status,
max(primary_phone_risk_indicator_status) as primary_phone_risk_indicator_status,
max(persona_final_result) as persona_final_result,
max(behavior_threat_level) as behavior_threat_level,
max(completion_time_seconds) as completion_time_seconds,
max(distraction_event_score) as distraction_event_score,
max(hesitation_percentage_score) as hesitation_percentage_score,
max(ip_threat_level) as ip_threat_level,
max(anonymous_indicator_list) as anonymous_indicator_list,
max(proxy_indicator_list) as proxy_indicator_list,
max(device_type) as device_type,
max(region_code) as region_code
from bi.poynt_spectrum.application_variable_safe_cln 
where snap_utc_date=(select max(snap_utc_date) from bi.poynt_spectrum.application_variable_safe_cln)
group by 1)
select temp.*, t1.domain_existence_flag, t2.ip_anonymous_detection_flag from temp
left join (select application_id, domain_existence_flag from bi.poynt_spectrum.application_variable_safe_cln where domain_existence_flag is not null and snap_utc_date=(select max(snap_utc_date) from bi.poynt_spectrum.application_variable_safe_cln)) as t1 on t1.application_id=temp.application_id
left join (select application_id, ip_anonymous_detection_flag from bi.poynt_spectrum.application_variable_safe_cln where ip_anonymous_detection_flag is not null and snap_utc_date=(select max(snap_utc_date) from bi.poynt_spectrum.application_variable_safe_cln)) as t2 on t2.application_id=temp.application_id
;

-----------------------------------

--- App info
drop table if exists app_temp;
create temp table app_temp as

select pa.*, a.casemgmt_application_id, a.channel_type, a.mock_process_flag, a.decision_status_desc, a.processing_status_desc, a.workflow_status_desc, a.user_assignee_uuid, a.risk_declined_reason, a.step_up_action, a.application_intent, a.create_utc_ts as app_create_time 
from bi.poynt_spectrum.casemgmt_application_cln as a
left join (
select SUBSTRING(application_uuid,9) as application_uuid, godaddy_shopper_id, organization_uuid, original_application_level, full_application_status, first_transaction_utc_ts, referral_url_id
from bi.poynt_spectrum.payfac_application_cln
where original_intent='CREATE_BUSINESS'
and snap_date=(select max(snap_date) from bi.poynt_spectrum.payfac_application_cln)
) as pa on pa.application_uuid=a.application_uuid

where
a.decision_status_desc != 'PENDING'
and a.application_intent='CREATE_BUSINESS'
and a.application_level='FULL'
and a.snap_date=(select max(snap_date) from bi.poynt_spectrum.casemgmt_application_cln)
;


-----------------------------------


drop table if exists final_app_master;
create temp table final_app_master as

select app_temp.application_uuid,
gd1_temp.*,
gd2_temp.WAM_tiers_Premium, gd2_temp.WAM_tiers_Commerce, gd2_temp.WAM_tiers_Commerce_plus, gd2_temp.WAM_tiers_Basic, gd2_temp.WAM_tiers_Standard, gd2_temp.WAM_tiers_Starter, gd2_temp.WAM_tiers_Marketing, gd2_temp.WAM_tiers_Others,
gd3_temp.website, gd3_temp.orders, gd3_temp.sales, gd3_temp.order_website_ratio, 
gd4_temp.payment_type_names, 
gd5_temp.vertical, 
gd6_temp.domain_cnt, gd6_temp.total_order, gd6_temp.GMV_lifetime,
gd7_temp.vgroup,

gd8_temp.pf_id,

av_temp.*
from app_temp

left join gd1_temp on gd1_temp.shopper_id=app_temp.godaddy_shopper_id
left join gd2_temp on gd2_temp.shopper_id=app_temp.godaddy_shopper_id
left join gd3_temp on gd3_temp.shopper_id=app_temp.godaddy_shopper_id
left join gd4_temp on gd4_temp.shopper_id=app_temp.godaddy_shopper_id
left join gd5_temp on gd5_temp.shopper_id=app_temp.godaddy_shopper_id
left join gd6_temp on gd6_temp.shopper_id=app_temp.godaddy_shopper_id
left join gd7_temp on gd7_temp.shopper_id=app_temp.godaddy_shopper_id

left join gd8_temp on gd8_temp.shopper_id=app_temp.godaddy_shopper_id

left join av_temp on av_temp.application_id=app_temp.casemgmt_application_id
;


select * from final_app_master;

;




----------------------------------------------------------------------------------------------------------------------------

### query_11 (merchant_labeling, gpv) 
### Run the following query (in alation and save the result as gpv.csv) to get total gpv and merchant status for all the businesses:

select business_uuid, sum(order_total_amt_usd) as total_gpv, count(tender_id) as total_num_gpv_trxs,
case when business_uuid in (select business_uuid  
                                         from poynt_spectrum.business_cln 
                                         where  payment_attr like '%enablePayment=0%' 
                                         and snap_date >= (current_date -1 )) then 'Merchant Terminated' else 'Merchant Active'  end as merchant_status
from bi.dna_approved.transactions
where
date(create_utc_ts)>='2022-04-01'
and isgpv = true
and type_desc = 'MERCHANT'
and acquirer_code = '%'
group by 1, 4;


----------------------------------------------------------------------------------------------------------------------------


### query_12 (merchant_labeling, chargeback) 
### Run the following query (in alation and save the result as CB.csv) to get total chargeback for all the businesses:


select a.business_uuid,
       sum(a.CB_AMNT) as CB_total,
       count(distinct a.chargeback_uuid) as CB_num_total
from (select d.*
        from (
          select business_uuid, 
          chargeback_uuid,
          casemgmt_chargeback_amt_minor * -0.01 as CB_AMNT,
          row_number () over (partition by chargeback_uuid order by update_utc_ts desc) as rows
          from bi.poynt_spectrum.casemgmt_chargeback_cln
          where casemgmt_chargeback_utc_ts >= '2022-04-01'
          and  original_transaction_utc_ts >='2022-04-01' 
          and charge_type_desc = 'CHARGEBACKS') d where rows =1 ) a
left join (select e.* 
           from (select  ref_uuid as trn_id,
                          transfer_status, 
                          payout_amt_minor*0.01 as amnt, 
                          row_number () over (partition by trn_id order by payout_amt_minor) as rows_1 , 
                          parent_uuid,
                          date (f.cln_update_utc_ts ) as debit_attempt_date
                          from bi.poynt.ledger_cln f
                          join  bi.poynt.payout_cln  g
                          on f.payout_uuid = g.payout_uuid
                          where f.ledger_type_name = 'CHARGEBACK_INIT'
                          and f.account_uuid <> 'urn:acc:poynt'
                          order by f.snap_date DESC) e
            where e.rows_1 = 1) c
on a.chargeback_uuid = c.parent_uuid
group by 1;


----------------------------------------------------------------------------------------------------------------------------


### query_13 (merchant_labeling, loss) 
### Run the following query (in alation and save the result as Loss.csv) to get total loss for all the businesses:


select a.business_uuid,
case when (c.transfer_status ='SUBMITTED' or c.transfer_status is NULL) then 'Not Loss' else 'Loss' end as LOSS_STAT,
       sum(a.CB_AMNT) as CB_total,
       count(distinct a.chargeback_uuid) as CB_num_total
from (select d.*
        from (
          select business_uuid, 
          chargeback_uuid,
          casemgmt_chargeback_amt_minor * -0.01 as CB_AMNT,
          row_number () over (partition by chargeback_uuid order by update_utc_ts desc) as rows
          from bi.poynt_spectrum.casemgmt_chargeback_cln
          where casemgmt_chargeback_utc_ts >= '2022-04-01'
          and  original_transaction_utc_ts >='2022-04-01' 
          and charge_type_desc = 'CHARGEBACKS') d where rows =1 ) a
left join (select e.* 
           from (select  ref_uuid as trn_id,
                          transfer_status, 
                          payout_amt_minor*0.01 as amnt, 
                          row_number () over (partition by trn_id order by payout_amt_minor) as rows_1 , 
                          parent_uuid,
                          date (f.cln_update_utc_ts ) as debit_attempt_date
                          from bi.poynt.ledger_cln f
                          join  bi.poynt.payout_cln  g
                          on f.payout_uuid = g.payout_uuid
                          where f.ledger_type_name = 'CHARGEBACK_INIT'
                          and f.account_uuid <> 'urn:acc:poynt'
                          order by f.snap_date DESC) e
            where e.rows_1 = 1) c
on a.chargeback_uuid = c.parent_uuid
group by 1, 2;


----------------------------------------------------------------------------------------------------------------------------


### query_14 (merchant_labeling, decline) 
### Run the following query (in alation and save the result as decline.csv) to get total decline for all the businesses:

select business_uuid, sum(order_total_amt_usd) as total_decline, count(tender_id) as total_num_decline_trxs
from bi.dna_approved.transactions txn1
where
date(create_utc_ts)>='2022-04-01'
and txn1.action_code IN ('A', 'S') --  -- only focus on auth or sale txn
and txn1.processor_status!='Successful' -- where the processor declined it
and txn1.type_desc = 'MERCHANT'
and txn1.acquirer_code = '%'
group by 1;


----------------------------------------------------------------------------------------------------------------------------


### query_15 (merchant_labeling, closing reason) 
### Run the following query (in alation and save the result as closing_reason.csv) to get closing_reason for all the businesses:


select business_uuid, closing_reason, closing_details
from bi.poynt_spectrum.business_cln
where 
business_uuid in (select business_uuid 
from bi.dna_approved.transactions 
where
date(create_utc_ts)>='2022-04-01' 
and isgpv = true
and type_desc = 'MERCHANT'
and acquirer_code = '%') -- for biz in the driver table
and snap_date >= (current_date -1)


























