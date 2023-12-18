WITH cte_member AS (
	SELECT
		member_id,
		first_name
	FROM trading.members
	WHERE first_name IN ('Vikram')
),

bull_strategy AS (
	SELECT
		m.first_name,
		t.ticker,
		SUM(t.quantity) as quantity,
		SUM(t.quantity*p.price) as investment,
		SUM(t.percentage_fee*p.price/100) as fee,
		SUM(t.quantity*_final.price) as final_value
	FROM trading.transactions t
	INNER JOIN cte_member m
		ON t.member_id = m.member_id
	INNER JOIN trading.prices p
		ON t.ticker = p.ticker
		AND t.txn_date = p.market_date
	INNER JOIN trading.prices _final
		ON t.ticker = _final.ticker
		AND _final.market_date = '2021-08-29'
	WHERE txn_type = 'BUY'
	GROUP BY m.first_name, t.ticker
)

SELECT
-- *
	first_name,
	ticker,
	ROUND(SUM(investment)::NUMERIC, 2) as investment,
	ROUND(SUM(fee)::NUMERIC, 2) as fee,
	ROUND(SUM(final_value)::NUMERIC, 2) as final_value,
	ROUND((SUM(final_value)/SUM(investment))::NUMERIC, 2) as profitability,
	ROUND((SUM(investment)/SUM(quantity))::NUMERIC, 2) as cost_per_unit
FROM bull_strategy
GROUP BY first_name, ticker;