# SCD Table Documentation & Usage Guidelines

## Overview:

The `actors_scd table` is a Slowly Changing Dimension (SCD) Type 2 implementation of the original `actors table` that tracks historical changes to an actor’s `quality_class` and `is_active` status. This data definition ensures that all historical states of the two dimensionss of an actor are preserved, enabling analysis of actor performance evaluation and film activity over time.

### Table Design:

- actor (TEXT): The name of the actor.
- actorid (INTEGER): The unique identifier for the actor. This key is a primary key used for tracking an actor across multiple years.
- quality_class (ENUM): A classification that reflects the overall quality of an actor’s portfolio based on aggregated film ratings by users. It can be one of the following values:
    - 'star' (Rating > 8)
    - 'good' (Rating > 7)
    - 'average' (Rating > 6)
    - 'bad' (Rating ≤ 6)
- is_active (BOOLEAN): A classification that indicates whether the actor was active in the current year. This boolean flag helps differentiate periods when an actor was actively appearing in films from periods of inactivity in the movies.
- start_date (DATE): The first year when the quality_class and is_active status were recorded for this actor. The record will span until the end_date year unless a change occurs.
- end_date (DATE): The last year during which the quality_class and is_active status remained unchanged. The record is valid until the end of the end_date year, or until a new status change is detected.
- current_year (INTEGER): A fixed year (as of now, 2020) used for tracking the current status of the actor at the time of data insertion.

### SCD Design Process:

#### Detect Changes:

The actor_changes CTE uses the LAG window function to detect changes in the actor’s quality_class and is_active status compared to the previous year. If the status differs or if it's the first entry, the record is marked as "changed."

#### Group Change Intervals:

The change_indicator CTE assigns an identifier to groups of years with the same status using a cumulative sum of the "changed" flag.
This allows for grouping consecutive years of unchanged status into a single record, defining the start_date and end_date for each period.

#### Historical Record Generation:

The final SELECT query generates records for each period of stability (defined by the change_identifier), indicating the period during which an actor's status remained unchanged.

The record includes start_date and end_date to represent the period of stability.
### Usage Guidelines:

#### Querying Actor Status:
To retrieve the status of an actor at a specific point in time, use the `start_date` and `end_date` fields to filter for relevant periods:

    SELECT * 
    FROM actors_scd 
    WHERE actorid = 123 
    AND 2020 BETWEEN start_date AND end_date;

This query will return the actor's status in 2020, including the `quality_class`, `is_active`, and the corresponding time period.

#### Handling Updates:
When new data is inserted into the actors table, it may result in changes to an actor’s quality_class or is_active status. In such cases, a new record will be created in actors_scd to represent the updated status, with an updated start_date and end_date values.

If there are no changes, the actor’s status remains stable within the existing records.

#### Tracking Historical Trends:
This table allows for efficient analysis of historical trends by querying the quality_class and is_active status over time. Use the start_date and end_date to summarize performance, identify periods of activity/inactivity, and analyze changes in actor performance.

#### Data Integrity:
To ensure the integrity of historical data, ensure that changes to quality_class or is_active are accurately reflected in the actors table, as these trigger changes in the actors_scd table.
Example Use Case:

To track an actor’s progression over the years, you can query the SCD table as follows:

SELECT actor, actorid, quality_class, start_date, end_date
FROM actors_scd
WHERE actorid = 123
ORDER BY start_date;
This will provide a timeline of all the periods the actor was classified under different quality_class labels, helping in performance evaluation over time.

Additional Considerations:
Retention and Expiration:
If needed, introduce additional logic to handle the retirement or expiration of an actor’s status (e.g., when the actor is no longer active after a certain date).
Load Optimization:
Consider indexing on actorid, start_date, and end_date for optimal performance when querying actor histories or performing aggregations.
Time-Range Queries:
The actors_scd table is ideal for generating reports and conducting historical analyses, as it allows you to efficiently query actor status over time intervals.