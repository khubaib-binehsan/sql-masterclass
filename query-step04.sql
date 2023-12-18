-- Exploring the trading.transactions table
-- How many records are there in the trading.transactions table

SELECT
	COUNT(txn_id)
FROM trading.transactions;

-- How many unique transactions are there 

SELECT
	COUNT(DISTINCT txn_id)
FROM trading.transactions;

-- How many buy and sell transactions are there for Bitcoin

SELECT
	txn_type,
	COUNT(txn_id)
FROM trading.transactions
WHERE ticker = 'BTC'
GROUP BY txn_type;

-- For each year, calculate the following buy and sell metrics for Bitcoin:
-- transaction count, total quantity, average quantity per transaction
-- also round the figures to 2 decimal places

SELECT
	EXTRACT(YEAR FROM txn_date) as txn_year,
	txn_type,
	COUNT(txn_id) as transaction_count,
	ROUND(SUM(quantity)::NUMERIC, 2) as transaction_qty,
	ROUND(AVG(quantity)::NUMERIC, 2) as avg_transaction_qty
FROM trading.transactions
WHERE ticker = 'BTC'
GROUP BY txn_year, txn_type
ORDER BY txn_year;

-- What was the monthly total quantity purchased and sold for Ethereum in 2020

SELECT
	EXTRACT(MONTH FROM txn_date) as txn_month,
	txn_type,
	ROUND(SUM(quantity)::NUMERIC, 2) as transaction_qty
FROM trading.transactions
WHERE ticker = 'ETH'
GROUP BY txn_month, txn_type
ORDER BY txn_month, txn_type;

-- Summarise all buy and sell transactions for each member_id by generating 1 row for each member with the following additional columns:
-- bitcoin buy quantity, bitcoin sell quantity, ehtereum buy quantity, ethereum sell quantity

SELECT
	member_id,
	SUM(CASE WHEN ticker = 'BTC' AND txn_type = 'BUY' THEN quantity ELSE 0 END) as btc_buy_qty,
	SUM(CASE WHEN ticker = 'BTC' AND txn_type = 'SELL' THEN quantity ELSE 0 END) as btc_sell_qty,
	SUM(CASE WHEN ticker = 'ETH' AND txn_type = 'BUY' THEN quantity ELSE 0 END) as eth_buy_qty,
	SUM(CASE WHEN ticker = 'ETH' AND txn_type = 'SELL' THEN quantity ELSE 0 END) as eth_sell_qty
FROM trading.transactions
GROUP BY member_id;

-- What was the final quantity holding of bitcoin for each member? Sort the output from highest bitcoin holding to lowest

SELECT
	member_id,
	SUM(CASE WHEN txn_type = 'BUY' THEN quantity ELSE -quantity END) as final_holding
FROM trading.transactions
WHERE ticker = 'BTC'
GROUP BY member_id
ORDER BY final_holding DESC;

-- Which members have sold less than 500 Bitcoins? Sort the output from most to least sold

SELECT
	member_id,
	SUM(quantity) as qty_sold
FROM trading.transactions
WHERE ticker = 'BTC'
	AND txn_type = 'SELL'
GROUP BY member_id
HAVING SUM(quantity) < 500
ORDER BY qty_sold DESC;

-- What is the total Bitcoin quantity for each member_id owns after adding all of the BUY and SELL transactions from the transactions table? Sort the output by descending total quantity

-- same as final bitcoin holding one!

-- Which member_id has the highest buy to sell ratio by quantity?

WITH cte AS (
SELECT
	member_id,
	SUM(CASE WHEN txn_type = 'BUY' THEN quantity ELSE 0 END) as total_bought,
	SUM(CASE WHEN txn_type = 'SELL' THEN quantity ELSE 0 END) as total_sold
FROM trading.transactions
GROUP BY member_id
)
SELECT
	member_id,
	ROUND((total_bought/total_sold)::NUMERIC, 2) as buy_to_sell
FROM cte
ORDER BY buy_to_sell DESC;

-- For each member_id - which month had the highest total Ethereum quantity sold`?

WITH cte AS (
	SELECT
		member_id,
		DATE_TRUNC('MON', txn_date)::DATE as txn_month,
		SUM(quantity) as qty_sold,
		RANK() OVER(PARTITION BY member_id ORDER BY SUM(quantity) DESC) AS month_rank
	FROM trading.transactions
	WHERE ticker = 'ETH'
		AND txn_type = 'SELL'
	GROUP BY member_id, txn_month
)
SELECT
	member_id,
	txn_month,
	qty_sold
FROM cte
WHERE month_rank = 1
ORDER BY qty_sold DESC;