/*
Validate row counts, grain, join integrity, duplicates, missingness,
and suspicious values before analysis begins.
*/

-- Row counts
SELECT COUNT(*) covid_deaths_row_count
FROM covid_deaths;

SELECT COUNT(*) covid_vaccinations_row_count
FROM covid_vaccinations;

-- Join key coverage: distinct countries and reporting dates
SELECT
    COUNT(DISTINCT iso_code) distinct_iso_codes,
    COUNT(DISTINCT location) distinct_locations,
    COUNT(DISTINCT date) distinct_dates
FROM covid_deaths;

SELECT
    COUNT(DISTINCT iso_code) distinct_iso_codes,
    COUNT(DISTINCT location) distinct_locations,
    COUNT(DISTINCT date) distinct_dates
FROM covid_vaccinations;

-- Duplicate check at expected grain (iso_code + date)
SELECT
    iso_code,
    date,
    COUNT(*) duplicate_count
FROM covid_deaths
GROUP BY iso_code, date
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, iso_code, date;

SELECT
    iso_code,
    date,
    COUNT(*) duplicate_count
FROM covid_vaccinations
GROUP BY iso_code, date
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, iso_code, date;

-- Join integrity: matched rows across both source tables
SELECT COUNT(*) matched_country_date_rows
FROM covid_deaths d
JOIN covid_vaccinations v
  ON d.iso_code = v.iso_code
 AND d.date = v.date;

-- Unmatched rows: deaths without vaccination match
SELECT COUNT(*) deaths_rows_without_vax_match
FROM covid_deaths d
LEFT JOIN covid_vaccinations v
  ON d.iso_code = v.iso_code
 AND d.date = v.date
WHERE v.iso_code IS NULL;

-- Unmatched rows: vaccinations without deaths match
SELECT COUNT(*) vax_rows_without_deaths_match
FROM covid_vaccinations v
LEFT JOIN covid_deaths d
  ON d.iso_code = v.iso_code
 AND d.date = v.date
WHERE d.iso_code IS NULL;

-- Null profiling: deaths table
SELECT
    COUNT(*) total_rows,
    SUM(CASE WHEN total_cases IS NULL THEN 1 ELSE 0 END) null_total_cases,
    SUM(CASE WHEN total_deaths IS NULL THEN 1 ELSE 0 END) null_total_deaths,
    SUM(CASE WHEN population IS NULL THEN 1 ELSE 0 END) null_population,
    ROUND(100.0 * SUM(CASE WHEN total_cases IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) pct_null_total_cases,
    ROUND(100.0 * SUM(CASE WHEN total_deaths IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) pct_null_total_deaths,
	ROUND(100.0 * SUM(CASE WHEN population IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) pct_null_population
FROM covid_deaths;

-- Null profiling: vaccinations table
SELECT
    COUNT(*) total_rows,
    SUM(CASE WHEN new_vaccinations IS NULL THEN 1 ELSE 0 END) null_new_vaccinations,
    SUM(CASE WHEN positive_rate IS NULL THEN 1 ELSE 0 END) null_positive_rate,
    SUM(CASE WHEN stringency_index IS NULL THEN 1 ELSE 0 END) null_stringency_index,
    SUM(CASE WHEN hospital_beds_per_thousand IS NULL THEN 1 ELSE 0 END) null_hospital_beds,
    ROUND(100.0 * SUM(CASE WHEN new_vaccinations IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) pct_null_new_vaccinations,
    ROUND(100.0 * SUM(CASE WHEN positive_rate IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) pct_null_positive_rate
FROM covid_vaccinations;

-- Impossible or suspicious values: deaths
SELECT *
FROM covid_deaths
WHERE population <= 0
   OR total_cases < 0
   OR new_cases < 0
   OR total_deaths < 0
   OR new_deaths < 0;

-- Impossible or suspicious values: vaccinations
SELECT *
FROM covid_vaccinations
WHERE positive_rate < 0
   OR positive_rate > 1
   OR total_tests < 0
   OR total_vaccinations < 0
   OR people_vaccinated < 0
   OR people_fully_vaccinated < 0
   OR new_vaccinations < 0;

-- Reconciliation check: summed daily cases and deaths vs. latest cumulative totals
WITH country_filtered AS (
    SELECT
        location,
        date,
        total_cases,
        total_deaths,
        new_cases,
        new_deaths
    FROM covid_deaths
    WHERE location IN (
        'France',
        'United States',
        'Canada',
        'Japan',
        'China',
        'South Korea',
        'India',
        'Pakistan'
    )
      AND continent IS NOT NULL
),

latest_totals AS (
    SELECT
        location,
        date latest_record_date,
        total_cases total_cases_latest,
        total_deaths total_deaths_latest,
        ROW_NUMBER() OVER (
            PARTITION BY location
            ORDER BY
                CASE
                    WHEN total_cases IS NULL OR total_deaths IS NULL THEN 1
                    ELSE 0
                END,
                date DESC
        ) rn
    FROM country_filtered
),

summed_daily_values AS (
    SELECT
        location,
        SUM(COALESCE(new_cases, 0)) summed_new_cases,
        SUM(COALESCE(new_deaths, 0)) summed_new_deaths
    FROM country_filtered
    GROUP BY location
)

SELECT
    l.location country,
    l.latest_record_date,
    l.total_cases_latest,
    s.summed_new_cases,
    l.total_deaths_latest,
    s.summed_new_deaths,
    l.total_cases_latest - s.summed_new_cases cases_difference,
    l.total_deaths_latest - s.summed_new_deaths deaths_difference
FROM latest_totals l
JOIN summed_daily_values s
  ON l.location = s.location
WHERE l.rn = 1
ORDER BY 
	cases_difference DESC, 
	deaths_difference DESC;

-- Recomputed vs provided metric
SELECT
    location,
    date,
    total_cases,
    population,
    total_cases_per_million,
    ROUND(total_cases * 1000000.0 / NULLIF(population, 0), 3) recomputed_cases_per_million
FROM covid_deaths
WHERE continent IS NOT NULL
  AND total_cases IS NOT NULL
  AND population IS NOT NULL
LIMIT 50;