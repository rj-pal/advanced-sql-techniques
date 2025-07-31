### Advanced SQL Techniques

The purpose of this directory is to highlight some advanced sql techniques used in data engineering or analytics. 

#### Actors and Films Database:
Project includes:
- [Postgres-movie-db](./postgres-movie-db.ipynb): Main notebook using sqlalchemy to run sql scripts
- [db.sql](./db.sql): SQL scripts
- [Magic_sql](./magic_sql.ipynb): Secondary Notebook for ad-hoc analysis
- [How to Use Guide](./how-to-guide.md): Documentation on how to use the data.

This demonstration showcases the use of PostgreSQL, Python, and Docker to build an actor_films database, featuring a Slowly Changing Dimension (SCD) table derived from a larger dataset on actors and films.

Docker is used to manage the PostgreSQL instance, while Jupyter Notebooks is used to execute all processing steps. A complete SQL script is provided, along with a supplementary notebook for additional analysis and a guide on how to use the data in analysis.

The SQL code in postgres-movie-db.ipynb is based on material from a bootcamp hosted by DataExpert.io using data from the [Data Engineer Handbook](https://github.com/DataExpert-io/data-engineer-handbook). For a full walkthrough of the the concepts and ideas seen here in the data engineering process, refer to the guide.

The setup pulls and modifies the official Postgres Docker image to create a custom PostgreSQL server. Environment variables for configuration are loaded from a .env file.

The main table, `actor_films`, is imported from a CSV file and includes the following fields: `actor`, `actorid`, `film`, `year`, `votes`, `rating`, `filmid`.

----
##### Summary of SQL Script Process

The first script leverages a PostgreSQL anonymous code block and a FOR loop to iteratively populate the actors table with cumulative yearly filmography data. The loop starts from 1969—one year before the earliest data year (1970)—and proceeds through 2021. For each year, it aggregates films into arrays of composite film types representing an actor’s portfolio, and merges these with the previous year’s cumulative data. This ensures continuity by carrying forward film data for inactive years. The script also computes an average rating from all accumulated films, classifying actors into enumerated quality tiers (‘star’, ‘good’, ‘average’, or ‘bad’). This approach constructs a comprehensive longitudinal dataset capturing actor activity and performance over time. 

The second script constructs a Slowly Changing Dimension (SCD) table, actors_scd, which identifies and records intervals of change in actors’ quality classifications and active status. Utilizing window functions (LAG and cumulative SUM), it detects year-over-year changes and groups contiguous years of consistent status into intervals defined by start and end years. This facilitates efficient historical tracking by representing stable periods as single records, optimizing temporal analysis and reporting.

--



