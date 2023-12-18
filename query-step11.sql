-- Trader Strategy

DROP TABLE IF EXISTS trader_strategy;
CREATE TEMP TABLE trader_strategy AS
WITH cte_member AS (
	SELECT
		member_id,
		first_name
	FROM trading.members
	WHERE first_name = 'Nandita'
)
SELECT
	m.first_name,
	t.txn_date,
	t.ticker,
	t.txn_type,
	t.quantity,
	t.percentage_fee,
	p.price
FROM trading.transactions t
INNER JOIN cte_member m
	ON t.member_id = m.member_id
INNER JOIN trading.prices p
	ON t.ticker = p.ticker
	AND t.txn_date = p.market_date;

-- Calculate Nandita's purchase metrics for each of her BTC and ETH portfolio:
-- count of purchases, initial investment, purhase fee, dollar cost average

SELECT
	first_name,
	ticker,
	COUNT(*) as purchase_count,
	ROUND(SUM(quantity)::NUMERIC, 2) as purchase_qty,
	ROUND(SUM(quantity*price)::NUMERIC, 2) as investment,
	ROUND(SUM(quantity*price*percentage_fee/100)::NUMERIC, 2) as fee,
	ROUND((SUM(quantity*price)/SUM(quantity))::NUMERIC, 2) as dollar_per_unit
FROM trader_strategy
WHERE txn_type = 'BUY'
GROUP BY first_name, ticker;

-- Calculate Nandita's sales metrics for each of her ETH and BTC portfolios:
-- count of sales, gross revenue amount, sales fee, average selling price

SELECT
	first_name,
	ticker,
	COUNT(*) as sales_count,
	ROUND(SUM(quantity)::NUMERIC, 2) as sales_qty,
	ROUND(SUM(quantity*price)::NUMERIC, 2) as revenue,
	ROUND(SUM(quantity*price*percentage_fee/100)::NUMERIC, 2) as fee,
	ROUND((SUM(quantity*price)/SUM(quantity))::NUMERIC, 2) as dollar_per_unit
FROM trader_strategy
WHERE txn_type = 'SELL'
GROUP BY first_name, ticker;

-- bonus combining both queries

SELECT
	first_name,
	ticker,
	txn_type,
	COUNT(*) as _count,
	ROUND(SUM(quantity)::NUMERIC, 2) as _qty,
	ROUND(SUM(quantity*price)::NUMERIC, 2) as _value,
	ROUND(SUM(quantity*price*percentage_fee/100)::NUMERIC, 2) as fee,
	ROUND((SUM(quantity*price)/SUM(quantity))::NUMERIC, 2) as dollar_per_unit
FROM trader_strategy
GROUP BY first_name, ticker, txn_type;

-- final portfolio value

SELECT
	t.ticker,
	ROUND(SUM(CASE WHEN t.txn_type = 'BUY' THEN t.quantity ELSE -t.quantity END)::NUMERIC, 2) as final_holdings,
	ROUND((SUM(CASE WHEN t.txn_type = 'BUY' THEN t.quantity ELSE -t.quantity END)*p.price)::NUMERIC, 2) as final_portfolio_value
FROM trader_strategy t
INNER JOIN trading.prices p
	ON t.ticker = p.ticker
	AND p.market_date = '2021-08-29'
GROUP BY t.ticker, p.price;

-- one final showdown

WITH summary AS (
	SELECT
		first_name,
		ticker,
		txn_type,
		COUNT(*) as _count,
		ROUND(SUM(quantity)::NUMERIC, 2) as _qty,
		ROUND(SUM(quantity*price)::NUMERIC, 2) as _value,
		ROUND(SUM(quantity*price*percentage_fee/100)::NUMERIC, 2) as _fee,
		ROUND((SUM(quantity*price)/SUM(quantity))::NUMERIC, 2) as _dollar_per_unit
	FROM trader_strategy
	GROUP BY first_name, ticker, txn_type
),

_final AS (
	SELECT
		t.ticker,
		ROUND(SUM(CASE WHEN t.txn_type = 'BUY' THEN t.quantity ELSE -t.quantity END)::NUMERIC, 2) as final_holdings,
		ROUND((SUM(CASE WHEN t.txn_type = 'BUY' THEN t.quantity ELSE -t.quantity END)*p.price)::NUMERIC, 2) as final_portfolio_value,
		p.price
	FROM trader_strategy t
	INNER JOIN trading.prices p
		ON t.ticker = p.ticker
		AND p.market_date = '2021-08-29'
	GROUP BY t.ticker, p.price
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
	GROUP BY s.first_name, s.ticker
)

SELECT
	first_name,
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
FROM aggregated;