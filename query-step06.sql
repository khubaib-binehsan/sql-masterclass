-- planning ahead for data analysis
-- creating a temporary base table
-- step 01

DROP TABLE IF EXISTS TEMP_PRICES;
CREATE TEMP TABLE TEMP_PRICES AS
WITH cte AS (
	SELECT
		ticker,
		EXTRACT(YEAR FROM market_date) as market_year,
		market_date,
		price
	FROM trading.prices
	WHERE EXTRACT(MONTH FROM market_date) = 12
),

cte2 AS (
	SELECT
		ticker,
		market_year,
		market_date,
		price,
		RANK() OVER(PARTITION BY ticker, market_year ORDER BY market_date DESC) as ranked
	FROM cte
	GROUP BY ticker, market_year, market_date, price
)

SELECT
	market_year,
	ticker,
	price
FROM cte2
WHERE ranked = 1;

DROP TABLE IF EXISTS TEMP_PORTFOLIO;
CREATE TEMP TABLE TEMP_PORTFOLIO AS
WITH base_table AS (
	SELECT
		m.first_name,
		m.region,
		EXTRACT(YEAR FROM t.txn_date) as txn_year,
		t.ticker,
		CASE WHEN t.txn_type = 'BUY' THEN t.quantity ELSE -t.quantity END as quantity
	FROM trading.transactions t
	INNER JOIN trading.members m
		ON t.member_id = m.member_id
	WHERE EXTRACT(YEAR FROM t.txn_date) <= 2020
),

aggregate_table AS (
	SELECT
		first_name,
		region,
		txn_year,
		ticker,
		SUM(quantity) as adjusted_qty
	FROM base_table
	GROUP BY first_name, region, txn_year, ticker
)

SELECT
	a.*,
	p.price
FROM aggregate_table a
INNER JOIN TEMP_PRICES p
	ON a.ticker = p.ticker
	AND a.txn_year = p.market_year
ORDER BY a.first_name, a.txn_year, a.ticker;
	
DROP TABLE IF EXISTS TEMP_PORTFOLIO_CUM;
CREATE TEMP TABLE TEMP_PORTFOLIO_CUM AS
SELECT
	first_name,
	region,
	txn_year,
	ticker,
	adjusted_qty as quantity,
	SUM(adjusted_qty) OVER(
		PARTITION BY first_name, ticker
		ORDER BY txn_year
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	) as cummulative_qty
FROM TEMP_PORTFOLIO;