#!/bin/bash

# Check if the required environment variable is set
if [ -z "$POSTGRES_CONNECTION_STRING" ]; then
    echo "Error: POSTGRES_CONNECTION_STRING environment variable is not set."
    echo "Please set it to your PostgreSQL connection string."
    exit 1
fi

# Function to check if PostgreSQL is accessible
check_postgres_connection() {
    if ! command -v psql &> /dev/null; then
        echo "Error: psql command not found. Please ensure PostgreSQL client tools are installed."
        exit 1
    fi

    if ! command -v pg_isready &> /dev/null; then
        echo "Error: pg_isready command not found. Please ensure PostgreSQL client tools are installed."
        exit 1
    fi

    if ! pg_isready -d "$POSTGRES_CONNECTION_STRING" &> /dev/null; then
        echo "Error: Unable to connect to PostgreSQL. Please check your connection string and ensure the server is running."
        exit 1
    fi

    echo "PostgreSQL connection successful."
    echo ""
}

# Check PostgreSQL connection
check_postgres_connection

# Function to execute SQL with minimal output
execute_sql() {
    local sql="$1"
    local message="$2"
    local output
    output=$(echo "$sql" | psql -v ON_ERROR_STOP=1 -t -q "$POSTGRES_CONNECTION_STRING" 2>&1)
    local exit_code=$?
    if [ $exit_code -eq 0 ] && ! echo "$output" | grep -qE "^ERROR:"; then
        echo "$output"
    else
        echo "Error executing SQL: $message" >&2
        echo "$output" >&2
        exit 1
    fi
}

# Function to get user input with default value, ensuring a non-negative number
get_input() {
    local prompt="$1"
    local default="$2"
    local input
    while true; do
        read -p "$prompt [$default]: " input
        input="${input:-$default}"
        if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 0 ]; then
            echo "$input"
            return
        else
            echo "Please enter a non-negative number." >&2
        fi
    done
}

# Function to extract a single numeric result from SQL query result
extract_single_numeric_result() {
    awk '/^[[:space:]]*[0-9]+[[:space:]]*$/ {print $1; exit}'
}

# Function to estimate the sum of normal variables
estimate_normal_sum() {
    local count=$1
    local mean=$2
    local stddev=$3
    local total_mean
    total_mean=$(echo "$count * $mean" | bc)
    local total_stddev
    total_stddev=$(echo "sqrt($count) * $stddev" | bc)
    echo "$total_mean $total_stddev"
}

# Function to clamp a value between min and max
clamp() {
    local value=$1
    local min=$2
    local max=$3
    echo $(( value < min ? min : value > max ? max : value ))
}
