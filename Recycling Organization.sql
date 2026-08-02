Stage 1:

WITH raited_money1 as 
	(SELECT money_in,
	NTILE(4) OVER(ORDER by money_in) as raited
	FROM Income_one_day),
    
    raited_money2 as 
	(SELECT money_in,
	NTILE(4) OVER(ORDER by money_in) as raited
	FROM Income)

SELECT
	"Company 1" AS company_name,
    ROUND(AVG(money_in), 2) AS mean,
    MAX(CASE WHEN raited = 2 THEN money_in END) AS median,
    MAX(money_in) - MIN(money_in) AS total_range,
    MAX(CASE WHEN raited = 3 THEN money_in END) - MAX(CASE WHEN raited = 1 THEN money_in END) as interquartile_range,
    ROUND(STDDEV(money_in), 2) AS standard_deviation,
    ROUND(VARIANCE(money_in), 2) AS variance
FROM raited_money1
UNION
SELECT
	"Company 2" AS company_name,
    ROUND(AVG(money_in), 2) AS mean,
    MAX(CASE WHEN raited = 2 THEN money_in END) median,
    MAX(money_in) - MIN(money_in) AS total_range,
    MAX(CASE WHEN raited = 3 THEN money_in END) - MAX(CASE WHEN raited = 1 THEN money_in END) as interquartile_range,
    ROUND(STDDEV(money_in), 2) AS standard_deviation,
    ROUND(VARIANCE(money_in), 2) AS variance
FROM raited_money2
________________________________

Stage 2:

SELECT 
    pick_up_point,
    date,
    SUM(money_in) AS total_money_in
FROM (SELECT pick_up_point, date, money_in FROM Income_one_day
      WHERE (pick_up_point, date, money_in) NOT IN (SELECT pick_up_point, date, money_in FROM Income)
      UNION ALL
      SELECT pick_up_point, date, money_in FROM Income) as temp_table
GROUP BY pick_up_point, date
________________________________

Stage 3:

WITH 
sums_in1 as (SELECT pick_up_point, sum(money_in) as total_income FROM Income_one_day GROUP by pick_up_point),
sums_out1 as (SELECT pick_up_point, sum(money_out) as total_outcome FROM Outcome_one_day GROUP by pick_up_point),
sums_in2 as (SELECT pick_up_point, sum(money_in)  as total_income FROM Income GROUP by pick_up_point),
sums_out2 as (SELECT pick_up_point, sum(money_out) as total_outcome FROM Outcome GROUP by pick_up_point)

SELECT 
	"Company 1" as company_name,
	sums_in1.pick_up_point, 
    sums_in1.total_income,
    sums_out1.total_outcome,
    sums_in1.total_income - sums_out1.total_outcome as net_income
FROM sums_in1
JOIN sums_out1 on sums_in1.pick_up_point = sums_out1.pick_up_point
UNION
SELECT 
	"Company 2" as company_name,
	sums_in2.pick_up_point, 
    sums_in2.total_income,
    sums_out2.total_outcome,
    sums_in2.total_income - sums_out2.total_outcome as net_income
FROM sums_in2
JOIN sums_out2 on sums_in2.pick_up_point = sums_out2.pick_up_point
ORDER BY company_name, net_income DESC
________________________________

Stage 4:

WITH 
    outcome_sum AS 
        (SELECT pick_up_point, date, SUM(money_out) AS money_out FROM Outcome GROUP BY pick_up_point, date),
    outcome_one_day_sum AS
        (SELECT pick_up_point, date, SUM(money_out) AS money_out FROM Outcome_one_day GROUP BY pick_up_point, date),
    all_dates AS
        (SELECT pick_up_point, date FROM Outcome UNION SELECT pick_up_point, date FROM Outcome_one_day)

SELECT
    all_dates.pick_up_point,
    all_dates.date,
    CASE
        WHEN COALESCE(outcome_one_day_sum.money_out, 0) = COALESCE(outcome_sum.money_out, 0) THEN 'both'
        WHEN COALESCE(outcome_one_day_sum.money_out, 0) > COALESCE(outcome_sum.money_out, 0) THEN 'once a day'
        ELSE 'more than once a day'
    END AS text
FROM all_dates
LEFT JOIN outcome_one_day_sum ON all_dates.pick_up_point = outcome_one_day_sum.pick_up_point AND all_dates.date = outcome_one_day_sum.date
LEFT JOIN outcome_sum ON all_dates.pick_up_point = outcome_sum.pick_up_point AND all_dates.date = outcome_sum.date
ORDER BY all_dates.pick_up_point, all_dates.date;
________________________________

Stage 5:

WITH CombinedIncome AS
    (SELECT pick_up_point, date, SUM(money_in) AS total_money_in FROM
        (SELECT pick_up_point, date, money_in FROM Income
        UNION ALL
        SELECT iod.pick_up_point, iod.date, iod.money_in FROM Income_one_day AS iod
        WHERE NOT EXISTS 
            (SELECT 1 FROM Income AS i WHERE i.pick_up_point = iod.pick_up_point
              AND i.date = iod.date
              AND i.money_in = iod.money_in)) AS income_data
    GROUP BY pick_up_point, date),

CombinedOutcome AS (SELECT pick_up_point, date, SUM(money_out) AS total_money_out
    FROM (SELECT pick_up_point, date,money_out FROM Outcome
          UNION ALL
          SELECT ood.pick_up_point, ood.date, ood.money_out FROM Outcome_one_day AS ood
          WHERE NOT EXISTS (SELECT 1 FROM Outcome AS o WHERE o.pick_up_point = ood.pick_up_point 
              AND o.date = ood.date
              AND o.money_out = ood.money_out)) AS outcome_data
    GROUP BY pick_up_point, date),

AllDates AS (SELECT pick_up_point, date FROM CombinedIncome
             UNION
             SELECT pick_up_point, date FROM CombinedOutcome)

SELECT
    ad.pick_up_point,
    ad.date,
    COALESCE(ci.total_money_in, 0) AS total_money_in,
    COALESCE(co.total_money_out, 0) AS total_money_out
FROM AllDates AS ad
LEFT JOIN CombinedIncome AS ci
    ON ad.pick_up_point = ci.pick_up_point
   AND ad.date = ci.date
LEFT JOIN CombinedOutcome AS co
    ON ad.pick_up_point = co.pick_up_point
   AND ad.date = co.date
ORDER BY
    ad.pick_up_point,
    ad.date;