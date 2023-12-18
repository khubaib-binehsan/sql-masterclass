-- Exploring the 'prices' table
-- How many total records do we have in the trading.prices table

SELECT
	COUNT(*) as total_records
FROM trading.prices;

-- How many records are there per ticker value

SELECT
	ticker,
	COUNT(*) as total_records
FROM trading.prices
GROUP BY ticker;

-- What is the minimum and maximum market_date values

SELECT
	MIN(market_date),
	MAX(market_date)
FROM trading.prices;

-- Are there differences in the market_date min/max values for each ticker

SELECT
	ticker,
	MIN(market_date),
	MAX(market_date)
FROM trading.prices
GROUP BY ticker;

-- What is the average of the price column for Bitcoin records during the year 2020

SELECT
	AVG(price)
FROM trading.prices
WHERE ticker = 'BTC'
	AND EXTRACT(YEAR FROM market_date) = 2020;

-- What is the monthly average of the price column for Ethereum in year 2020? Sort the output in chronological order and also round the average price value to 2 decimal figures.

SELECT
	EXTRACT(MONTH FROM market_date) as month_id,
	ROUND(AVG(price)::NUMERIC, 2)
FROM trading.prices
WHERE ticker = 'ETH'
	AND EXTRACT(YEAR FROM market_date) = 2020
GROUP BY month_id
ORDER BY month_id;

-- Are there any duplicate market_date values for any ticker value in our table

SELECT
	ticker,
	COUNT(market_date) as total_records,
	COUNT(DISTINCT market_date) as unique_records
FROM trading.prices
GROUP BY ticker;

-- How many days from the trading.prices table exist where the high price of bitcoin is over $30,000

SELECT
	COUNT(*) as days_count
FROM trading.prices
WHERE ticker = 'BTC'
	AND high > 30000;

-- How many "breakout" days were there in 2020 where the price column is greater than the open column for each ticker?

SELECT
	ticker,
	SUM(
		CASE WHEN price > open THEN 1 ELSE 0 END
	) as breakout_days
FROM trading.prices
WHERE EXTRACT(YEAR FROM market_date) = 2020
GROUP BY ticker;

-- How many "non_breakout" days were there in 2020 where the price column is less than the open column for each ticker?

SELECT
	ticker,
	SUM(
		CASE WHEN price < open THEN 1 ELSE 0 END
	) as non_breakout_days
FROM trading.prices
WHERE EXTRACT(YEAR FROM market_date) = 2020
GROUP BY ticker;

-- What percentage of days in 2020 were breakout days vs non-breakout days? Round the percentages to 2 decimal places

WITH cte as (
	SELECT
		ticker,
		SUM(CASE WHEN price > open THEN 1 ELSE 0 END) as breakout_days,
		SUM(CASE WHEN price < open THEN 1 ELSE 0 END) as non_breakout_days,
		COUNT(*) as total_days
	FROM trading.prices
	WHERE EXTRACT(YEAR FROM market_date) = 2020
	GROUP BY ticker
)
SELECT
	ticker,
	ROUND(100*breakout_days/total_days::NUMERIC, 2) as percent_breakout,
	ROUND(100*non_breakout_days/total_days::NUMERIC, 2) as percent_non_breakout
FROM cte;