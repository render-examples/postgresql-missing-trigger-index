# PostgreSQL Trigger + Missing Index Demonstration

This repository is an interactive demonstration of a performance pitfall common in many PostgreSQL schemas as described in [TODO - BLOG POST LINK - TODO](TODO).

TL;DR: The deletion of a record that can cascade over other tables can take an unintuitive amount of time if there are no indexes on foreign key relationships **in both directions**. This repository contains scripts to create a sample schema and generate enough data to show the contrast in performance with and without these indexes.

## Prerequisites

- `psql` command-line tool available in your system's PATH

## Configuring your instance

Set connection string pointing to your target PostgreSQL instance as an environment variable:

```
export POSTGRES_CONNECTION_STRING="postgresql://username:password@localhost:5432/database_name"
```

If you are running a database locally, replace the values of `username`, `password`, `localhost`, `5432`, and `database_name` with your actual PostgreSQL connection details.

You can also spin up a test PostgreSQL instance on Render using the [Blueprint](https://docs.render.com/infrastructure-as-code) [defined in this repository](./render.yaml). You can then find the connection string for that instance in the connection widget:

![Finding the connection string](./images/connection.png)

## Running the simulation

The following steps will create a test schema, generate fake data, and run a specific deletion with and without an index.

1. Run the `create-schema.sh` script to create the database schema:

   ```
   ./create-schema.sh
   ```

   If the target tables already exist, they will be dropped and recreated.

2. After the schema is created successfully, run the `generate-data.sh` script to populate the tables with sample data:

   ```
   ./generate-data.sh
   ```

   This script will prompt you for various parameters to customize the data generation process.

3. Follow the prompts in the `generate-data.sh` script to specify the amount and distribution of data you want to generate. Here are the exact questions you'll be asked, along with sample values that will generate approximately 1,000 users, 25,000 articles, and 13 million comments, which match the test values we used for the query plans/timings in the blog post:

   - How many users would you like to insert? [1000]: 1000
   - What percentage of the 1000 users should be active authors? [10]: 100
   - On average, how many articles should each active author write? [25]: 25
   - What should be the standard deviation for the number of articles per author? [5]: 5
   - What's the maximum number of articles an author can write? [50]: 50
   - What percentage of the 1000 users should be active commenters? [40]: 100
   - What percentage of the 25000 articles should have comments? [20]: 100
   - On average, how many comments should each article with comments have? [5]: 520
   - What should be the standard deviation for the number of comments per article? [2]: 100
   - What's the maximum number of comments an article can have? [10]: 1000

   The insertion process might take a while for larger insertions. With the sample values provided above, inserting the comments (approximately 13 million rows) takes just over 3 minutes and consumes ~3GB of disk space. Please be patient and allow the script to complete its execution.

4. After generating the data, run the `delete.sh` script to select and delete a user with many related records:

   ```
   ./delete.sh
   ```

   This script will find the user with the most articles that have comments, and perform a cascade delete. The deletion process should be relatively slow due to the lack of indexes. Note the execution time for comparison.

5. Now, apply the indexes by running the `create-index.sh` script:

   ```
   ./create-index.sh
   ```

6. Run the `delete.sh` script again:

   ```
   ./delete.sh
   ```

   This time, the deletion process should be significantly faster (potentially orders of magnitude) due to the presence of indexes. Compare the execution time with the previous run to see the dramatic improvement.

By comparing the execution times and EXPLAIN ANALYZE output from the two runs of `delete.sh`, you can observe the dramatic performance improvement that proper indexing can provide for cascade delete operations in a relational database.
