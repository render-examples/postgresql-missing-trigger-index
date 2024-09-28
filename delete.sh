#!/bin/bash

source ./helpers.sh

find_user_with_most_commented_articles() {
    local SQL_QUERY="
    SELECT u.id AS user_id
    FROM users u
    JOIN articles a ON u.id = a.author_id
    JOIN comments c ON a.id = c.article_id
    GROUP BY u.id
    ORDER BY COUNT(DISTINCT a.id) DESC
    LIMIT 1;
    "
    local result
    result=$(execute_sql "$SQL_QUERY" "Finding user with most articles that have comments" | extract_single_numeric_result)
    
    if [[ "$result" =~ ^[0-9]+$ ]]; then
        echo "$result"
    else
        echo "No valid user ID found. There might be no users with articles that have comments."
        exit 1
    fi
}

echo "Finding the user with the most articles that have at least one comment..."
result=$(find_user_with_most_commented_articles)
echo "User ID with the most articles that have at least one comment: $result"

ARTICLE_COUNT_QUERY="SELECT COUNT(*) FROM articles WHERE author_id = $result;"
ARTICLE_COUNT=$(execute_sql "$ARTICLE_COUNT_QUERY" "Counting associated articles" | extract_single_numeric_result)
COMMENT_COUNT_QUERY="SELECT COUNT(*) FROM comments WHERE author_id = $result OR article_id IN (SELECT id FROM articles WHERE author_id = $result);"
COMMENT_COUNT=$(execute_sql "$COMMENT_COUNT_QUERY" "Counting associated comments" | extract_single_numeric_result)
echo "Deleting user $result, which will cascade to $ARTICLE_COUNT articles and $COMMENT_COUNT comments."
read -p "Press Enter to continue or Ctrl+C to cancel..."

DELETE_QUERY="EXPLAIN ANALYZE DELETE FROM users WHERE id = $result;"
execute_sql "$DELETE_QUERY" "Deleting user and associated data"
echo "✅ User deleted successfully."
echo ""