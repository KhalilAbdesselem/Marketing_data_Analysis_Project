-- Check for null values in each column of the 'channels' table.
-- This helps identify missing or incomplete data before performing transformations.
SELECT 
    SUM(CASE WHEN Average_Video_Length IS NULL THEN 1 ELSE 0 END) AS Average_Video_Length_Null_Count,
    SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS Category_Null_Count,
    SUM(CASE WHEN Channel IS NULL THEN 1 ELSE 0 END) AS Channel_Null_Count,
    SUM(CASE WHEN Channel_ID IS NULL THEN 1 ELSE 0 END) AS Channel_ID_Null_Count,
    SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS Country_Null_Count,
    SUM(CASE WHEN Engagement_Rate IS NULL THEN 1 ELSE 0 END) AS Engagement_Rate_Null_Count,
    SUM(CASE WHEN Monthly_Earning IS NULL THEN 1 ELSE 0 END) AS Monthly_Earning_Null_Count,
    SUM(CASE WHEN Subscribers IS NULL THEN 1 ELSE 0 END) AS Subscribers_Null_Count,
    SUM(CASE WHEN Views IS NULL THEN 1 ELSE 0 END) AS Views_Null_Count
FROM channels;


-- Update the 'Subscribers' column to convert values containing 'M' (million) or 'K' (thousand) into numeric form.
-- For example, "1.2M" becomes 1200000 and "450K" becomes 450000.
UPDATE channels
SET Subscribers = 
    CASE 
        WHEN Subscribers LIKE '%M%' THEN 
            CAST(CAST(SUBSTRING(Subscribers, 1, CHARINDEX('M', Subscribers) - 1) AS DECIMAL(10, 2)) * 1000000 AS BIGINT)
        WHEN Subscribers LIKE '%K%' THEN 
            CAST(CAST(SUBSTRING(Subscribers, 1, CHARINDEX('K', Subscribers) - 1) AS DECIMAL(10, 2)) * 1000 AS BIGINT)
        ELSE 
            -- If the value is already numeric, ensure it is cast as BIGINT.
            CAST(REPLACE(Subscribers, ',', '') AS BIGINT)
    END
WHERE Subscribers LIKE '%M%' OR Subscribers LIKE '%K%' OR ISNUMERIC(REPLACE(Subscribers, ',', '')) = 1;


-- Update the 'Views' column to clean and convert it to numeric format.
-- Remove characters like '+' or '-' and commas for consistency.
UPDATE channels
SET Views = 
    CASE
        WHEN Views LIKE '%+%' THEN 
            -- Extract and clean the part before '+' and remove commas.
            CAST(REPLACE(SUBSTRING(Views, 1, CHARINDEX('+', Views) - 1), ',', '') AS BIGINT)
        WHEN Views LIKE '%-%' THEN 
            -- Extract and clean the part before '-' and remove commas.
            CAST(REPLACE(SUBSTRING(Views, 1, CHARINDEX('-', Views) - 1), ',', '') AS BIGINT)
        ELSE 
            -- Handle values without special characters and remove commas.
            CAST(REPLACE(Views, ',', '') AS BIGINT)
    END
WHERE Views LIKE '%+%' OR Views LIKE '%-%' OR ISNUMERIC(REPLACE(Views, ',', '')) = 1;

-- Change the data type of the 'Views' column to BIGINT for efficient storage and computation.
ALTER TABLE channels
ALTER COLUMN Views BIGINT;



-- Add two new columns: 'min_Monthly_Earning' and 'max_Monthly_Earning' to store the range of monthly earnings.
ALTER TABLE channels
ADD min_Monthly_Earning FLOAT,
    max_Monthly_Earning FLOAT;


-- Update the new columns to store the minimum and maximum values from the 'Monthly_Earning' range.
UPDATE channels
SET 
    min_Monthly_Earning = CASE 
        -- Extract the first number in the range and clean it.
        WHEN CHARINDEX('-', Monthly_Earning) > 0 THEN 
            CAST(REPLACE(REPLACE(SUBSTRING(Monthly_Earning, 2, CHARINDEX('-', Monthly_Earning) - 2), ',', ''), '$', '') AS FLOAT)
        ELSE 
            -- If there is no range, treat the value as the minimum and clean it.
            CAST(REPLACE(REPLACE(Monthly_Earning, '$', ''), ',', '') AS FLOAT)
    END,
    max_Monthly_Earning = CASE 
        -- Extract the second number in the range and clean it.
        WHEN CHARINDEX('-', Monthly_Earning) > 0 THEN 
            CAST(REPLACE(REPLACE(SUBSTRING(Monthly_Earning, CHARINDEX('-', Monthly_Earning) + 1, LEN(Monthly_Earning)), ',', ''), '$', '') AS FLOAT)
        ELSE 
            NULL  -- If there is no range, leave the maximum as NULL.
    END
WHERE Monthly_Earning IS NOT NULL AND Monthly_Earning <> '';


--Final Cleanup

-- Remove the original 'Monthly_Earning' column after splitting it into two new columns.
ALTER TABLE channels
DROP COLUMN Monthly_Earning;


-- Check the final data types for all columns to ensure they are properly aligned.
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'channels';


-- Validate and ensure any date fields are properly cast to DATE format (if applicable).
SELECT COUNT(*)
FROM channels
WHERE TRY_CAST(Date AS DATE) IS NULL;

-- If there is a 'Date' column, update its data type.
ALTER TABLE channels
ALTER COLUMN Date DATE;
