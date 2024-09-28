# Database Schema Creation and Data Loading

This project includes scripts to create the necessary database schema and load sample data for the application.

## Prerequisites

- PostgreSQL installed and running
- `psql` command-line tool available in your system's PATH

## Setting Up the Database

To set up the database schema and load sample data, follow these steps:

1. Set the PostgreSQL connection string as an environment variable:

   ```
   export POSTGRES_CONNECTION_STRING="postgresql://username:password@localhost:5432/database_name"
   ```

   Replace `username`, `password`, `localhost`, `5432`, and `database_name` with your actual PostgreSQL connection details.

2. Run the `create-schema.sh` script to create the database schema:

   ```
   ./create-schema.sh
   ```

   This script will create the following tables:
   - `users`
   - `articles`
   - `comments`

   If the tables already exist, they will be dropped and recreated.

3. After the schema is created successfully, run the `generate-data.sh` script to populate the tables with sample data:

   ```
   ./generate-data.sh
   ```

   This script will prompt you for various parameters to customize the data generation process.

4. Follow the prompts in the `generate-data.sh` script to specify the amount and distribution of data you want to generate. Here are sample values that will generate approximately 1,000 users, 25,000 articles, and 13 million comments:

   - Number of users to insert: 1000
   - Percentage of users who should be active authors: 100
   - Average number of articles per active author: 25
   - Standard deviation for the number of articles per author: 5
   - Maximum number of articles an author can write: 50
   - Percentage of users who should be active commenters: 100
   - Percentage of articles that should have comments: 100
   - Average number of comments per article with comments: 520
   - Standard deviation for the number of comments per article: 100
   - Maximum number of comments an article can have: 1000

   These values are designed to mirror a scale discussed in a related blog post, resulting in approximately 1,000 users, 25,000 articles, and 13 million total comments.

   Note: When inserting a large number of rows (approximately 1 million or more), the insertion process might take a considerable amount of time. With the sample values provided above, inserting the comments (approximately 13 million rows) takes about 2 minutes. Please be patient and allow the script to complete its execution.

5. After generating the data, run the `delete.sh` script to select and delete a user with many related records:

   ```
   ./delete.sh
   ```

   This script will find the user with the most articles that have comments, and perform a cascade delete. The deletion process should be relatively slow due to the lack of indexes.

6. Now, apply the indexes by running the `create-index.sh` script:

   ```
   ./create-index.sh
   ```

7. Run the `delete.sh` script again:

   ```
   ./delete.sh
   ```

   This time, the deletion process should be significantly faster (potentially orders of magnitude) due to the presence of indexes.

By comparing the execution times and EXPLAIN ANALYZE output from the two runs of `delete.sh`, you can observe the dramatic performance improvement that proper indexing can provide for cascade delete operations in a relational database.

