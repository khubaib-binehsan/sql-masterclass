-- Exploring the 'members' table
-- Show only the top 5 rows from the trading.members table

SELECT * FROM trading.members LIMIT 5;

-- Sort all the rows in the table by first_name in alphabetical order and show the top 3

SELECT * FROM trading.members
ORDER BY first_name
LIMIT 3;

-- Which records from trading.members are from the United States region

SELECT * FROM trading.members
WHERE region = 'United States';

-- Select only the member_id and first_name columns for members who are not from United States

SELECT
	member_id,
	first_name
FROM trading.members
WHERE region != 'United States';

-- Return the unique region values from trading.members and sort the output by reverse alphabetical order

SELECT
	DISTINCT region as region
FROM trading.members
ORDER BY region DESC;

-- How many members are there from Australia or the United States

SELECT
	COUNT(member_id) as member_count
FROM trading.members
WHERE region IN ('United States', 'Australia');

-- How many members are not from Australia or the United States

SELECT
	COUNT(member_id) as member_count
FROM trading.members
WHERE region NOT IN ('United States', 'Australia');

-- How many members are there per region? Sort the output by regions with most members to the least

SELECT
	region,
	COUNT(member_id) as member_count
FROM trading.members
GROUP BY region
ORDER BY member_count DESC;

-- How many US and non-US members are there

SELECT
	CASE
		WHEN region != 'United States' THEN 'Non US'
		ELSE region
	END as member_region,
	COUNT(*) as member_count
FROM trading.members
GROUP BY member_region;

-- How many members have a first_name starting with a letter before 'E'

SELECT
	COUNT(*) as member_count
FROM trading.members
WHERE LEFT(first_name, 1) < 'E';