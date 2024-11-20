-- Update the 'Average_Video_Length_Min' column to store numerical values only
UPDATE channels
SET Average_Video_Length_Min = CAST(REPLACE(LTRIM(RTRIM(SUBSTRING(Average_Video_Length_Min, 1, CHARINDEX(' ', Average_Video_Length_Min) - 1))), ' ', '') AS FLOAT)
WHERE Average_Video_Length_Min LIKE '%minutes%';

-- Select all unique categories for verification
SELECT DISTINCT Category
FROM channels;

-- Find channels with the 'Unknown' category
SELECT *
FROM channels
WHERE Category = 'Unknown';

-- Update the category for a specific channel
UPDATE channels
SET Category = 'Lifestyle'
WHERE Channel = 'Ben Lionel Scott';

-- Clean the 'Engagement_Rate' column by removing '%' and converting to FLOAT
UPDATE channels
SET Engagement_Rate = 
    CAST(REPLACE(LTRIM(RTRIM(SUBSTRING(Engagement_Rate, 1, LEN(Engagement_Rate) - 1))), '%', '') AS FLOAT)
WHERE Engagement_Rate LIKE '%';

-- Add columns to store lower and maximum monthly earnings as FLOAT
ALTER TABLE channels
ADD Lower_Monthly_Earning FLOAT,
    Max_Monthly_Earning FLOAT;

-- Remove spaces from the 'Monthly_Earning' column
UPDATE channels
SET Monthly_Earning = REPLACE(Monthly_Earning, ' ', '');

-- Parse and update the lower and upper monthly earnings based on ranges
UPDATE channels
SET 
    Lower_Monthly_Earning = 
    CASE
        WHEN Monthly_Earning LIKE '$%K-%' 
        THEN CAST(REPLACE(SUBSTRING(Monthly_Earning, 2, CHARINDEX('-', Monthly_Earning) - 3), 'K', '') AS FLOAT) * 1000
        WHEN Monthly_Earning LIKE '$%M-%' 
        THEN CAST(REPLACE(SUBSTRING(Monthly_Earning, 2, CHARINDEX('-', Monthly_Earning) - 3), 'M', '') AS FLOAT) * 1000000
        ELSE CAST(SUBSTRING(Monthly_Earning, 2, CHARINDEX('-', Monthly_Earning) - 3) AS FLOAT)
    END,
    Max_Monthly_Earning = 
    CASE
        WHEN SUBSTRING(Monthly_Earning, CHARINDEX('-', Monthly_Earning) + 1, LEN(Monthly_Earning)) LIKE '%K' 
        THEN CAST(REPLACE(SUBSTRING(Monthly_Earning, CHARINDEX('-', Monthly_Earning) + 2, LEN(Monthly_Earning)), 'K', '') AS FLOAT) * 1000
        WHEN SUBSTRING(Monthly_Earning, CHARINDEX('-', Monthly_Earning) + 1, LEN(Monthly_Earning)) LIKE '%M' 
        THEN CAST(REPLACE(SUBSTRING(Monthly_Earning, CHARINDEX('-', Monthly_Earning) + 2, LEN(Monthly_Earning)), 'M', '') AS FLOAT) * 1000000
        ELSE CAST(SUBSTRING(Monthly_Earning, CHARINDEX('-', Monthly_Earning) + 2, LEN(Monthly_Earning)) AS FLOAT)
    END;

-- Remove the 'Monthly_Earning' column after parsing its values
ALTER TABLE channels
DROP COLUMN Monthly_Earning;

-- Clean the 'Rank' column to keep only numeric values and convert to INT
UPDATE channels
SET Rank = CAST('' + 
                CAST(SUBSTRING(Rank, PATINDEX('%[0-9]%', Rank), LEN(Rank)) AS VARCHAR) AS INT);

-- Convert 'Subscribers' to an integer value, multiplying by 1M for values with 'M'
UPDATE channels
SET Subscribers = 
    CAST(CAST(REPLACE(Subscribers, 'M', '') AS FLOAT) * 1000000 AS INT)
WHERE Subscribers LIKE '%M%';

-- Drop the 'Total_Views_Last_Month' column as it is no longer needed
ALTER TABLE channels
DROP COLUMN Total_Views_Last_Month;

-- Rename the 'Video_Upload_Frequency' column for clarity
EXEC sp_rename 'channels.Video_Upload_Frequency', 'Video_Upload_Frequency_per_Week', 'COLUMN';

-- Convert 'Video_Upload_Frequency_per_Week' to numerical values
UPDATE dbo.channels
SET [Video_Upload_Frequency_per_Week] = 
    CAST(SUBSTRING([Video_Upload_Frequency_per_Week], 1, CHARINDEX(' ', [Video_Upload_Frequency_per_Week]) - 1) AS FLOAT);

-- Clean and convert 'Videos' to integer values, handling 'K' (thousands)
UPDATE dbo.channels
SET [Videos] = 
    CASE 
        WHEN [Videos] LIKE '%K' 
        THEN CAST(CAST(SUBSTRING([Videos], 1, LEN([Videos]) - 1) AS FLOAT) * 1000 AS INT)
        ELSE CAST([Videos] AS INT)
    END;

-- Convert 'Views' to BIGINT, handling 'B' (billions) and 'M' (millions)
UPDATE dbo.channels
SET [Views] = 
    CASE 
        WHEN [Views] LIKE '%B' 
        THEN CAST(CAST(SUBSTRING([Views], 1, LEN([Views]) - 1) AS FLOAT) * 1000000000 AS BIGINT)
        WHEN [Views] LIKE '%M' 
        THEN CAST(CAST(SUBSTRING([Views], 1, LEN([Views]) - 1) AS FLOAT) * 1000000 AS BIGINT)
        ELSE 
            CASE 
                WHEN ISNUMERIC([Views]) = 1 
                THEN CAST([Views] AS BIGINT)
                ELSE NULL
            END
    END;

-- Drop the 'Country_Code' column
ALTER TABLE dbo.channels
DROP COLUMN [Country_Code];

-- Alter the data types of columns for consistency
ALTER TABLE dbo.channels
ALTER COLUMN Engagement_Rate FLOAT;
ALTER TABLE dbo.channels
ALTER COLUMN Rank INT;
ALTER TABLE dbo.channels
ALTER COLUMN Average_Video_Length_Min FLOAT;
ALTER TABLE dbo.channels
ALTER COLUMN Video_Upload_Frequency_per_Week FLOAT;
ALTER TABLE dbo.channels
ALTER COLUMN Videos INT;
ALTER TABLE dbo.channels
ALTER COLUMN Views BIGINT;

-- Update a specific channel's views
UPDATE channels
SET Views = 60690
WHERE Channel_ID = 'UCVUdHi-tdW5AKdzMiTPG97Q';

-- Verify column details after cleaning
SELECT 
    COLUMN_NAME, 
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH AS [Length],
    NUMERIC_PRECISION AS [Precision],
    NUMERIC_SCALE AS [Scale]
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'channels' 
    AND TABLE_SCHEMA = 'dbo';

-- Ensure 'date_joined' column is consistent
UPDATE [Youtube_DB].[dbo].[channels]
SET date_joined = CONVERT(VARCHAR(10), CAST(date_joined AS DATE), 23)
WHERE ISDATE(date_joined) = 1;

-- Alter the 'date_joined' column to DATE data type
ALTER TABLE [Youtube_DB].[dbo].[channels]
ALTER COLUMN date_joined DATE;

-- Manually update a specific channel's date
UPDATE [Youtube_DB].[dbo].[channels]
SET date_joined = 'Mar 28, 2018'
WHERE Channel_ID = 'UC2tsySbe9TNrI-xh2lximHA';
