# Global Layoffs Analysis (MySQL)

SQL project that cleans a global tech layoffs dataset and explores it to find which industries, countries, company stages and funding levels were hit hardest.

## Dataset
- Source: layoffs [https://github.com/AlexTheAnalyst/MySQL-YouTube-Series/blob/main/layoffs.csv]
- Rows: 7,606 (after cleaning)
- Period covered: March 11, 2020 to March 6, 2023
- Columns: company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions

## Tools
MySQL 8.0+ (window functions and CTEs are required), MySQL Workbench

## Project steps
1. **Data cleaning**
   - Created a staging table so the raw data stays untouched
   - Removed duplicates with ROW_NUMBER()
   - Trimmed company names and standardized industry and country values
   - Converted text dates to the DATE type
   - Filled missing industries using a self-join
   - Removed rows with no layoff information
2. **Exploratory analysis**
   - Layoffs by company, industry, country, year and company stage
   - Monthly layoffs with a rolling total
   - Top 5 companies per year (DENSE_RANK)
   - Severe (50%+) versus moderate layoff events per year
   - Layoffs by funding bracket
   - Companies with repeated layoffs
   - Layoffs by industry across selected countries

## Key findings
- Total layoffs recorded: 383,659 (March 2020 to March 2023).
- **Industry:** Consumer was the hardest-hit industry, with 45,182 layoffs (about 11.8% of the total).
- **Country:** The United States accounted for 256,559 layoffs, about 66.9% of the total.
- **Year:** 2023 was the peak year with 125,677 layoffs (about 32.8%), from only about two months of data (through March 6, 2023).

Note: totals use SUM, which skips rows with no layoff number.

## How to run
1. Create a database: `CREATE DATABASE world_layoffs;`
2. Import the raw CSV into a table named `layoffs` (Workbench: Table Data Import Wizard)
3. Run `sql/layoffs_cleaning_and_eda.sql` in full, top to bottom

## Repository structure
```
.
├── README.md
├── LICENSE
├── data/        (raw CSV, if the license allows sharing)
├── sql/
│   └── layoffs_cleaning_and_eda.sql
└── images/      (screenshots of key query results)
```

## Author
Adewale Henry Adetunji | [LinkedIn](https://linkedin.com/in/adewale-adetunji-4257b32b0) | henrytheanalyst.netlify.app
