/*
Create two empty source tables.
*/

DROP TABLE IF EXISTS covid_deaths;

CREATE TABLE covid_deaths (
    iso_code                           VARCHAR(10),
    continent                          VARCHAR(50),
    location                           VARCHAR(100),
    date                               DATE,
    population                         NUMERIC(20,3),
    total_cases                        NUMERIC(20,3),
    new_cases                          NUMERIC(20,3),
    new_cases_smoothed                 NUMERIC(20,3),
    total_deaths                       NUMERIC(20,3),
    new_deaths                         NUMERIC(20,3),
    new_deaths_smoothed                NUMERIC(20,3),
    total_cases_per_million            NUMERIC(20,6),
    new_cases_per_million              NUMERIC(20,6),
    new_cases_smoothed_per_million     NUMERIC(20,6),
    total_deaths_per_million           NUMERIC(20,6),
    new_deaths_per_million             NUMERIC(20,6),
    new_deaths_smoothed_per_million    NUMERIC(20,6),
    reproduction_rate                  NUMERIC(20,6),
    icu_patients                       NUMERIC(20,3),
    icu_patients_per_million           NUMERIC(20,6),
    hosp_patients                      NUMERIC(20,3),
    hosp_patients_per_million          NUMERIC(20,6),
    weekly_icu_admissions              NUMERIC(20,3),
    weekly_icu_admissions_per_million  NUMERIC(20,6),
    weekly_hosp_admissions             NUMERIC(20,3),
    weekly_hosp_admissions_per_million NUMERIC(20,6)
);

DROP TABLE IF EXISTS covid_vaccinations;

CREATE TABLE covid_vaccinations (
    iso_code                                 VARCHAR(10),
    continent                                VARCHAR(50),
    location                                 VARCHAR(100),
    date                                     DATE,
    new_tests                                NUMERIC(20,3),
    total_tests                              NUMERIC(20,3),
    total_tests_per_thousand                 NUMERIC(20,6),
    new_tests_per_thousand                   NUMERIC(20,6),
    new_tests_smoothed                       NUMERIC(20,3),
    new_tests_smoothed_per_thousand          NUMERIC(20,6),
    positive_rate                            NUMERIC(20,6),
    tests_per_case                           NUMERIC(20,6),
    tests_units                              VARCHAR(100),
    total_vaccinations                       NUMERIC(20,3),
    people_vaccinated                        NUMERIC(20,3),
    people_fully_vaccinated                  NUMERIC(20,3),
    new_vaccinations                         NUMERIC(20,3),
    new_vaccinations_smoothed                NUMERIC(20,3),
    total_vaccinations_per_hundred           NUMERIC(20,6),
    people_vaccinated_per_hundred            NUMERIC(20,6),
    people_fully_vaccinated_per_hundred      NUMERIC(20,6),
    new_vaccinations_smoothed_per_million    NUMERIC(20,6),
    stringency_index                         NUMERIC(20,6),
    population_density                       NUMERIC(20,6),
    median_age                               NUMERIC(20,6),
    aged_65_older                            NUMERIC(20,6),
    aged_70_older                            NUMERIC(20,6),
    gdp_per_capita                           NUMERIC(20,6),
    extreme_poverty                          NUMERIC(20,6),
    cardiovasc_death_rate                    NUMERIC(20,6),
    diabetes_prevalence                      NUMERIC(20,6),
    female_smokers                           NUMERIC(20,6),
    male_smokers                             NUMERIC(20,6),
    handwashing_facilities                   NUMERIC(20,6),
    hospital_beds_per_thousand               NUMERIC(20,6),
    life_expectancy                          NUMERIC(20,6),
    human_development_index                  NUMERIC(20,6)
);

COMMENT ON TABLE covid_deaths IS
'Daily country-level COVID cases, deaths, and hospital burden metrics.';

COMMENT ON TABLE covid_vaccinations IS
'Daily country-level COVID testing, vaccination, policy, and demographic context metrics.';