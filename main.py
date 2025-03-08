# Import necessary libraries
import json
import requests
import time
import re
import os
import sqlparse

# Global variable to keep track of the total number of tokens
total_tokens = 0

# Function to load input file
def load_input_file(file_path):
    """
    Load input file which is a list of dictionaries.
    
    :param file_path: Path to the input file
    :return: List of dictionaries
    """
    with open(file_path, 'r') as file:
        data = json.load(file)
    return data

# Function to extract schema information from SQL files
def extract_sql_schema(sql_file_path):
    # Read the SQL file
    with open(sql_file_path, 'r') as file:
        sql_content = file.read()
    
    # Find CREATE TABLE statements
    create_table_pattern = r'CREATE\s+TABLE\s+[IF NOT EXISTS\s+]*`?(\w+)`?\s*\(([\s\S]*?)\);'
    tables = re.findall(create_table_pattern, sql_content, re.IGNORECASE)
    
    schema = {}
    for table_name, table_content in tables:
        # Extract column definitions
        column_pattern = r'`?(\w+)`?\s+([\w\(\)]+)(?:\s+(\w+(?:\s+\w+)*))*'
        columns = re.findall(column_pattern, table_content)
        
        table_schema = []
        for col in columns:
            col_name = col[0]
            col_type = col[1]
            col_constraints = col[2].strip() if len(col) > 2 and col[2] else ""
            
            # Skip if this is likely a constraint rather than a column
            if col_name.upper() in ["PRIMARY", "FOREIGN", "UNIQUE", "CHECK", "CONSTRAINT"]:
                continue
                
            table_schema.append({
                "name": col_name,
                "type": col_type,
                "constraints": col_constraints
            })
            
        schema[table_name] = table_schema
    
    return schema  # This return statement is missing in the original code

# Function to create schema description for the LLM
def create_schema_description(schema):
    """
    Create a detailed textual description of the database schema for use with an LLM.
    
    This function generates a structured representation of the database schema,
    including all tables and their columns with data types and constraints.
    
    Args:
        schema: Dictionary with schema information where keys are table names
               and values are lists of column dictionaries
    
    Returns:
        String with formatted schema description ready for LLM consumption
    """
    if not schema:
        return "The database schema is empty."
    
    description = "DATABASE SCHEMA\n" + "="*15 + "\n\n"
    
    for table_name, columns in schema.items():
        description += f"TABLE: {table_name}\n" + "-"*50 + "\n"
        
        if not columns:
            description += "  This table has no columns defined.\n\n"
            continue
            
        # Column header
        description += f"{'COLUMN NAME':<20} {'DATA TYPE':<20} {'CONSTRAINTS':<30}\n"
        description += f"{'-'*20:<20} {'-'*20:<20} {'-'*30:<30}\n"
        
        # Column details
        for column in columns:
            col_name = column['name']
            col_type = column['type']
            col_constraints = column['constraints'] if column['constraints'] else "None"
            
            description += f"{col_name:<20} {col_type:<20} {col_constraints:<30}\n"
        
        description += "\n"
    
    return description

# Function to clean SQL code from markdown formatting
def clean_sql_query(sql_query):
    """
    Remove markdown code block formatting from SQL query if present.
    
    :param sql_query: SQL query possibly with markdown formatting
    :return: Clean SQL query
    """
    # Remove markdown sql code block formatting if present
    sql_pattern = r"```(?:sql)?\n([\s\S]*?)\n```"
    match = re.search(sql_pattern, sql_query)
    
    if match:
        return match.group(1).strip()
    
    return sql_query.strip()

# Function to generate SQL statements
def generate_sqls(data, schema_description=""):
    """
    Generate SQL statements from the NL queries.
    
    :param data: List of NL queries
    :param schema_description: Description of the database schema
    :return: List of SQL statements
    """
    sql_statements = []
    # with open('schema.txt', 'r') as file:
    #     schema = file.read()
    schema = extract_sql_schema('required.sql')
    schema_description = create_schema_description(schema)
    # print(schema_description)
    for item in data:
        nl_query = item["NL"]
        
        # Prepare the prompt for the LLM
        system_content = "You are an expert in converting natural language to SQL. Generate a correct SQL query based on the description provided. Return ONLY the SQL query without any explanation or markdown code blocks."
        if schema_description:
            system_content += f"\n\nUse the following database schema for reference:\n{schema.keys()}"
        
        messages = [
            {
                "role": "system",
                "content": system_content
            },
            {
                "role": "user",
                "content": nl_query
            }
        ]
        
        # Call the API to get the SQL statement
        api_response, _ = call_groq_api(
            api_key="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",
            model="llama-3.3-70b-versatile",
            messages=messages,
            temperature=0.1,
            max_tokens=500
        )
        
        # Extract the SQL query from the response
        if 'choices' in api_response and len(api_response['choices']) > 0:
            sql_query = api_response['choices'][0]['message']['content'].strip()
            
            # Clean the SQL query if it has markdown formatting
            sql_query = clean_sql_query(sql_query)
            
            # Add the result to our list
            sql_statements.append({
                "NL": nl_query,
                "Query": sql_query
            })
        else:
            # In case of API error, just keep the original NL and add an empty query
            print("API Error:", api_response)
            sql_statements.append({
                "NL": nl_query,
                "Query": ""
            })
    
    return sql_statements

# Function to correct SQL statements
def correct_sqls(sql_statements, schema_description=""):
    """
    Correct SQL statements if necessary.
    
    :param sql_statements: List of Dict with incorrect SQL statements and NL query
    :param schema_description: Description of the database schema
    :return: List of corrected SQL statements in the format [{"IncorrectQuery": "...", "CorrectQuery": "..."}]
    """
    corrected_sqls = []
    
    for item in sql_statements:
        # Extract the incorrect query from the input data
        # The input format might have NL and Query keys or might directly have IncorrectQuery
        if "Query" in item:
            incorrect_query = item["Query"]
            nl_query = item.get("NL", "")
        elif "IncorrectQuery" in item:
            incorrect_query = item["IncorrectQuery"]
            nl_query = item.get("NL", "")
        else:
            # Skip items with unexpected format
            continue
        
        # Prepare the prompt for the LLM
        system_content = "You are an expert in SQL. Given an incorrect SQL query and optionally a natural language description, provide the corrected SQL query. Return ONLY the corrected SQL query without any explanation or markdown code blocks."
        
        if schema_description:
            system_content += f"\n\nUse the following database schema for reference:\n{schema_description}"
        
        messages = [
            {
                "role": "system",
                "content": system_content
            },
            {
                "role": "user",
                "content": f"Incorrect SQL Query: {incorrect_query}\n\n" + 
                          (f"Natural Language Description: {nl_query}\n\n" if nl_query else "") +
                          "Please provide the correct SQL query:"
            }
        ]
        
        # Call the API to get the corrected SQL statement
        api_response, _ = call_groq_api(
            api_key="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",
            model="llama-3.3-70b-versatile",
            messages=messages,
            temperature=0.1,
            max_tokens=500
        )
        
        # Extract the corrected SQL query from the response
        if 'choices' in api_response and len(api_response['choices']) > 0:
            corrected_query = api_response['choices'][0]['message']['content'].strip()
            
            # Clean the SQL query if it has markdown formatting
            corrected_query = clean_sql_query(corrected_query)
            
            # Add the result to our list in the required format
            corrected_sqls.append({
                "IncorrectQuery": incorrect_query,
                "CorrectQuery": corrected_query
            })
        else:
            # In case of API error, just keep the original query
            corrected_sqls.append({
                "IncorrectQuery": incorrect_query,
                "CorrectQuery": incorrect_query
            })
    
    return corrected_sqls

# Function to call the Groq API
def call_groq_api(api_key, model, messages, temperature=0.0, max_tokens=1000, n=1):
    """
    NOTE: DO NOT CHANGE/REMOVE THE TOKEN COUNT CALCULATION 
    Call the Groq API to get a response from the language model.
    :param api_key: API key for authentication
    :param model: Model name to use
    :param messages: List of message dictionaries
    :param temperature: Temperature for the model
    :param max_tokens: Maximum number of tokens to generate (these are max new tokens)
    :param n: Number of responses to generate
    :return: Response from the API
    """
    global total_tokens
    url = "https://api.groq.com/openai/v1/chat/completions"
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}",
    }
    data = {
        "model": model,
        "messages": messages,
        'temperature': temperature,
        'max_tokens': max_tokens,
        'n': n
    }

    response = requests.post(url, headers=headers, json=data)
    response_json = response.json()

    # Update the global token count
    total_tokens += response_json.get('usage', {}).get('completion_tokens', 0)

    # You can get the completion from response_json['choices'][0]['message']['content']
    return response_json, total_tokens

# Main function
def main():
    # TODO: Specify the path to your input files and SQL schema directory
    input_file_path_1 = 'train_generate_task.json'
    input_file_path_2 = 'train_query_correction_task.json'
    schema_directory = 'required.sql'
    
    # Load data from input files
    data_1 = load_input_file(input_file_path_1)
    data_2 = load_input_file(input_file_path_2)
    
    # Extract schema information from SQL files
    schema = extract_sql_schema(schema_directory)
    schema_description = create_schema_description(schema)
    
    start = time.time()
    # Generate SQL statements with schema information
    sql_statements = generate_sqls(data_1, schema_description)
    generate_sqls_time = time.time() - start
    
    start = time.time()
    # Correct SQL statements with schema information
    corrected_sqls = correct_sqls(data_2, schema_description)
    correct_sqls_time = time.time() - start
    
    assert len(data_2) == len(corrected_sqls) # If no answer, leave blank
    assert len(data_1) == len(sql_statements) # If no answer, leave blank
    
    # Get the outputs as a list of dicts with keys 'IncorrectQuery' and 'CorrectQuery'
    with open('output_sql_correction_task.json', 'w') as f:
        json.dump(corrected_sqls, f)    
    
    # Get the outputs as a list of dicts with keys 'NL' and 'Query'
    with open('output_sql_generation_task.json', 'w') as f:
        json.dump(sql_statements, f)
    
    return generate_sqls_time, correct_sqls_time

if __name__ == "__main__":
    generate_sqls_time, correct_sqls_time = main()
    print(f"Time taken to generate SQLs: {generate_sqls_time} seconds")
    print(f"Time taken to correct SQLs: {correct_sqls_time} seconds")
    print(f"Total tokens: {total_tokens}")