# Tutorial: Simulate and fix slow delete operations in PostgreSQL

This repo contains code that lets you simulate and fix a common performance issue in PostgreSQL schemas.

The issue is that deleting a single record can take an unexpectedly long time, if:
- The record you delete is referenced as a foreign key in another table
- Deleting this record causes rows in another table to be deleted due to an `ON DELETE CASCADE` constraint
- You haven't created indexes on the foreign key columns in _both_ the referencing table and the referenced table.

We encourage you to first read about this pitfall in [our blog post](https://render.com/blog/top-cause-slow-queries-postgresql-no-query-log-needed). Then come back here to demo it for yourself.

## Overview
In this tutorial, you will follow steps to:
1. Create a demo environment with a demo database.
2. Populate your database with sample data.
3. Delete a first record. (This deletion will be slow.)
4. Create indexes, and delete another record. (This deletion will be fast.)

## Prerequisites

- Install the `psql` command-line tool on the machine where you will run the scripts in this demo. (You can run this demo on your local machine, such as a laptop.)

## 1. Set up a demo environment
### 1a. Create a demo database
If you already have a database you can use for demo purposes, feel free to use that instead of creating a new instance. Identify the URL of this database.

Otherwise, create a database on Render. You can use Render's free plan.
1. [Follow this guide](https://docs.render.com/databases#create-your-database) to create a database through the Render dashboard.
   * If you prefer to set up a database using Infrastructure as Code, learn about [Render Blueprints](https://docs.render.com/infrastructure-as-code) and apply the Blueprint that's [located in this repository](./render.yaml).
2. Once your database is running, locate its [external URL](https://docs.render.com/databases#connecting-with-the-external-url) in the Render dashboard:

<img width=”500” src=”./images/connection.png” />

You will use the database URL in the next step.

### 1b. Configure local environment variable

On your local machine (or, wherever you plan to run this demo), set the `POSTGRES_CONNECTION_STRING` environment variable to be your database URL. This is the URL from `Step 1a`.

To set the environment variable, run the following line in a terminal—but replace the dummy value here with your PostgreSQL URL from `Step 1a`:
```
export POSTGRES_CONNECTION_STRING="postgresql://username:password@host:5432/database_name"
```

## 2. Populate the database
### 2a. Create the database schema

First, set up the database schema. We will implement the schema described in [the blog post](https://render.com/blog/top-cause-slow-queries-postgresql-no-query-log-needed), with users, articles, and comments.

Run the `create-schema.sh` script to create the database schema:

```
./create-schema.sh
```

Note: If the target tables already exist, running this script will drop and recreate those tables.

### 2b. Generate sample data

Run the `generate-data.sh` script to populate the tables with sample data:

```
./generate-data.sh
```

This script will prompt you for parameters to customize the data it generates. Note that:
- By default, this script will generate ~1.5M comments. If you use the database plan defined in [the Blueprint in this repo](./render.yaml), this script should take ~40s to run.
- If you choose to generate more comments, the script will take longer to run.

## 3. Delete a record (slow performance)

Run the `delete.sh` script. Running this script will select and delete a user with many related records.

```
./delete.sh
```

This script finds the user with the most articles and comments, and deletes the user. Deleting this user triggers a cascade of deletes in articles and comments.

The deletion should be relatively slow due to the lack of indexes. Note the execution time. Our goal is to speed this up.

## 4. Fix the performance problem
### 4a. Create indexes
Now, create the missing foreign key indexes by running the `create-index.sh` script:

```
./create-index.sh
```

### 4b. Delete a record (fast performance)
5. Run the `delete.sh` script again:

```
./delete.sh
```

This time, the deletion process should be significantly faster (potentially orders of magnitude) due to the indexes.

Compare the execution time of this deletion with the previous run to see the improvement.

Note that this improvement increases as the number of comments increase!

## How to reproduce the blog post demo
By default, the script in this repo generates ~1.5M comments. In contrast, the demo in the blog post used 13M comments (as well as ~1k users and 25k articles).

If you'd like to reproduce the larger-scale scenario in the blog post, use the following inputs when you run `generate-data.sh`:
```
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
```
