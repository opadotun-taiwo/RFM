with rfm as (
    select
        distinct wallet_id as customer_id,
        date_diff(current_date(), date(max(transaction_date)), day) as recency,
        count(transaction_id) as frequency,
        sum(amount) as monetary
    from mart.mart_finance_transactions 
    group by customer_id
),

rfm_score as (
    select 
        customer_id,
        recency,
        ntile(5) over(order by recency desc) as recency_score,
        ntile(5) over(order by frequency desc) as frequency_score,
        ntile(5) over(order by monetary desc) as monetary_score
    from rfm
)

select 
    rs.customer_id,
    rs.recency_score, 
    rs.frequency_score, 
    rs.monetary_score,
    case
        when rs.recency_score = 1 and rs.frequency_score = 5 and rs.monetary_score = 5 
            then 'champions'  
        when rs.recency_score = 1 and rs.frequency_score between 4 and 5 and rs.monetary_score between 3 and 5 
            then 'loyal high-value' 
        when rs.recency_score = 1 and rs.frequency_score between 2 and 3 and rs.monetary_score between 3 and 5 
            then 'potential champions'  
        when rs.recency_score between 1 and 2 and rs.frequency_score between 1 and 3 and rs.monetary_score >= 4 
            then 'big spenders'  
        when rs.recency_score between 1 and 2 and rs.frequency_score >= 4 and rs.monetary_score between 1 and 2 
            then 'frequent users'  
        when rs.recency_score between 2 and 3 and rs.frequency_score between 2 and 5 and rs.monetary_score between 2 and 3 
            then 'stable users'  
        when rs.recency_score between 3 and 4 and rs.frequency_score between 3 and 5 and rs.monetary_score between 3 and 5 
            then 'at risk high-value'  
        when rs.recency_score between 3 and 4 and rs.frequency_score between 1 and 2 and rs.monetary_score between 3 and 5 
            then 'slipping high-value'  
        when rs.recency_score >= 4 and rs.frequency_score >= 4 and rs.monetary_score >= 4 
            then 'churning vips'  
        when rs.recency_score >= 4 and rs.frequency_score between 2 and 3 and rs.monetary_score between 2 and 3 
            then 'churning stable users'  
        when rs.recency_score = 1 and rs.frequency_score = 1 and rs.monetary_score = 1 
            then 'new users'  
        when rs.recency_score >= 4 and rs.frequency_score = 1 and rs.monetary_score = 1 
            then 'dormant'  
        when rs.recency_score = 5 and rs.frequency_score = 1 and rs.monetary_score = 1 
            then 'lost'  
        else 'need analysis'  
    end as customer_segment, 
    bd.business_name
from rfm_score rs
--left join mart.mart_merchants bd on rs.customer_id = bd.wallet_id;
