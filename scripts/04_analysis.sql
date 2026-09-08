/*
Analyze COVID burden, vaccination rollout, testing coverage, distributions,
outliers, and country-level risk patterns using joined daily data.
*/

-- Join deaths and vaccinations tables to form a reusable CTE for later analysis
WITH joined_base AS (
    SELECT
        d.iso_code,
        d.continent,
        d.location,
        d.date report_date,
        d.population,
        d.total_cases,
        d.new_cases,
        d.total_deaths,
        d.new_deaths,
        d.reproduction_rate,
        d.icu_patients,
        d.hosp_patients,
        v.total_tests,
        v.new_tests,
        v.positive_rate,
        v.tests_per_case,
        v.total_vaccinations,
        v.people_vaccinated,
        v.people_fully_vaccinated,
        v.new_vaccinations,
        v.stringency_index,
        v.population_density,
        v.median_age,
        v.aged_65_older,
        v.gdp_per_capita,
        v.diabetes_prevalence,
        v.hospital_beds_per_thousand,
        v.life_expectancy
    FROM covid_deaths d
    LEFT JOIN covid_vaccinations v
      ON d.iso_code = v.iso_code
     AND d.date = v.date
    WHERE d.continent IS NOT NULL
)
SELECT *
FROM joined_base;

-- Feature engineering (calculations and categorical grouping)
WITH joined_base AS (
    SELECT
        d.iso_code,
        d.continent,
        d.location,
        d.date report_date,
        d.population,
        d.total_cases,
        d.new_cases,
        d.total_deaths,
        d.new_deaths,
        v.total_tests,
        v.positive_rate,
        v.total_vaccinations,
        v.people_vaccinated,
        v.people_fully_vaccinated,
        v.new_vaccinations,
        v.stringency_index,
        v.median_age,
        v.aged_65_older,
        v.diabetes_prevalence,
        v.hospital_beds_per_thousand
    FROM covid_deaths d
    LEFT JOIN covid_vaccinations v
      ON d.iso_code = v.iso_code
     AND d.date = v.date
    WHERE d.continent IS NOT NULL
),
featured AS (
    SELECT
        *,
        ROUND(total_cases * 1000000.0 / NULLIF(population, 0), 2) cases_per_million_calc,
        ROUND(total_deaths * 1000000.0 / NULLIF(population, 0), 2) deaths_per_million_calc,
        ROUND(total_deaths * 100.0 / NULLIF(total_cases, 0), 4) case_fatality_pct,
        ROUND(people_vaccinated * 100.0 / NULLIF(population, 0), 2) people_vaccinated_pct,
        ROUND(people_fully_vaccinated * 100.0 / NULLIF(population, 0), 2) people_fully_vaccinated_pct,
        ROUND(total_tests * 1000.0 / NULLIF(population, 0), 2) tests_per_thousand_calc,
        CASE
            WHEN median_age >= 40 THEN 'Older population'
            WHEN median_age >= 30 THEN 'Mid-age population'
            ELSE 'Younger population'
        END age_profile,
        CASE
            WHEN hospital_beds_per_thousand >= 5 THEN 'High bed capacity'
            WHEN hospital_beds_per_thousand >= 2 THEN 'Moderate bed capacity'
            ELSE 'Low bed capacity'
        END bed_capacity_group
    FROM joined_base
)
SELECT *
FROM featured;

-- Country-level burden snapshot
WITH country_latest AS (
    SELECT
        d.location,
        d.continent,
        d.population,
        d.total_cases,
        d.total_deaths,
        ROW_NUMBER() OVER (
            PARTITION BY d.location
            ORDER BY d.date DESC
        ) rn
    FROM covid_deaths d
    WHERE d.continent IS NOT NULL
)
SELECT
    location,
    continent,
    population,
    total_cases,
    total_deaths,
    ROUND(total_cases * 1000000.0 / NULLIF(population, 0), 2) cases_per_million,
    ROUND(total_deaths * 1000000.0 / NULLIF(population, 0), 2) deaths_per_million,
    ROUND(total_deaths * 100.0 / NULLIF(total_cases, 0), 4) case_fatality_pct
FROM country_latest
WHERE rn = 1
ORDER BY deaths_per_million DESC NULLS LAST;

-- Mortality rank within continent
WITH country_latest AS (
    SELECT
        d.location,
        d.continent,
        d.population,
        d.total_deaths,
        ROW_NUMBER() OVER (
            PARTITION BY d.location
            ORDER BY d.date DESC
        ) rn
    FROM covid_deaths d
    WHERE d.continent IS NOT NULL
)
SELECT
    continent,
	location,
    ROUND(total_deaths * 1000000.0 / NULLIF(population, 0), 2) deaths_per_million,
    RANK() OVER (
        PARTITION BY continent
        ORDER BY total_deaths * 1000000.0 / NULLIF(population, 0) DESC NULLS LAST
    ) mortality_rank_within_continent
FROM country_latest
WHERE rn = 1
ORDER BY continent, mortality_rank_within_continent;

-- Monthly trends and running totals
WITH monthly_country AS (
    SELECT
        iso_code,
        location,
        continent,
        DATE_TRUNC('month', date)::date month_start,
        SUM(COALESCE(new_cases, 0)) monthly_new_cases,
        SUM(COALESCE(new_deaths, 0)) monthly_new_deaths
    FROM covid_deaths
    WHERE continent IS NOT NULL
    GROUP BY iso_code, location, continent, DATE_TRUNC('month', date)::date
),
monthly_with_windows AS (
    SELECT
        *,
        SUM(monthly_new_cases) OVER (
            PARTITION BY iso_code
            ORDER BY month_start
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) running_cases,
        SUM(monthly_new_deaths) OVER (
            PARTITION BY iso_code
            ORDER BY month_start
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) running_deaths,
        LAG(monthly_new_cases) OVER (
            PARTITION BY iso_code
            ORDER BY month_start
        ) prior_month_cases
    FROM monthly_country
)
SELECT
    iso_code,
    location,
    month_start,
    monthly_new_cases,
    monthly_new_deaths,
    running_cases,
    running_deaths,
    prior_month_cases,
    ROUND(
        (monthly_new_cases - prior_month_cases) * 100.0 / NULLIF(prior_month_cases, 0),
        2
    ) pct_change_vs_prior_month
FROM monthly_with_windows
ORDER BY location, month_start;

-- Global monthly totals
SELECT
    DATE_TRUNC('month', date)::date month_start,
    SUM(COALESCE(new_cases, 0)) global_monthly_new_cases,
    SUM(COALESCE(new_deaths, 0)) global_monthly_new_deaths
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY DATE_TRUNC('month', date)::date
ORDER BY month_start;

-- Testing coverage and positivity
WITH country_latest AS (
    SELECT
        v.location,
        v.continent,
        v.total_tests,
        v.positive_rate,
        v.tests_per_case,
        ROW_NUMBER() OVER (
            PARTITION BY v.location
            ORDER BY
				CASE
        			WHEN v.total_tests IS NOT NULL
         			 AND v.positive_rate IS NOT NULL
         			 AND v.tests_per_case IS NOT NULL
            			THEN 0
        			ELSE 1
    			END,
    			v.date DESC
        ) rn
    FROM covid_vaccinations v
    WHERE v.continent IS NOT NULL
)
SELECT
    location,
    continent,
    total_tests,
    positive_rate,
    tests_per_case
FROM country_latest
WHERE rn = 1
  AND total_tests IS NOT NULL
  AND positive_rate IS NOT NULL
  AND tests_per_case IS NOT NULL
ORDER BY positive_rate DESC NULLS LAST;

-- Average positivity by country
WITH country_avg_pos AS (
    SELECT
        location,
        continent,
        AVG(positive_rate) avg_positive_rate
    FROM covid_vaccinations
    WHERE continent IS NOT NULL
      AND positive_rate IS NOT NULL
    GROUP BY location, continent
)
SELECT
    location,
    continent,
    ROUND(avg_positive_rate, 4) avg_positive_rate,
    CASE
        WHEN avg_positive_rate >= 0.20 THEN 'Very high positivity'
        WHEN avg_positive_rate >= 0.10 THEN 'High positivity'
        WHEN avg_positive_rate >= 0.05 THEN 'Moderate positivity'
        ELSE 'Lower positivity'
    END positivity_risk_group
FROM country_avg_pos
ORDER BY continent, avg_positive_rate DESC;

-- Median positive rate by continent
WITH country_latest AS (
    SELECT
        v.location,
        v.continent,
        v.positive_rate,
        ROW_NUMBER() OVER (
            PARTITION BY v.location
            ORDER BY v.date DESC
        ) rn
    FROM covid_vaccinations v
    WHERE v.continent IS NOT NULL
      AND v.positive_rate IS NOT NULL
),
latest_snapshot AS (
    SELECT
        location,
        continent,
        positive_rate
    FROM country_latest
    WHERE rn = 1
)
SELECT
    continent,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY positive_rate)::numeric,
        4
    ) median_positive_rate
FROM latest_snapshot
GROUP BY continent
ORDER BY continent;

-- Vaccination rollout
WITH vax_base AS (
    SELECT
        d.iso_code,
        d.location,
        d.continent,
        d.date report_date,
        d.population,
        COALESCE(v.new_vaccinations, 0) new_vaccinations
    FROM covid_deaths d
    JOIN covid_vaccinations v
      ON d.iso_code = v.iso_code
     AND d.date = v.date
    WHERE d.continent IS NOT NULL
),
rolling_vax AS (
    SELECT
        *,
        SUM(new_vaccinations) OVER (
            PARTITION BY iso_code
            ORDER BY report_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) rolling_total_vaccinations
    FROM vax_base
)
SELECT
    iso_code,
    location,
    continent,
    report_date,
    population,
    new_vaccinations,
    rolling_total_vaccinations,
    ROUND(rolling_total_vaccinations * 100.0 / NULLIF(population, 0), 2) rolling_vax_pct
FROM rolling_vax
ORDER BY location, report_date;

-- Vaccination milestone dates
WITH vax_base AS (
    SELECT
        d.iso_code,
        d.location,
        d.continent,
        d.date report_date,
        d.population,
        COALESCE(v.new_vaccinations, 0) new_vaccinations
    FROM covid_deaths d
    JOIN covid_vaccinations v
      ON d.iso_code = v.iso_code
     AND d.date = v.date
    WHERE d.continent IS NOT NULL
),
rolling_vax AS (
    SELECT
        *,
        SUM(new_vaccinations) OVER (
            PARTITION BY iso_code
            ORDER BY report_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) rolling_total_vaccinations
    FROM vax_base
)
SELECT
    iso_code,
    location,
    MIN(CASE WHEN rolling_total_vaccinations * 100.0 / NULLIF(population, 0) >= 10 THEN report_date END) date_10_pct,
    MIN(CASE WHEN rolling_total_vaccinations * 100.0 / NULLIF(population, 0) >= 50 THEN report_date END) date_50_pct,
    MIN(CASE WHEN rolling_total_vaccinations * 100.0 / NULLIF(population, 0) >= 70 THEN report_date END) date_70_pct
FROM rolling_vax
GROUP BY iso_code, location
ORDER BY date_50_pct NULLS LAST, date_70_pct NULLS LAST;

-- Vaccination and mortality comparison
WITH country_latest AS (
    SELECT
        d.location,
        d.continent,
        d.population,
        d.total_deaths,
        v.people_fully_vaccinated,
        ROW_NUMBER() OVER (
            PARTITION BY d.location
            ORDER BY d.date DESC
        ) rn
    FROM covid_deaths d
    LEFT JOIN covid_vaccinations v
      ON d.iso_code = v.iso_code
     AND d.date = v.date
    WHERE d.continent IS NOT NULL
),
latest_snapshot AS (
    SELECT
        location,
        continent,
        ROUND(total_deaths * 1000000.0 / NULLIF(population, 0), 2) deaths_per_million,
        ROUND(people_fully_vaccinated * 100.0 / NULLIF(population, 0), 2) fully_vaccinated_pct
    FROM country_latest
    WHERE rn = 1
)
SELECT
    location,
    continent,
    deaths_per_million,
    fully_vaccinated_pct,
    CASE
        WHEN COALESCE(fully_vaccinated_pct, 0) >= 70 THEN '70%+ vaccinated'
        WHEN COALESCE(fully_vaccinated_pct, 0) >= 50 THEN '50-69% vaccinated'
        WHEN COALESCE(fully_vaccinated_pct, 0) >= 10 THEN '10-49% vaccinated'
        ELSE '<10% vaccinated'
    END vaccination_group
FROM latest_snapshot
ORDER BY fully_vaccinated_pct DESC NULLS LAST, deaths_per_million DESC;

-- Medians and distributions
WITH country_latest AS (
    SELECT
        d.location,
        d.continent,
        d.population,
        d.total_cases,
        d.total_deaths,
        v.people_fully_vaccinated,
        v.positive_rate,
        ROW_NUMBER() OVER (
            PARTITION BY d.location
            ORDER BY d.date DESC
        ) rn
    FROM covid_deaths d
    LEFT JOIN covid_vaccinations v
      ON d.iso_code = v.iso_code
     AND d.date = v.date
    WHERE d.continent IS NOT NULL
),
latest_snapshot AS (
    SELECT
        location,
        continent,
        ROUND(total_cases * 1000000.0 / NULLIF(population, 0), 2) cases_per_million,
        ROUND(total_deaths * 1000000.0 / NULLIF(population, 0), 2) deaths_per_million,
        ROUND(people_fully_vaccinated * 100.0 / NULLIF(population, 0), 2) fully_vaccinated_pct,
        positive_rate
    FROM country_latest
    WHERE rn = 1
)
SELECT
    continent,
    ROUND(AVG(deaths_per_million), 2) mean_deaths_per_million,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY deaths_per_million)::numeric,
        2
    ) median_deaths_per_million
FROM latest_snapshot
GROUP BY continent
ORDER BY continent;

-- Distribution bands for deaths per million
WITH country_latest AS (
    SELECT
        d.location,
        d.continent,
        d.population,
        d.total_deaths,
        ROW_NUMBER() OVER (
            PARTITION BY d.location
            ORDER BY d.date DESC
        ) rn
    FROM covid_deaths d
    WHERE d.continent IS NOT NULL
),
latest_snapshot AS (
    SELECT
        location,
        continent,
        ROUND(total_deaths * 1000000.0 / NULLIF(population, 0), 2) deaths_per_million
    FROM country_latest
    WHERE rn = 1
)
SELECT
    CASE
        WHEN deaths_per_million < 500 THEN '<500'
        WHEN deaths_per_million < 1000 THEN '500-999'
        WHEN deaths_per_million < 2000 THEN '1000-1999'
        WHEN deaths_per_million < 3000 THEN '2000-2999'
        ELSE '3000+'
    END deaths_per_million_band,
    COUNT(*) country_count
FROM latest_snapshot
GROUP BY 1
ORDER BY country_count DESC;

-- Outlier detection
WITH country_latest AS (
    SELECT
        d.location,
        d.continent,
        d.population,
        d.total_deaths,
        ROW_NUMBER() OVER (
            PARTITION BY d.location
            ORDER BY d.date DESC
        ) rn
    FROM covid_deaths d
    WHERE d.continent IS NOT NULL
),
latest_snapshot AS (
    SELECT
        location,
        continent,
        ROUND(total_deaths * 1000000.0 / NULLIF(population, 0), 2) deaths_per_million
    FROM country_latest
    WHERE rn = 1
),
ranked AS (
    SELECT
        *,
        NTILE(100) OVER (ORDER BY deaths_per_million DESC) outlier_percentile
    FROM latest_snapshot
)
SELECT
    location,
    continent,
    deaths_per_million,
    outlier_percentile
FROM ranked
WHERE outlier_percentile = 1
ORDER BY deaths_per_million DESC;

-- Mean before and after removing top 1% outliers
WITH country_latest AS (
    SELECT
        d.location,
        d.continent,
        d.population,
        d.total_deaths,
        ROW_NUMBER() OVER (
            PARTITION BY d.location
            ORDER BY d.date DESC
        ) rn
    FROM covid_deaths d
    WHERE d.continent IS NOT NULL
),
latest_snapshot AS (
    SELECT
        location,
        continent,
        ROUND(total_deaths * 1000000.0 / NULLIF(population, 0), 2) deaths_per_million
    FROM country_latest
    WHERE rn = 1
),
ranked AS (
    SELECT
        *,
        NTILE(100) OVER (ORDER BY deaths_per_million DESC) outlier_percentile
    FROM latest_snapshot
)
SELECT
    'All countries' analysis_group,
    ROUND(AVG(deaths_per_million), 2) avg_deaths_per_million
FROM ranked

UNION ALL

SELECT
    'Excluding top 1% outliers' analysis_group,
    ROUND(AVG(deaths_per_million), 2) avg_deaths_per_million
FROM ranked
WHERE outlier_percentile > 1;

-- Country risk segmentation
WITH country_latest AS (
    SELECT
        d.iso_code,
        d.location,
        d.continent,
        d.population,
        d.total_deaths,
        v.people_fully_vaccinated,
        v.positive_rate,
        v.hospital_beds_per_thousand,
        v.median_age,
        ROW_NUMBER() OVER (
            PARTITION BY d.location
            ORDER BY d.date DESC
        ) rn
    FROM covid_deaths d
    LEFT JOIN covid_vaccinations v
      ON d.iso_code = v.iso_code
     AND d.date = v.date
    WHERE d.continent IS NOT NULL
),
latest_snapshot AS (
    SELECT
        iso_code,
        location,
        continent,
        ROUND(total_deaths * 1000000.0 / NULLIF(population, 0), 2) deaths_per_million,
        ROUND(people_fully_vaccinated * 100.0 / NULLIF(population, 0), 2) fully_vaccinated_pct,
        positive_rate,
        hospital_beds_per_thousand,
        median_age
    FROM country_latest
    WHERE rn = 1
),
segmented AS (
    SELECT
        *,
        CASE
            WHEN deaths_per_million >= 2000
             AND COALESCE(fully_vaccinated_pct, 0) < 50
             AND COALESCE(positive_rate, 0) >= 0.10
                THEN 'High burden / low vaccine / high positivity'
            WHEN COALESCE(fully_vaccinated_pct, 0) >= 70
             AND COALESCE(positive_rate, 0) < 0.05
                THEN 'Higher readiness / lower positivity'
            WHEN COALESCE(median_age, 0) >= 40
             AND deaths_per_million >= 1500
                THEN 'Older population / elevated mortality'
            ELSE 'Mixed profile'
        END risk_segment
    FROM latest_snapshot
)
SELECT
    location,
    continent,
    deaths_per_million,
    fully_vaccinated_pct,
    positive_rate,
    hospital_beds_per_thousand,
    median_age,
    risk_segment,
    RANK() OVER (
        PARTITION BY continent
        ORDER BY deaths_per_million DESC
    ) mortality_rank_within_continent
FROM segmented
ORDER BY continent, mortality_rank_within_continent;