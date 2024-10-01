#!/bin/bash

source ./helpers.sh

SQL_QUERY="
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS articles;
DROP TABLE IF EXISTS users;

DROP FUNCTION IF EXISTS normal_rand();
DROP FUNCTION IF EXISTS clamp(NUMERIC, NUMERIC, NUMERIC);
"

echo "🗑️ Dropping schema..."
execute_sql "$SQL_QUERY" "Dropping schema" > /dev/null
echo "✅ Schema dropped successfully."
echo ""
