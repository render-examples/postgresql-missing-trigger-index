#!/bin/bash

source ./helpers.sh

# Get current table counts
TOTAL_USERS=$(execute_sql "SELECT COUNT(*) FROM users;" "Counting total users" | extract_single_numeric_result)
TOTAL_ARTICLES=$(execute_sql "SELECT COUNT(*) FROM articles;" "Counting total articles" | extract_single_numeric_result)

# Function to check if table is empty and ask user if they want to proceed
check_and_confirm() {
    local table_name="$1"
    local count
    count=$(execute_sql "SELECT COUNT(*) FROM $table_name;" "Counting rows in $table_name" | extract_single_numeric_result)
    
    if [[ "$count" =~ ^[0-9]+$ ]] && [ "$count" -gt 0 ]; then
        echo "The $table_name table already contains $count rows."
        echo "Note: Running create-schema.sh will clear all existing data if you want to start fresh."
        read -p "Do you want to proceed with inserting more data? (y/n): " choice
        case "$choice" in
            y|Y ) return 0;;
            n|N ) return 1;;
            * ) echo "Invalid input. Skipping insertion."; return 1;;
        esac
    else
        return 0
    fi
}

SQL_HELPER_FUNCTIONS="
CREATE OR REPLACE FUNCTION normal_rand() RETURNS double precision
AS \$\$ 
BEGIN 
    RETURN sqrt(-2 * ln(random())) * cos(2 * pi() * random()); 
END; 
\$\$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION clamp(value NUMERIC, min_value NUMERIC, max_value NUMERIC) RETURNS NUMERIC
AS \$\$ 
BEGIN 
    RETURN GREATEST(min_value, LEAST(max_value, value)); 
END; 
\$\$ LANGUAGE plpgsql IMMUTABLE;
"
execute_sql "$SQL_HELPER_FUNCTIONS" "Creating helper functions" > /dev/null
echo "Helper functions created successfully."
echo ""

echo "📊 Preparing to insert users...
================================="
if check_and_confirm "users"; then
    NUM_USERS=$(get_input "How many users would you like to insert?" 1000)
    echo ""
    echo "About to insert $NUM_USERS users."
    read -p "Press Enter to continue or Ctrl+C to cancel..."
    echo ""

    SQL_INSERT_USERS="
    WITH inserted AS (
        INSERT INTO users (name, email)
        SELECT gen_random_uuid()::text, gen_random_uuid()::text
        FROM generate_series(1, $NUM_USERS) i
        RETURNING 1
    )
    SELECT COUNT(*) AS num_users_inserted FROM inserted;
    "
    inserted_users=$(execute_sql "$SQL_INSERT_USERS" "Inserting users" | extract_single_numeric_result)
    echo "✅ $inserted_users users inserted successfully."
        TOTAL_USERS=$((TOTAL_USERS + inserted_users))
    else
        echo "⏩ Skipping user insertion."
    fi
    echo ""

echo "📝 Preparing to insert articles...
====================================="
if check_and_confirm "articles"; then
    ACTIVE_AUTHORS_PERCENT=$(get_input "What percentage of the $TOTAL_USERS users should be active authors?" 100)
    ARTICLES_PER_AUTHOR_MEAN=$(get_input "On average, how many articles should each active author write?" 20)
    ARTICLES_PER_AUTHOR_STDDEV=$(get_input "What should be the standard deviation for the number of articles per author?" 5)
    ARTICLES_PER_AUTHOR_MAX=$(get_input "What's the maximum number of articles an author can write?" $((2 * ARTICLES_PER_AUTHOR_MEAN)))
    echo ""

    # Estimate the number of articles to be inserted
    TOTAL_USERS=$(execute_sql "SELECT COUNT(*) FROM users;" "Counting total users" | extract_single_numeric_result)
    ESTIMATED_ACTIVE_AUTHORS=$((TOTAL_USERS * ACTIVE_AUTHORS_PERCENT / 100))
    read ESTIMATED_ARTICLES ESTIMATED_ARTICLES_STDDEV <<< "$(estimate_normal_sum $ESTIMATED_ACTIVE_AUTHORS $ARTICLES_PER_AUTHOR_MEAN $ARTICLES_PER_AUTHOR_STDDEV)"
    ESTIMATED_ARTICLES=$(clamp $ESTIMATED_ARTICLES 0 $((ESTIMATED_ACTIVE_AUTHORS * ARTICLES_PER_AUTHOR_MAX)))
    echo "Estimated number of articles to be inserted: ~$ESTIMATED_ARTICLES (±$ESTIMATED_ARTICLES_STDDEV)"
    read -p "Press Enter to continue or Ctrl+C to cancel..."

    SQL_INSERT_ARTICLES="
    WITH
    active_authors AS (
        SELECT id AS user_id FROM users WHERE random() < $ACTIVE_AUTHORS_PERCENT::float / 100
    ),
    user_article_counts AS (
        SELECT
            user_id,
            clamp((normal_rand() * $ARTICLES_PER_AUTHOR_STDDEV)::integer + $ARTICLES_PER_AUTHOR_MEAN, 0, $ARTICLES_PER_AUTHOR_MAX) AS article_count
        FROM active_authors
    ),
    inserted AS (
        INSERT INTO articles (author_id, title, content)
        SELECT c.user_id, gen_random_uuid()::text, gen_random_uuid()::text
        FROM user_article_counts c, generate_series(1, c.article_count) i
        RETURNING 1
    )
    SELECT COUNT(*) AS num_articles_inserted FROM inserted;
    "
    inserted_articles=$(execute_sql "$SQL_INSERT_ARTICLES" "Inserting articles" | extract_single_numeric_result)
    echo "✅ $inserted_articles articles inserted successfully."
        TOTAL_ARTICLES=$((TOTAL_ARTICLES + inserted_articles))
    else
        echo "⏩ Skipping article insertion."
    fi
    echo ""

echo "💬 Preparing to insert comments...
====================================="
if check_and_confirm "comments"; then
    ACTIVE_COMMENTERS_PERCENT=$(get_input "What percentage of the $TOTAL_USERS users should be active commenters?" 100)
    ARTICLES_WITH_COMMENTS_PERCENT=$(get_input "What percentage of the $TOTAL_ARTICLES articles should have comments?" 100)
    COMMENTS_PER_ARTICLE_MEAN=$(get_input "On average, how many comments should each article with comments have?" 125)
    COMMENTS_PER_ARTICLE_STDDEV=$(get_input "What should be the standard deviation for the number of comments per article?" 25)
    COMMENTS_PER_ARTICLE_MAX=$(get_input "What's the maximum number of comments an article can have?" $((2 * COMMENTS_PER_ARTICLE_MEAN)))
    echo ""
    
    # Estimate the number of comments to be inserted
    TOTAL_ARTICLES=$(execute_sql "SELECT COUNT(*) FROM articles;" "Counting total articles" | extract_single_numeric_result)
    ESTIMATED_ARTICLES_WITH_COMMENTS=$((TOTAL_ARTICLES * ARTICLES_WITH_COMMENTS_PERCENT / 100))
    read ESTIMATED_COMMENTS ESTIMATED_COMMENTS_STDDEV <<< "$(estimate_normal_sum $ESTIMATED_ARTICLES_WITH_COMMENTS $COMMENTS_PER_ARTICLE_MEAN $COMMENTS_PER_ARTICLE_STDDEV)"
    ESTIMATED_COMMENTS=$(clamp $ESTIMATED_COMMENTS 0 $((ESTIMATED_ARTICLES_WITH_COMMENTS * COMMENTS_PER_ARTICLE_MAX)))
    echo "Estimated number of comments to be inserted: ~$ESTIMATED_COMMENTS (±$ESTIMATED_COMMENTS_STDDEV)"
    read -p "Press Enter to continue or Ctrl+C to cancel..."

    SQL_INSERT_COMMENTS="
    WITH
    active_commenters AS (
        SELECT id AS user_id FROM users WHERE random() < $ACTIVE_COMMENTERS_PERCENT::float / 100
    ),
    articles_with_comments AS (
        SELECT id AS article_id FROM articles WHERE random() < $ARTICLES_WITH_COMMENTS_PERCENT::float / 100
    ),
    article_comment_counts AS (
        SELECT
            article_id,
            clamp((normal_rand() * $COMMENTS_PER_ARTICLE_STDDEV)::integer + $COMMENTS_PER_ARTICLE_MEAN, 0, $COMMENTS_PER_ARTICLE_MAX) AS comment_count
        FROM articles_with_comments
    ),
    comment_assignments AS (
        SELECT c.user_id, a.article_id
        FROM article_comment_counts a
        JOIN LATERAL (
            SELECT user_id FROM active_commenters 
            ORDER BY random() LIMIT a.comment_count
        ) c ON true
    ),
    inserted AS (
        INSERT INTO comments (author_id, article_id, content)
        SELECT a.user_id, a.article_id, gen_random_uuid()::text
        FROM comment_assignments a
        RETURNING 1
    )
    SELECT COUNT(*) AS num_comments_inserted FROM inserted;
    "
    inserted_comments=$(execute_sql "$SQL_INSERT_COMMENTS" "Inserting comments" | extract_single_numeric_result)
    echo "✅ $inserted_comments comments inserted successfully."
else
    echo "⏩ Skipping comment insertion."
fi
echo ""
