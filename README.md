# Global COVID-19 Burden and Health System Readiness Analysis

## Overview

This project analyzes global COVID-19 data to evaluate differences in disease burden, testing coverage, and vaccination rollout across countries.

The analysis focuses on transforming raw public health data into structured, analysis-ready outputs while accounting for data quality, missingness, and reporting inconsistencies.

---

## Data Source

Data is sourced from Our World in Data and reflects real-world COVID-19 reporting across countries.

Datasets used:
- COVID-19 deaths dataset
- COVID-19 vaccinations dataset

These datasets provide country-level daily metrics including cases, deaths, testing activity, vaccination data, and demographic indicators.

---

## Project Structure

00_init_database.sql — Create database  
01_create_tables.sql — Define schema  
02_load_data.sql — Load CSV data  
03_data_validation.sql — Validate data quality  
04_analysis.sql — Perform analysis and feature engineering  
05_dashboard_views.sql — Create views for dashboards

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

## Key Analyses

This project includes:

- Country-level burden snapshots using latest available data  
- Mortality ranking within continents  
- Monthly trends and running totals  
- Testing coverage and positivity analysis  
- Vaccination rollout tracking and milestone identification  
- Outlier detection using percentile-based methods  
- Risk segmentation combining mortality, vaccination, and positivity metrics  

---

## Key Findings

- Countries with higher testing coverage tend to exhibit lower positivity rates  
- Higher median age populations are associated with increased deaths per million  
- Vaccination rollout varies significantly across regions and correlates with reduced mortality in later periods  
- Reporting completeness varies widely across countries, particularly for testing data  

---

## Tools and Skills Demonstrated

- PostgreSQL (data modeling and querying)  
- SQL (CTEs, window functions, aggregations, feature engineering)  
- DBeaver (database management and query execution environment)
- - Data validation and quality checks  
- Healthcare data analysis and interpretation  
- Tableau (dashboard development)  

---

## How to Run

1. Run scripts in order from 00 through 05  
2. Update file paths in 02_load_data.sql to match your environment  
3. Ensure CSV files are accessible to PostgreSQL  
4. Connect a BI tool (e.g., Tableau) to the generated views  

---

## Project Goal

This project demonstrates an end-to-end SQL-based data analysis workflow applied to real-world healthcare data. The goal is to produce structured, interpretable insights that support understanding of global health patterns and system-level differences.
