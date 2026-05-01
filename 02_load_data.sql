/*
Load the source CSV files into the raw tables created in 01.

Before running:
1. Confirm that 01_create_tables.sql has already been executed
2. Update the file paths below to match yours
3. Run this script while connected to coviddb created in 00_init_database.sql
*/

-- Load covid deaths data 

TRUNCATE TABLE covid_deaths;

COPY covid_deaths
FROM 'path/to/CovidDeaths.csv'
WITH (
    FORMAT csv,
    HEADER true
);

-- Load covid vaccinations data

TRUNCATE TABLE covid_vaccinations;

COPY covid_vaccinations
FROM 'path/to/CovidVaccinations.csv'
WITH (
    FORMAT csv,
    HEADER true
);