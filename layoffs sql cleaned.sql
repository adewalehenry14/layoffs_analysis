-- CONTEXT:
-- We select the database that contains our layoffs data.
USE world_layoffs;

-- Allow UPDATE and DELETE statements without a key column (MySQL Workbench safe mode)
SET SQL_SAFE_UPDATES = 0;


-- CONTEXT:
-- We display the original layoffs dataset so we can inspect
-- the data before making any changes.
SELECT *
FROM layoffs;


-- CONTEXT:
-- We remove the previous staging table if it already exists.
-- This allows us to start the cleaning process from a fresh copy.
DROP TABLE IF EXISTS layoffs_staging2;


-- CONTEXT:
-- We create a new staging table with the same structure as
-- the original layoffs table. This gives us a safe working copy.
CREATE TABLE layoffs_staging2
LIKE layoffs;


-- CONTEXT:
-- We add a temporary column called row_num.
-- This will help us identify duplicate records.
ALTER TABLE layoffs_staging2
ADD COLUMN row_num INT;


-- CONTEXT:
-- We copy the original data into the staging table.
-- At the same time, we assign a number to each record within
-- groups of identical records so duplicates can be identified.
INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company,
                        location,
                        industry,
                        total_laid_off,
                        percentage_laid_off,
                        `date`,
                        stage,
                        country,
                        funds_raised_millions
       ) AS row_num
FROM layoffs;


-- CONTEXT:
-- We display the staging table to confirm that the data was
-- successfully copied and the row numbers were added.
SELECT *
FROM layoffs_staging2;



-- CONTEXT:
-- We display records that have a row number greater than 1.
-- These records are potential duplicates of another record.
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;


-- CONTEXT:
-- We search specifically for Casper to inspect all of its
-- layoff records and check the data for that company.
SELECT *
FROM layoffs_staging2
WHERE company = 'Casper';


-- CONTEXT:
-- We remove duplicate records identified by row_num.
-- The first occurrence is kept, while additional copies are removed.
DELETE FROM layoffs_staging2
WHERE row_num > 1;



-- CONTEXT:
-- We list all unique company names in the dataset.
-- This helps us identify inconsistent company names.
SELECT DISTINCT company
FROM layoffs_staging2;


-- CONTEXT:
-- We compare the original company name with a version where
-- unnecessary spaces at the beginning or end have been removed.
SELECT company, TRIM(company)
FROM layoffs_staging2;


-- CONTEXT:
-- We remove unnecessary spaces from company names so that
-- company names are stored consistently.
UPDATE layoffs_staging2
SET company = TRIM(company);


-- CONTEXT:
-- We list all unique industries in the dataset.
-- This helps us identify inconsistencies in industry categories.
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;


-- CONTEXT:
-- We search for records whose industry starts with "Crypto".
-- This helps us find different versions of the same industry category.
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';


-- CONTEXT:
-- We standardize all industry values beginning with "Crypto"
-- into one consistent category called "Crypto".
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';


-- CONTEXT:
-- We convert blank industry values and the text "NULL"
-- into actual missing values.
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '' OR industry = 'NULL';


-- CONTEXT:
-- We fill Airbnb's missing industry classification with "Travel".
UPDATE layoffs_staging2
SET industry = 'Travel'
WHERE company = 'Airbnb';


-- CONTEXT:
-- We fill Juul's missing industry classification with "Consumer".
UPDATE layoffs_staging2
SET industry = 'Consumer'
WHERE company = 'Juul';


-- CONTEXT:
-- We fill Carvana's missing industry classification with
-- "Transportation".
UPDATE layoffs_staging2
SET industry = 'Transportation'
WHERE company = 'Carvana';


-- CONTEXT:
-- We check the unique industry categories again after
-- standardizing the industry data.
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;



-- CONTEXT:
-- We list all unique locations in the dataset.
-- This helps us inspect location consistency.
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;


-- CONTEXT:
-- We list all unique countries in the dataset to look for
-- inconsistencies in country names.
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;


-- CONTEXT:
-- We compare the original country name with a version that
-- has any trailing period removed.
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;


-- CONTEXT:
-- We remove trailing periods from United States entries so
-- that the country name is stored consistently.
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';


-- CONTEXT:
-- We convert the text value "NULL" in the date column into
-- an actual missing value.
UPDATE layoffs_staging2
SET `date` = NULL
WHERE `date` = 'NULL';


-- CONTEXT:
-- We compare the original date with its converted date value.
-- This allows us to check how MySQL interprets the dates.
SELECT `date`,
       STR_TO_DATE(`date`, '%c/%e/%Y') AS converted_date
FROM layoffs_staging2;


-- CONTEXT:
-- We convert the values in the date column into date values.
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%c/%e/%Y');


-- CONTEXT:
-- We change the date column to the DATE data type so that
-- it can be properly used for date-based analysis.
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- CONTEXT:
-- We check a sample of the dates to confirm the conversion.
SELECT `date`
FROM layoffs_staging2
LIMIT 10;


-- CONTEXT:
-- We display the complete dataset after the cleaning steps.
SELECT *
FROM layoffs_staging2;


-- CONTEXT:
-- We identify records where both the total number laid off
-- and the percentage laid off are missing.
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


-- CONTEXT:
-- We check for industries that are missing or contain only
-- a blank space.
SELECT DISTINCT industry
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = ' ';


-- CONTEXT:
-- We inspect Airbnb's records to examine its industry information.
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';


-- CONTEXT:
-- We find all records where the industry is still missing
-- or contains only a blank space.
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = ' ';


-- CONTEXT:
-- We search for companies whose names begin with "Bally".
-- This allows us to inspect those records individually.
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';


-- CONTEXT:
-- We compare industry information between records belonging
-- to the same company. This helps find known industry values
-- that can be used to fill missing ones.
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = ' ')
AND t2.industry IS NOT NULL;


-- CONTEXT:
-- We fill missing industry values by using the industry value
-- from another record belonging to the same company.
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


-- CONTEXT:
-- We review the dataset after filling the missing industry values.
SELECT *
FROM layoffs_staging2;


-- CONTEXT:
-- We identify records where the total number of employees laid
-- off is missing.
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL;


-- CONTEXT:
-- We remove records where both the number and percentage of
-- employees laid off are missing because they contain no
-- information about the size of the layoff.
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


-- CONTEXT:
-- We review the dataset after removing records with no
-- layoff-size information.
SELECT *
FROM layoffs_staging2;


-- CONTEXT:
-- The row_num column was only needed during duplicate removal.
-- Now that duplicate cleaning is complete, we remove that column.
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;



-- Exploratory Data Analysis

-- CONTEXT:
-- We display the cleaned dataset before beginning the analysis.
SELECT *
FROM layoffs_staging2;


-- CONTEXT:
-- We find the earliest and latest dates in the dataset.
-- This tells us the overall period covered by the data.
SELECT MIN(`date`) AS earliest, MAX(`date`) AS latest
FROM layoffs_staging2;

SELECT SUM(total_laid_off) FROM layoffs_staging2;


-- CONTEXT:
-- We find the highest number of employees laid off in a single
-- event and the highest percentage of employees laid off.
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;


-- CONTEXT:
-- We identify companies that laid off 100% of their workforce
-- and arrange them from the largest number of layoffs downward.
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;


-- CONTEXT:
-- We identify companies that laid off 100% of their workforce
-- and arrange them according to the amount of funding they raised.
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;


-- CONTEXT:
-- We calculate the total number of layoffs for each company
-- across all recorded layoff events.
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;


-- CONTEXT:
-- We find the earliest and latest dates again to confirm
-- the time range of the dataset.
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;


-- CONTEXT:
-- We calculate the total number of layoffs for each industry.
-- This shows how layoffs are distributed across industries.
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;


-- CONTEXT:
-- We display the dataset for inspection before continuing
-- with the country analysis.
SELECT *
FROM layoffs_staging2;


-- CONTEXT:
-- We calculate the total number of layoffs for each country.
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;


-- CONTEXT:
-- We display the dataset for inspection before continuing
-- with the date analysis.
SELECT *
FROM layoffs_staging2;


-- CONTEXT:
-- We calculate the total number of layoffs recorded on each date.
SELECT `date`, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY `date`
ORDER BY 1 DESC;


-- CONTEXT:
-- We calculate the total number of layoffs for each year.
-- This allows us to compare layoff activity across years.
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;


-- CONTEXT:
-- We calculate the total number of layoffs for each company stage.
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;


-- CONTEXT:
-- We group the layoffs by month and calculate the total number
-- of employees laid off during each month.
SELECT SUBSTRING(`date`,1,7) AS `Month`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC
;


-- CONTEXT:
-- We calculate the total layoffs for each month and then create
-- a rolling total. The rolling total shows how layoffs accumulated
-- over the period covered by the dataset.
WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`,1,7) AS `Month`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC
)
SELECT `Month`, total_off
,SUM(total_off) OVER(ORDER BY `Month`) AS rolling_total
FROM Rolling_Total;


-- CONTEXT:
-- We calculate the total number of layoffs for each company
-- in each year.
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY company ASC;


-- CONTEXT:
-- We calculate company layoffs by year and arrange the results
-- from the highest number of layoffs to the lowest.
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;


-- CONTEXT:
-- We calculate total layoffs for each company in each year,
-- then rank companies within each year. The final result shows
-- the five highest-ranked companies for every year.
WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(SELECT *, 
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5
;


-- CONTEXT:
-- We calculate the average percentage of employees laid off
-- for each company stage and count how many layoff events occurred.
SELECT stage,
       ROUND(AVG(percentage_laid_off), 2) AS avg_pct_laid_off,
       COUNT(*)                            AS num_events
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL
GROUP BY stage
ORDER BY avg_pct_laid_off DESC;


-- CONTEXT:
-- We identify companies that raised at least $500 million and
-- examine their layoff percentage, company stage, and date.
SELECT company, funds_raised_millions, percentage_laid_off, stage, `date`
FROM layoffs_staging2
WHERE funds_raised_millions >= 500
  AND percentage_laid_off IS NOT NULL
ORDER BY percentage_laid_off DESC
LIMIT 15;


-- CONTEXT:
-- We count the number of recorded layoff events for each industry
-- and show the ten industries with the most events.
SELECT industry, COUNT(*) AS num_events
FROM layoffs_staging2
GROUP BY industry
ORDER BY num_events DESC
LIMIT 10;


-- CONTEXT:
-- We calculate the average percentage of employees laid off
-- for each industry. We only include industries with at least
-- ten recorded events.
SELECT 
    industry,
    ROUND(AVG(percentage_laid_off), 2) AS avg_pct_laid_off,
    COUNT(*) AS num_events
FROM
    layoffs_staging2
WHERE
    percentage_laid_off IS NOT NULL
GROUP BY industry
HAVING COUNT(*) >= 10
ORDER BY avg_pct_laid_off DESC;


-- CONTEXT:
-- We display the dataset again for inspection before continuing
-- with the next analysis.
SELECT *
FROM layoffs_staging2;


-- CONTEXT:
-- We classify each layoff event into two groups based on the
-- percentage of employees laid off: severe events (50% or more)
-- and moderate events (less than 50%). We then compare these
-- groups across different years.
SELECT YEAR(`date`) AS `year`,
       SUM(CASE WHEN percentage_laid_off >= 0.5 THEN 1 ELSE 0 END) AS severe_events,
       SUM(CASE WHEN percentage_laid_off < 0.5 THEN 1 ELSE 0 END)  AS moderate_events
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL
  AND `date` IS NOT NULL
GROUP BY YEAR(`date`)
ORDER BY `year`;


-- CONTEXT:
-- We group companies into funding brackets based on how much
-- money they raised, then calculate the average percentage of
-- employees laid off and the number of events in each bracket.
SELECT
    CASE
        WHEN funds_raised_millions < 10  THEN 'Under $10M'
        WHEN funds_raised_millions < 100 THEN '$10M - $100M'
        WHEN funds_raised_millions < 500 THEN '$100M - $500M'
        ELSE 'Over $500M'
    END AS funding_bracket,
    ROUND(AVG(percentage_laid_off), 2) AS avg_pct_laid_off,
    COUNT(*) AS num_events
FROM layoffs_staging2
WHERE funds_raised_millions IS NOT NULL
  AND percentage_laid_off IS NOT NULL
GROUP BY funding_bracket
ORDER BY MIN(funds_raised_millions);


-- CONTEXT:
-- We identify companies that experienced more than one layoff event.
-- For each company, we show the number of events, total employees
-- laid off, first recorded event, and most recent event.
SELECT company,
       COUNT(DISTINCT `date`)   AS num_layoff_events,
       SUM(total_laid_off)      AS total_laid_off_all_rounds,
       MIN(`date`)              AS first_event,
       MAX(`date`)              AS most_recent_event
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY company
HAVING COUNT(DISTINCT `date`) > 1
ORDER BY num_layoff_events DESC, total_laid_off_all_rounds DESC
LIMIT 15;


-- CONTEXT:
-- We identify the locations with the highest total number
-- of employees laid off and include the corresponding country.
SELECT location, country, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY location, country
ORDER BY total_laid_off DESC
LIMIT 10;


-- CONTEXT:
-- We compare total layoffs across selected countries within
-- each industry. This shows how layoffs are distributed across
-- these countries by industry.
SELECT industry,
       SUM(CASE WHEN country = 'United States' THEN total_laid_off ELSE 0 END) AS united_states,
       SUM(CASE WHEN country = 'India'         THEN total_laid_off ELSE 0 END) AS india,
       SUM(CASE WHEN country = 'Netherlands'   THEN total_laid_off ELSE 0 END) AS netherlands,
       SUM(CASE WHEN country = 'Sweden'        THEN total_laid_off ELSE 0 END) AS sweden,
       SUM(total_laid_off) AS industry_total
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY industry
ORDER BY industry_total DESC
LIMIT 10;


-- CONTEXT:
-- We calculate the average number of employees laid off per event
-- for each year and also count the number of layoff events.
SELECT YEAR(`date`)                        AS `year`,
       ROUND(AVG(total_laid_off), 1)       AS avg_event_size,
       COUNT(*)                            AS num_events
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
  AND `date` IS NOT NULL
GROUP BY YEAR(`date`)
ORDER BY `year`;


-- CONTEXT:
-- We first calculate the total layoffs for each company.
-- Then we rank the companies by their total layoffs, calculate
-- a running total, and determine what percentage of all recorded
-- layoffs has been accumulated as we move through the ranking.
WITH company_totals AS (
    SELECT company, SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    WHERE total_laid_off IS NOT NULL
    GROUP BY company
),
ranked AS (
    SELECT company,
           total_laid_off,
           RANK() OVER (ORDER BY total_laid_off DESC) AS rnk,
           SUM(total_laid_off) OVER (ORDER BY total_laid_off DESC) AS running_total,
           SUM(total_laid_off) OVER ()                              AS grand_total
    FROM company_totals
)
SELECT company,
       total_laid_off,
       rnk,
       ROUND(running_total / grand_total * 100, 1) AS cumulative_pct
FROM ranked
WHERE rnk <= 20
ORDER BY rnk;