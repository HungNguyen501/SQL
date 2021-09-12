with rfm_matrix as (
select "Customer_ID" as customer_id,
	max("Adjusted_Created_At")::date as last_active_date,
	CURRENT_DATE - max("Adjusted_Created_At")::date as recency,
	count(distinct "Sales_ID") as frequency,
	sum("Net_Sales") as monetary
from "Sales"
where "Adjusted_Created_At" >= CURRENT_DATE - interval '1 year`'
group by "Customer_ID"
order by customer_id
),

rfm_percent_rank as (
select 	*,
	percent_rank() over (order by frequency) as frequency_percent_rank,
	percent_rank() over (order by monetary) as monetary_percent_rank

from rfm_matrix
),

rfm_rank as (
select *,
	case 
		when recency between 0 and 100 then 3
		when recency between 101 and 200 then 2
		when recency between 201 and 370 then 1
		else 0
	end as recency_rank,
	case 
		when frequency_percent_rank >= 0.8 then 3
		when frequency_percent_rank < 0.8 and frequency_percent_rank >= 0.5 then 2
		when frequency_percent_rank < 0.5 then 1
	end as frequency_rank,
	case 
		when monetary_percent_rank >= 0.8 then 3
		when monetary_percent_rank < 0.8 and monetary_percent_rank >=0.5 then 2
		when monetary_percent_rank < 0.5 then 1
	end as monetary_rank
from rfm_percent_rank
),

rfm_rank_concat as (
select *,
	concat(recency_rank, frequency_rank, monetary_rank) as rfm_rank
	from rfm_rank
)

SELECT 
    *
    , CASE 
        WHEN recency_rank = 1 THEN '1-Churned'
        WHEN recency_rank = 2 THEN '2-Churning'
        WHEN recency_rank = 3 THEN '3-Active'
        END AS recency_segment
    , CASE 
        WHEN frequency_rank = 1 THEN '1-Least frequent'
        WHEN frequency_rank = 2 THEN '2-Frequent'
        WHEN frequency_rank = 3 THEN '3-Most frequent'
        END as frequency_segment
    , CASE
        WHEN monetary_rank = 1 THEN '1-Least spending'
        WHEN monetary_rank = 2 THEN '2-Normal spending'
        WHEN monetary_rank = 3 THEN '3-Most spending'
        END AS monetary_segment
    , CASE
        WHEN rfm_rank IN ('333', '323') THEN 'VIP'
        WHEN rfm_rank IN ('313') THEN 'VIP, high purchasing'
        WHEN rfm_rank IN ('233', '223') THEN 'VIP but churning/churned'
        WHEN rfm_rank IN ('332', '331') THEN 'Normal'
        END
        AS rfm_segment
FROM rfm_rank_concat
order by customer_id
;

