-- What is the total portfolio value for each member at the end of 2020?

SELECT
	t.first_name,
	ROUND(SUM(t.adjusted_qty*p.price)::NUMERIC, 2) as portfolio_value
FROM TEMP_PORTFOLIO t
INNER JOIN (
	SELECT ticker, price
	FROM TEMP_PRICES
	WHERE market_year = 2020
) p
	ON t.ticker = p.ticker
GROUP BY t.first_name
ORDER BY portfolio_value DESC;

-- What is the total portfolio value for each region at the end of 2019?

SELECT
	t.region,
	ROUND(SUM(t.adjusted_qty*p.price)::NUMERIC, 2) as portfolio_value
FROM TEMP_PORTFOLIO t
INNER JOIN (
	SELECT ticker, price
	FROM TEMP_PRICES
	WHERE market_year = 2019
) p
	ON t.ticker = p.ticker
WHERE t.txn_year <= 2019
GROUP BY t.region
ORDER BY portfolio_value DESC;

-- What percentage of regional portfolio values does each member contribute at the end of 2018?

WITH cte_prices AS (
	SELECT
		ticker,
		price
	FROM TEMP_PRICES
	WHERE market_year = 2018
),

cte as (
	SELECT
		t.region,
		SUM(t.adjusted_qty*p.price) as region_value
	FROM TEMP_PORTFOLIO t
	INNER JOIN cte_prices p
		ON t.ticker = p.ticker
	WHERE t.txn_year <= 2018
	GROUP BY t.region
),

cte2 as (
	SELECT
		t.first_name,
		t.region,
		SUM(t.adjusted_qty*p.price) as portfolio_value
	FROM TEMP_PORTFOLIO t
	INNER JOIN cte_prices p
		ON t.ticker = p.ticker
	WHERE t.txn_year <= 2018
	GROUP BY t.first_name, t.region
)

SELECT
	p.region,
	p.first_name,
	ROUND(r.region_value::NUMERIC, 2) as region_value,
	ROUND((100*p.portfolio_value/r.region_value)::NUMERIC, 2) as contribution
FROM cte r
INNER JOIN cte2 p
	ON r.region = p.region
ORDER BY r.region_value DESC, contribution DESC;

-- Does this region contribution percentage change when we look across both Bitcoin and Ethereum portfolios independently at the end of 2017?

WITH cte_prices AS (
	SELECT
		ticker,
		price
	FROM TEMP_PRICES
	WHERE market_year = 2017
),

cte as (
	SELECT
		t.region,
		t.ticker,
		SUM(t.adjusted_qty*p.price) as region_value
	FROM TEMP_PORTFOLIO t
	INNER JOIN cte_prices p
		ON t.ticker = p.ticker
	WHERE t.txn_year <= 2017
	GROUP BY t.region, t.ticker
),

cte2 as (
	SELECT
		t.first_name,
		t.region,
		t.ticker,
		SUM(t.adjusted_qty*p.price) as portfolio_value
	FROM TEMP_PORTFOLIO t
	INNER JOIN cte_prices p
		ON t.ticker = p.ticker
	WHERE t.txn_year <= 2017
	GROUP BY t.first_name, t.region, t.ticker
)

SELECT
	p.region,
	p.first_name,
	p.ticker,
	ROUND((100*p.portfolio_value/r.region_value)::NUMERIC, 2) as contribution
FROM cte r
INNER JOIN cte2 p
	ON r.region = p.region
	AND r.ticker = p.ticker
ORDER BY p.ticker, contribution DESC;

-- Calculate the ranks for each mentor in the US and Australia for each year and ticker

WITH cte AS (
	SELECT
		region,
		first_name,
		txn_year,
		ticker,
		RANK() OVER(PARTITION BY region, txn_year, ticker ORDER BY adjusted_qty DESC) as ranked
	FROM TEMP_PORTFOLIO
	WHERE region IN ('Australia', 'United States')
	ORDER BY region, ticker, txn_year
)
SELECT
	region,
	first_name,
	SUM(CASE WHEN ticker = 'BTC' AND txn_year = 2017 THEN ranked ELSE 0 END) as btc2017,
	SUM(CASE WHEN ticker = 'BTC' AND txn_year = 2018 THEN ranked ELSE 0 END) as btc2018,
	SUM(CASE WHEN ticker = 'BTC' AND txn_year = 2019 THEN ranked ELSE 0 END) as btc2019,
	SUM(CASE WHEN ticker = 'BTC' AND txn_year = 2020 THEN ranked ELSE 0 END) as btc2020,
	SUM(CASE WHEN ticker = 'ETH' AND txn_year = 2017 THEN ranked ELSE 0 END) as eth2017,
	SUM(CASE WHEN ticker = 'ETH' AND txn_year = 2018 THEN ranked ELSE 0 END) as eth2018,
	SUM(CASE WHEN ticker = 'ETH' AND txn_year = 2019 THEN ranked ELSE 0 END) as eth2019,
	SUM(CASE WHEN ticker = 'ETH' AND txn_year = 2020 THEN ranked ELSE 0 END) as eth2020
FROM cte
GROUP BY region, first_name
ORDER BY region, btc2017;