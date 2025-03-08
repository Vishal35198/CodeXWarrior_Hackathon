# Hackathon-CodeXWarrior

# README

## Project Overview

This project focuses on processing and correcting SQL queries using a Natural Language Processing (NLP) model. It extracts schema information from SQL files, generates SQL queries from natural language descriptions, and corrects incorrect SQL queries.

## Approach

The approach taken in this project follows these key steps:

1. **Loading Input Data**

   - Read natural language queries (NL) and incorrect SQL queries from JSON files.

2. **Extracting Schema Information**

   - Parse SQL files to extract table and column definitions.
   - Generate a structured schema description for reference during query generation and correction.

3. **Generating SQL Queries**

   - Utilize an NLP model (Grok API) to convert NL queries into structured SQL statements.
   - Provide the extracted schema information to improve accuracy.

4. **Correcting SQL Queries**

   - Pass incorrect SQL queries to the NLP model for correction.
   - Ensure corrections align with the database schema.

5. **API Integration**

   - Use Grok's API to interact with a large language model (LLM).
   - Send structured prompts and parse responses to extract SQL queries.

6. **Storing Results**
   - Save the generated SQL queries and corrected queries into JSON output files.

## Tech Stack

- **Programming Language:** Python
- **Libraries Used:**
  - `json` (for data handling)
  - `requests` (for API calls)
  - `sqlparse` (for SQL parsing)
  - `re` (for regex-based SQL query cleanup)
  - `os` (for file handling)
  - `time` (for performance measurement)
- **Database:** PostgreSQL (Schema Extraction & Validation)
- **LLM Model:** Grok API (via `requests` library)

## File Structure

- `main.py`: Main script containing data processing logic
- `data.json`: Input file containing natural language queries
- `correction.json`: Input file containing incorrect SQL queries
- `hackathon_database_iitd.sql`: SQL schema file for reference
- `output_sql_generation_task.json`: Output file for generated SQL queries
- `output_sql_correction_task.json`: Output file for corrected SQL queries
- `README.md`: Project documentation

## Execution Steps

1. Ensure Python is installed.
2. Install necessary dependencies using `pip install -r requirements.txt` (if applicable).
3. Run `python main.py` to execute the script.
4. The output JSON files will contain the generated and corrected SQL queries.

## Future Improvements

- Improve schema extraction logic to handle complex constraints.
- Optimize API token usage to reduce computational costs.
- Extend support for additional database management systems (e.g., MySQL, SQLite).

## Flow Chart

[See the flow chart](https://lucid.app/lucidchart/3e4dbbb1-3540-46d5-81cc-5ce772aaf8c0/view?page=0_0&invitationId=inv_80e9c9f9-98a0-4617-ab09-6246003d6aed#)
