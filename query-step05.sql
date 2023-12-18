-- Joining the tables and carrying out real analysis
-- What is the earliest and latest date of transactions for all members?

SELECT
	MIN(txn_date),
	MAX(txn_date)
FROM trading.transactions;

-- What is the range of market_date values available in the prices data?

SELECT
	MIN(market_date),
	MAX(market_date)
FROM trading.prices;

-- Which top 3 mentors have the most Bitcoin quantity as of the 29th of August?

SELECT
	m.first_name,
	SUM(CASE WHEN t.txn_type = 'BUY' THEN t.quantity ELSE - t.quantity END) as holding_qty
FROM trading.transactions t
INNER JOIN trading.members m
	ON t.member_id = m.member_id
WHERE t.ticker = 'BTC'
GROUP BY m.first_name
ORDER BY holding_qty DESC
LIMIT 3;
	
-- What is total value of all Ethereum portfolios for each region at the end date of our analysis? Order the output by descending portfolio value

WITH cte_price AS (
SELECT
	ticker,
	price
FROM trading.prices
WHERE ticker = 'ETH'
ORDER BY market_date DESC
LIMIT 1
)
SELECT
	m.region,
	ROUND(SUM(CASE WHEN t.txn_type = 'BUY' THEN t.quantity ELSE -t.quantity END)::NUMERIC, 2) as eth_qty,
	ROUND((SUM(CASE WHEN t.txn_type = 'BUY' THEN t.quantity ELSE -t.quantity END)*p.price)::NUMERIC, 2) as eth_value
FROM trading.transactions t
INNER JOIN trading.members m
	ON t.member_id = m.member_id
INNER JOIN cte_price p
	ON t.ticker = p.ticker
WHERE t.ticker = 'ETH'
GROUP BY m.region, p.price
ORDER BY eth_value DESC;

-- What is the average value of each Ethereum portfolio in each region? Sort this output in descending order

WITH portfolio_value AS (
	WITH cte_price AS (
		SELECT
			ticker,
			price
		FROM trading.prices
		WHERE ticker = 'ETH'
		ORDER BY market_date DESC
		LIMIT 1
	)
	SELECT
		m.region,
		ROUND((SUM(CASE WHEN t.txn_type = 'BUY' THEN t.quantity ELSE -t.quantity END)*p.price)::NUMERIC, 2) as eth_value,
		ROUND((SUM(CASE WHEN t.txn_type = 'BUY' THEN t.quantity ELSE -t.quantity END)*p.price)::NUMERIC, 2) as avg_eth_value
	FROM trading.transactions t
	INNER JOIN trading.members m
		ON t.member_id = m.member_id
	INNER JOIN cte_price p
		ON t.ticker = p.ticker
	WHERE t.ticker = 'ETH'
	GROUP BY m.region, p.price
)
SELECT
	v.region,
	v.eth_value,
	ROUND(v.eth_value/m.member_count::NUMERIC, 2) as avg_eth_value
FROM portfolio_value v
INNER JOIN (SELECT region, COUNT(*) as member_count FROM trading.members GROUP BY region) m
	ON v.region = m.region
ORDER BY avg_eth_value DESC;