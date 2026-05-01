/*
Create reusable views for Tableau or Power BI dashboards.
*/

-- Country-level latest snapshot
DROP VIEW IF EXISTS vw_country_latest_snapshot;

CREATE VIEW vw_country_latest_snapshot AS
WITH country_latest AS (
    SELECT
        d.iso_code,
        d.location,
        d.continent,
        d.population,
        d.total_cases,
        d.total_deaths,
        v.total_tests,
        v.positive_rate,
        v.people_vaccinated,
        v.people_fully_vaccinated,
        v.hospital_beds_per_thousand,
        v.median_age,
        v.stringency_index,
        ROW_NUMBER() OVER (
            PARTITION BY d.location
            ORDER BY d.date DESC
        ) rn
    FROM covid_deaths d
    LEFT JOIN covid_vaccinations v
      ON d.iso_code = v.iso_code
     AND d.date = v.date
    WHERE d.continent IS NOT NULL
)
SELECT
    iso_code,
    location,
    continent,
    population,
    total_cases,
    total_deaths,
    total_tests,
    positive_rate,
    people_vaccinated,
    people_fully_vaccinated,
    hospital_beds_per_thousand,
    median_age,
    stringency_index,
    ROUND(total_cases * 1000000.0 / NULLIF(population, 0), 2) cases_per_million,
    ROUND(total_deaths * 1000000.0 / NULLIF(population, 0), 2) deaths_per_million,
    ROUND(total_deaths * 100.0 / NULLIF(total_cases, 0), 4) case_fatality_pct,
    ROUND(people_fully_vaccinated * 100.0 / NULLIF(population, 0), 2) fully_vaccinated_pct
FROM country_latest
WHERE rn = 1;

-- Monthly country trends
DROP VIEW IF EXISTS vw_monthly_country_trends;

CREATE VIEW vw_monthly_country_trends AS
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
)
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
FROM monthly_country;

-- Vaccination progress
DROP VIEW IF EXISTS vw_vaccination_progress;

CREATE VIEW vw_vaccination_progress AS
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
)
SELECT
    *,
    SUM(new_vaccinations) OVER (
        PARTITION BY iso_code
        ORDER BY report_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) rolling_total_vaccinations,
    ROUND(
        SUM(new_vaccinations) OVER (
            PARTITION BY iso_code
            ORDER BY report_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) * 100.0 / NULLIF(population, 0),
        2
    ) rolling_vax_pct
FROM vax_base;