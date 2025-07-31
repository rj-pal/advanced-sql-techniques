-- Create two user-defined types: 'quality_class' as Enum and 'films' as custom type
CREATE TYPE quality_class AS ENUM ('star', 'good', 'average', 'bad');

CREATE TYPE films AS (
    film TEXT,
    votes INTEGER,
    rating REAL,
    year INTEGER,
    filmid TEXT
);
-- Create the 'actors table' with DDL to be constructed from the 'actors_film table'
CREATE TABLE actors (
    actor TEXT,
    actorid TEXT,
    quality_class quality_class,
    is_active BOOL,
    current_year SMALLINT,
    films films[],
    PRIMARY KEY(actorid, current_year)
);
-- Script STARTS for constructing the 'actors table'
-- Initiate variable 'start_year' as 1969 (one year before data starts in 1970 or MIN(year)) as starting value of FOR LOOP 
-- Initiate variable 'end_year' as 2021 (final year in data or MAX(year)) as ending value of FOR LOOP
-- Initiate variable 'current_year'
DO $$ 
DECLARE  
    start_year SMALLINT := 1969;  
    end_year SMALLINT := 2021;  
    current SMALLINT;  
BEGIN 
-- Start FOR LOOP from first year in the table to the final year - 1
FOR current IN start_year..end_year-1 LOOP 
    -- Insert into the new table data cumulatively created with FOR LOOP
    INSERT INTO actors
    -- CTE of previous year's data, starting from the start year 
    -- This table will initiate as empty table, since cumulative data starts from one year before data collection
    -- Culumative table script always joins the previous_year to the current_year
    WITH previous_year AS (
        SELECT * FROM actors
        WHERE current_year = current
    ), 
    -- CTE of current year's data, starting from the start year + 1
    current_year AS (
        SELECT actor,
               actorid,
               -- Aggregated array of composite data struct that stores data in array of 'film' type stucts for all films for the actor from the year
               ARRAY_AGG(
                   -- Composite array data struct of type 'film' that compresses each film from an actor into a single json-like data structure
                   ARRAY[ROW(
                       film,
                       votes,
                       rating,
                       year,
                       filmid
                   )::films] 
               ORDER BY rating DESC
               ) AS films,
               year AS current_year
        FROM actor_films
        WHERE year = current + 1
        GROUP BY actor, actorid, year
    ), 
    combined_years AS (
        -- Culumative table join for current and previous year that coalesces null data (key for first step)
        SELECT COALESCE(cy.actor, py.actor) AS actor,
               COALESCE(cy.actorid, py.actorid) AS actorid,    
               -- Boolean Tag if the actor had any films in the current year
               CASE
                 WHEN cy.current_year IS NOT NULL THEN TRUE
                 ELSE FALSE
               END AS is_active,
               -- Add one year to previous_year current year to get proper coalesce of combined current_year when actor is not active (cy.current_year is null)
               COALESCE(cy.current_year, py.current_year +1) AS current_year,
               -- Update the films array by setting films to the current year films when previous year is null (i.e. a new entry)
               -- or set combined the arrays of previous year films to the current year films for active actor
               -- or carry over previous year film array when actor becomes not active
               CASE 
                 WHEN py.films IS NULL THEN cy.films
                 WHEN cy.current_year IS NOT NULL THEN py.films || cy.films
                 ELSE py.films
               END        
        FROM current_year as cy
        FULL OUTER JOIN previous_year as py
        ON cy.actorid = py.actorid
    )
    -- Main statement of combined tables to commit to table from each culumative year
    SELECT 
        cy.actor,
        cy.actorid,
        -- Use Enum quality_class type stuct data to set the quality of actor based on overall flim rating
        CASE 
            WHEN avg_rating > 8 THEN 'star'
            WHEN avg_rating > 7 THEN 'good'
            WHEN avg_rating > 6 THEN 'average'
            ELSE 'bad'
        END::quality_class AS quality_class,
        cy.is_active,
        cy.current_year,
        cy.films
    -- Self-select FROM statement that uses the average film rating from all films up to the current year to determine quality class rating
    FROM (
        SELECT 
            actor,
            actorid,
            is_active,
            current_year,
            films,
            (SELECT AVG((f).rating) 
	         FROM unnest(films) AS f) AS avg_rating
        FROM combined_years
      ) AS cy;
END LOOP;  
END $$;
-- Script ENDS for constructing the 'actors table'

--Create 'actors_scd table' with DDL
CREATE TABLE actors_scd
(
	actor text,
    actorid text, 
	quality_class quality_class,
	is_active boolean,
	start_date SMALLINT,
	end_date SMALLINT,
	current_year SMALLINT,
	PRIMARY KEY(actorid, start_date)
);

-- Script STARTS for populating 'actors_scd table'
INSERT INTO actors_scd
-- CTE that idenifies any change in quality class or active status
WITH actor_changes AS (
SELECT 
       actor,
       actorid,
	   current_year,
	   quality_class,
	   is_active,
       -- Use LAG to create boolean tag for status change in 'quality_class' or 'is_active dimensions'
       -- If LAG of 1 year differs from current_year, tagged as a changed or True (the previous and current years are not equal) 
       -- If they are the same, tagged as not changed or False
       -- Null values also tagged as True, for first time entries
       LAG(quality_class, 1) OVER(PARTITION BY actorid ORDER BY current_year) <> quality_class
	   OR
	   LAG(quality_class, 1) OVER (PARTITION BY actorid ORDER BY current_year) IS NULL
	   OR
	   LAG(is_active, 1) OVER(PARTITION BY actorid ORDER BY current_year) <> is_active
	   OR
	   LAG(is_active, 1) OVER (PARTITION BY actorid ORDER BY current_year) IS NULL AS changed
	 FROM actors
WHERE current_year <= 2020 
), 
-- CTE that marks each year with a change or no change. 
--- Addition of one on SUMS from year to year indicates a change, Equality of SUMS from year to year indicates no change
change_indicator AS (
SELECT 
       actor,
       actorid,
	   current_year,
	   quality_class,
	   is_active,
       -- Sum over the fully grouped partition by current_year and adds to the sum when the changed tag is True
       -- Year by year, the sum does not increase when all the group by elements are the same
	   SUM(CASE WHEN changed THEN 1 ELSE 0 END)
        OVER (PARTITION BY actorid ORDER BY current_year) as change_identifier
FROM actor_changes
GROUP BY actor, actorid, current_year, quality_class, is_active, changed
)
-- Creates the proper record with start and end date of the change as data is aggregated by the change indicator
-- All years that have the same sum in the change_indentifier means the status of quality_class or is_active did not change
-- MIN and MAX over this grouped partition gives the bounds for the SCD
SELECT 
      actor,
	  actorid,
	  quality_class, 
	  is_active,
	  MIN(current_year) AS start_date,
	  MAX(current_year) AS end_date,
	  2020 AS current_year
FROM change_indicator
GROUP BY actor, actorid, quality_class, is_active, change_identifier
ORDER BY actor, actorid, change_identifier;
-- Script ENDS for populating 'actors_scd table'