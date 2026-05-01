/*
Create the project database.
These scripts needs to be run separately because CREATE DATABASE cannot be run inside a transaction block.
*/

DROP DATABASE IF EXISTS coviddb;
CREATE DATABASE coviddb;