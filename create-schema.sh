#!/bin/bash

source ./helpers.sh

SQL_QUERY="
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS articles;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    email       TEXT UNIQUE NOT NULL,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE articles (
    id          SERIAL PRIMARY KEY,
    title       TEXT NOT NULL,
    content     TEXT NOT NULL,
    author_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE comments (
    id          SERIAL PRIMARY KEY,
    content     TEXT NOT NULL,
    author_id   INTEGER REFERENCES users(id) ON DELETE SET NULL,
    article_id  INTEGER NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
"
echo "📝 Creating schema..."
execute_sql "$SQL_QUERY" "Creating schema" > /dev/null
echo "✅ Schema created successfully."
echo ""
