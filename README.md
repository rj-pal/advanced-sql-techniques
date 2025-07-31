### Advanced SQL Techniques

This directory showcases some advanced sql techniques used in data engineering or analytics. 

#### Actors and Films Database:
Project includes:
- [Postgres-movie-db](./postgres-movie-db.ipynb): Main notebook using sqlalchemy to run sql scripts
- [db.sql](./db.sql): SQL scripts
- [Magic_sql](./magic_sql.ipynb): Secondary Notebook for ad-hoc analysis
- [How to Use Guide](./how-to-guide.md)

The purpose of this demonstation is to showcase the use of Postgre, Python, and Docker to create an Actor and Film databsase featuring a SDC (slowly changing dimension) table made from a larger table of information on actors and films. Docker is used to manage the postgres instance and Juypter Notebooks is used for executing the steps. A sql script file of all commands can also be found, as well as an additional notebook for conducting analysis.  

The sql found in the notebook postgres.ipynb is from a bootcamp on dataexpert.io and the original data can be found in the [Data Engineer Handbook](https://github.com/DataExpert-io/data-engineer-handbook). Check it out for a complete guide to data engineering.

The set-up uses Docker to pull and modify the official Postgres Docker image to create my own postgres server. All the standard postgres set-up variables are used, and are loaded from an .env file.

The database is populated with a table entitled `actor_films` which was read in from a csv file. The DDL for this tables included:

- actor	
- actorid
- film
- year
- votes
- rating
- filmid

----

The first script employs a PostgreSQL anonymous code block utilizing a FOR loop to incrementally populate the actors table with cumulative yearly data. The loop iterates from a baseline year preceding the dataset's initial year (1969) through to the final year (2021). For each iteration, it aggregates film data from the current year into arrays of composite film types, which are then combined with the preceding year’s cumulative dataset. This approach preserves a running history of each actor’s filmography, accounting for continuity by carrying forward film data when an actor is inactive in a given year. Additionally, the script computes an average film rating for each actor’s cumulative portfolio, subsequently categorizing actors into quality classes (‘star’, ‘good’, ‘average’, or ‘bad’) via an enumerated type. The methodology effectively constructs a longitudinal record reflecting both actor activity and performance across the specified time span.

The second script generates a Slowly Changing Dimension (SCD) table, actors_scd, designed to capture temporal changes in an actor’s quality classification and activity status. Through the use of window functions (LAG and cumulative SUM), the script identifies years in which an actor’s status has changed relative to the prior year. It then groups consecutive years with unchanged status to define contiguous periods, outputting records that delineate the start and end years of each status interval. This design facilitates an efficient representation of actor status histories by consolidating periods of stability, thereby supporting more concise temporal analyses and reporting.

--

The first script leverages a PostgreSQL anonymous code block and a FOR loop to iteratively populate the actors table with cumulative yearly filmography data. The loop starts from 1969—one year before the earliest data year (1970)—and proceeds through 2021. For each year, it aggregates films into arrays of composite film types representing an actor’s portfolio, and merges these with the previous year’s cumulative data. This ensures continuity by carrying forward film data for inactive years. The script also computes an average rating from all accumulated films, classifying actors into enumerated quality tiers (‘star’, ‘good’, ‘average’, or ‘bad’). This approach constructs a comprehensive longitudinal dataset capturing actor activity and performance over time. 

The second script constructs a Slowly Changing Dimension (SCD) table, actors_scd, which identifies and records intervals of change in actors’ quality classifications and active status. Utilizing window functions (LAG and cumulative SUM), it detects year-over-year changes and groups contiguous years of consistent status into intervals defined by start and end years. This facilitates efficient historical tracking by representing stable periods as single records, optimizing temporal analysis and reporting.

--



