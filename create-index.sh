#!/bin/bash

source ./helpers.sh

SQL_CREATE_INDEX_ARTICLES_AUTHOR_ID="CREATE INDEX IF NOT EXISTS articles_author_id ON articles(author_id);"
echo "📗 Creating index on articles(author_id)..."
execute_sql "$SQL_CREATE_INDEX_ARTICLES_AUTHOR_ID" "Creating index on articles(author_id)" > /dev/null
echo "✅ Index created successfully."
echo ""

SQL_CREATE_INDEX_COMMENTS_AUTHOR_ID="CREATE INDEX IF NOT EXISTS comments_author_id ON comments(author_id);"
echo "📗 Creating index on comments(author_id)..."
execute_sql "$SQL_CREATE_INDEX_COMMENTS_AUTHOR_ID" "Creating index on comments(author_id)" > /dev/null
echo "✅ Index created successfully."
echo ""

SQL_CREATE_INDEX_COMMENTS_ARTICLE_ID="CREATE INDEX IF NOT EXISTS comments_article_id ON comments(article_id);"
echo "📗 Creating index on comments(article_id)..."
execute_sql "$SQL_CREATE_INDEX_COMMENTS_ARTICLE_ID" "Creating index on comments(article_id)" > /dev/null
echo "✅ Index created successfully."
echo ""
