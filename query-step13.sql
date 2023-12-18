-- Trader Strategy

WITH summary AS (
	SELECT
		m.first_name,
		t.ticker,
		t.txn_type,
		COUNT(*) as _count,
		ROUND(SUM(t.quantity)::NUMERIC, 2) as _qty,
		ROUND(SUM(t.quantity*p.price)::NUMERIC, 2) as _value,
		ROUND(SUM(t.quantity*p.price*t.percentage_fee/100)::NUMERIC, 2) as _fee,
		ROUND((SUM(t.quantity*p.price)/SUM(t.quantity))::NUMERIC, 2) as _dollar_per_unit
	FROM trading.transactions t
	INNER JOIN trading.members m
		ON t.member_id = m.member_id
	INNER JOIN trading.prices p
		ON t.ticker = p.ticker
		AND t.txn_date = p.market_date
	GROUP BY m.first_name, t.ticker, t.txn_type
),

_final AS(	
	SELECT
		m.first_name,
		t.ticker,
		ROUND(SUM(CASE WHEN t.txn_type = 'BUY' THEN t.quantity ELSE -t.quantity END)::NUMERIC, 2) as final_holdings,
		ROUND((SUM(CASE WHEN t.txn_type = 'BUY' THEN t.quantity ELSE -t.quantity END)*p.price)::NUMERIC, 2) as final_portfolio_value,
		p.price
	FROM trading.transactions t
	INNER JOIN trading.prices p
		ON t.ticker = p.ticker
		AND p.market_date = '2021-08-29'
	INNER JOIN trading.members m
		ON t.member_id = m.member_id
	GROUP BY m.first_name, t.ticker, p.price
	ORDER BY m.first_name, t.ticker
),

aggregated AS (
	SELECT
		s.first_name,
		s.ticker,
		SUM(CASE WHEN txn_type = 'BUY' THEN _count ELSE 0 END) as purchase_count,
		SUM(CASE WHEN txn_type = 'BUY' THEN _qty ELSE 0 END) as purchase_qty,
		SUM(CASE WHEN txn_type = 'BUY' THEN _value ELSE 0 END) as investment,
		SUM(CASE WHEN txn_type = 'BUY' THEN _fee ELSE 0 END) as purchase_fee,
		SUM(CASE WHEN txn_type = 'SELL' THEN _count ELSE 0 END) as sales_count,
		SUM(CASE WHEN txn_type = 'SELL' THEN _qty ELSE 0 END) as sales_qty,
		SUM(CASE WHEN txn_type = 'SELL' THEN _value ELSE 0 END) as revenue,
		SUM(CASE WHEN txn_type = 'SELL' THEN _fee ELSE 0 END) as sales_fee,
		MAX(final_holdings) as final_holdings,
		MAX(final_portfolio_value) as portfolio_value,
		MAX(f.price) as final_price
	FROM summary s
	INNER JOIN _final f
		ON s.ticker = f.ticker
		AND s.first_name = f.first_name
	GROUP BY s.first_name, s.ticker
)

SELECT
	a.first_name,
	m.region,
	ticker,
	ROUND(((portfolio_value - purchase_fee)/investment)::NUMERIC, 2) as theoretical_profitability,
	ROUND(((portfolio_value + revenue - sales_fee - purchase_fee)/investment)::NUMERIC, 2) as actual_profitability,
	final_holdings,
	portfolio_value,
	investment,
	revenue,
	purchase_qty,
	sales_qty,
	purchase_count,
	sales_count,
	purchase_fee,
	sales_fee,
	ROUND(investment/purchase_qty::NUMERIC, 2) as avg_buying,
	ROUND(revenue/sales_qty::NUMERIC, 2) as avg_selling,
	ROUND(purchase_fee/purchase_count::NUMERIC, 2) as avg_buying_fee,
	ROUND(sales_fee/sales_qty::NUMERIC, 2) as avg_selling_fee
FROM aggregated a
INNER JOIN trading.members m
	ON a.first_name = m.first_name
ORDER BY region, ticker, actual_profitability DESC;