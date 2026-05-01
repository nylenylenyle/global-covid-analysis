# Global COVID-19 Burden and Health System Readiness Analysis

## Overview

This project analyzes global COVID-19 data to evaluate how disease burden, testing coverage, and vaccination rollout vary across countries and over time. The objective is to transform raw public health data into actionable insights that reflect differences in pandemic impact and healthcare system readiness.

This analysis follows a healthcare analytics workflow, including data validation, feature engineering, trend analysis, and creation of dashboard-ready datasets for stakeholder use.

---

## Data Source

Data is sourced from Our World in Data and reflects real-world COVID-19 reporting across countries.

Datasets used:

- COVID-19 deaths dataset  
- COVID-19 vaccinations dataset  

These datasets provide country-level daily metrics including cases, deaths, testing activity, vaccination data, and demographic indicators.

---

## Data Structure & Initial Checks

The database consists of two primary tables: `covid_deaths` and `covid_vaccinations`, joined on `iso_code` and `date`.

The dataset operates at a country-day granularity, where each row represents a single country on a specific reporting date.

---

### Table: covid_deaths

| Column Name        | Data Type | Description |
|-------------------|----------|------------|
| iso_code          | VARCHAR  | Unique country identifier |
| location          | VARCHAR  | Country name |
| date              | DATE     | Reporting date |
| population        | NUMERIC  | Total population |
| total_cases       | NUMERIC  | Cumulative confirmed cases |
| new_cases         | NUMERIC  | Daily new cases |
| total_deaths      | NUMERIC  | Cumulative deaths |
| new_deaths        | NUMERIC  | Daily new deaths |
| reproduction_rate | NUMERIC  | Estimated transmission rate |
| icu_patients      | NUMERIC  | Number of ICU patients |
| hosp_patients     | NUMERIC  | Number of hospitalized patients |

---

### Table: covid_vaccinations

| Column Name                 | Data Type | Description |
|----------------------------|----------|------------|
| iso_code                   | VARCHAR  | Unique country identifier |
| location                   | VARCHAR  | Country name |
| date                       | DATE     | Reporting date |
| total_tests                | NUMERIC  | Total tests conducted |
| new_tests                  | NUMERIC  | Daily new tests |
| positive_rate              | NUMERIC  | Share of tests that are positive |
| tests_per_case             | NUMERIC  | Tests conducted per confirmed case |
| total_vaccinations         | NUMERIC  | Total vaccine doses administered |
| people_vaccinated          | NUMERIC  | Individuals with at least one dose |
| people_fully_vaccinated    | NUMERIC  | Individuals fully vaccinated |
| new_vaccinations           | NUMERIC  | Daily vaccinations administered |
| stringency_index           | NUMERIC  | Government response strictness |
| hospital_beds_per_thousand | NUMERIC  | Healthcare capacity indicator |
| median_age                 | NUMERIC  | Median population age |
| population_density         | NUMERIC  | Population density |
| gdp_per_capita             | NUMERIC  | Economic indicator |
| life_expectancy            | NUMERIC  | Average life expectancy |

---

### Data Relationships

- Primary join keys:
  - `iso_code`
  - `date`

- Relationship type:
  - One-to-one at the country-date level (validated during data checks)

---

### Initial Data Checks

Before analysis, the following validations were performed:

- Verified uniqueness of `(iso_code, date)` in both tables  
- Assessed join completeness between deaths and vaccination datasets  
- Profiled missing values across key analytical fields  
- Evaluated inconsistencies in testing and vaccination reporting  

These checks ensured the dataset was reliable and suitable for downstream analysis.

---

## Executive Summary

Global COVID-19 outcomes vary significantly across countries, driven by differences in testing coverage, population demographics, and vaccination rollout. Countries with broader testing tend to exhibit lower positivity rates, suggesting more comprehensive detection of infections. Higher mortality rates are concentrated in countries with older populations and lower vaccination coverage.

Vaccination rollout speed and completeness are strongly associated with improved outcomes in later periods, while inconsistent testing and reporting create challenges in accurately comparing countries. These findings highlight the importance of testing infrastructure, demographic risk factors, and timely vaccination efforts in managing public health crises.

---

## Key Analyses

The project includes the following analytical components:

- Country-level burden snapshots using latest available data  
- Mortality ranking within continents  
- Monthly trends and running totals for cases and deaths  
- Testing coverage and positivity analysis  
- Vaccination rollout tracking and milestone identification  
- Outlier detection using percentile-based methods  
- Risk segmentation combining mortality, vaccination, and positivity metrics  

---

## Key Findings

- Countries with higher testing coverage generally show lower positivity rates, indicating more complete case detection and surveillance  
- High positivity rates are often observed in countries with limited testing capacity, suggesting underreporting of true case counts  
- Higher median age populations are associated with significantly higher deaths per million, reflecting increased vulnerability to severe outcomes  
- Vaccination rollout varies widely across countries, with faster rollout associated with reduced mortality in later stages of the pandemic  
- Some countries exhibit extreme values (outliers) in deaths per million, driven by combinations of demographic risk, healthcare capacity, and reporting differences  
- Testing, vaccination, and mortality metrics interact to shape overall pandemic outcomes  

---

## Recommendations

- Expand testing capacity in regions with high positivity rates to improve visibility into true infection levels  
- Prioritize vaccination efforts in countries with older populations and higher mortality risk  
- Use testing and positivity metrics together when evaluating country performance, rather than relying on case counts alone  
- Investigate outlier countries to identify structural factors driving extreme outcomes  
- Promote standardized reporting practices to improve cross-country comparability  

---

## Data Validation

Data quality checks were performed prior to analysis, including:

- Duplicate detection at the country-date level  
- Join key validation between deaths and vaccination tables  
- Missing value profiling across key variables  
- Validation of numeric ranges and consistency  

Missing data was handled contextually:

- COALESCE used in aggregations where appropriate  
- Null values preserved or filtered in comparative analyses to avoid misleading results  

---

## Feature Engineering

Key derived metrics include:

- Cases per million  
- Deaths per million  
- Case fatality percentage  
- Vaccination coverage (% of population)  
- Tests per thousand  

Additional categorical groupings:

- Age profile (younger, mid-age, older populations)  
- Healthcare capacity (based on hospital beds per thousand)  

---

## Tools and Skills Demonstrated

- PostgreSQL (data modeling and querying)  
- SQL (CTEs, window functions, aggregations, feature engineering)  
- DBeaver (SQL development and query execution environment)  
- Data validation and quality checks  
- Healthcare data analysis and interpretation  
- Tableau (dashboard development)  

---

## Limitations and Assumptions

- COVID-19 reporting varies significantly across countries, particularly for testing and vaccination data  
- Missing values may reflect reporting gaps rather than true absence of activity  
- Daily reporting inconsistencies may affect trend accuracy  
- Aggregations assume missing data does not systematically bias results  

---

## How to Run

1. Execute scripts in order from 00 through 05  
2. Update file paths in `02_load_data.sql` to match your local environment  
3. Ensure CSV files are accessible to PostgreSQL  
4. Connect a BI tool (e.g., Tableau) to the generated views  

---

## Project Goal

This project demonstrates an end-to-end SQL-based data analysis workflow applied to real-world healthcare data. The goal is to generate structured, interpretable insights that support understanding of global health patterns and inform data-driven decision-making.
