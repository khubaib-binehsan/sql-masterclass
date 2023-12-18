-- HODL (Hold On for Dear Life STRATEGY)

WITH cte_member AS (
	SELECT
		member_id,
		first_name
	FROM trading.members
	WHERE first_name = 'Leah'
),

cte_hodl_strategy AS (
	SELECT
		*
	FROM (
		SELECT
			m.first_name,
			t.ticker,
			t.quantity,
			t.percentage_fee,
			t.quantity*_initial.price*t.percentage_fee/100 as fee,
			t.quantity*_initial.price as initial_value,
			t.quantity*_final.price as final_value,
			RANK() OVER(PARTITION BY m.first_name, t.ticker ORDER BY t.txn_time) as ranked
		FROM trading.transactions t
		INNER JOIN cte_member m
			ON t.member_id = m.member_id
		INNER JOIN trading.prices _initial
			ON t.ticker = _initial.ticker
			AND _initial.market_date = '2017-01-01'
		INNER JOIN trading.prices _final
			ON t.ticker = _final.ticker
			AND _final.market_date = '2021-08-29'
	) cte_initial
	WHERE ranked = 1
)

SELECT
	first_name,
	ROUND(SUM(initial_value)::NUMERIC, 2) as initial_value,
	ROUND(SUM(fee)::NUMERIC, 2) as fee,
	ROUND(SUM(final_value)::NUMERIC, 2) as final_value,
	ROUND((SUM(final_value)/SUM(initial_value))::NUMERIC, 2) as profitability
FROM cte_hodl_strategy
GROUP BY first_name;