-- Retrieve metadata for the 'trending' table columns.
-- This helps to understand the column names, data types, and max length for NVARCHAR columns.
SELECT 
    COLUMN_NAME, 
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'trending';


-- Clean and convert NVARCHAR columns that store numeric data to INT.
-- Ensure that only rows with numeric data (validated by ISNUMERIC) are converted.

-- Update numeric columns by removing whitespace and converting to INT.
UPDATE trending
SET 
    daily_rank = CAST(TRIM(daily_rank) AS INT),
    daily_movement = CAST(TRIM(daily_movement) AS INT),
    weekly_movement = CAST(TRIM(weekly_movement) AS INT),
    view_count = CAST(TRIM(view_count) AS INT),
    like_count = CAST(TRIM(like_count) AS INT),
    comment_count = CAST(TRIM(comment_count) AS INT)
WHERE 
    ISNUMERIC(TRIM(daily_rank)) = 1 AND
    ISNUMERIC(TRIM(daily_movement)) = 1 AND
    ISNUMERIC(TRIM(weekly_movement)) = 1 AND
    ISNUMERIC(TRIM(view_count)) = 1 AND
    ISNUMERIC(TRIM(like_count)) = 1 AND
    ISNUMERIC(TRIM(comment_count)) = 1;

-- Change the data type of cleaned columns to INT.
ALTER TABLE trending
ALTER COLUMN daily_rank INT;

ALTER TABLE trending
ALTER COLUMN daily_movement INT;

ALTER TABLE trending
ALTER COLUMN weekly_movement INT;

ALTER TABLE trending
ALTER COLUMN view_count INT;

ALTER TABLE trending
ALTER COLUMN like_count INT;

ALTER TABLE trending
ALTER COLUMN comment_count INT;


-- Identify columns still using NVARCHAR as their data type.
SELECT COLUMN_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'trending' AND DATA_TYPE = 'nvarchar';


-- Calculate the maximum lengths for NVARCHAR columns to optimize their sizes.
SELECT 
    MAX(LEN(title)) AS Max_Title_Length,
    MAX(LEN(channel_name)) AS Max_Channel_Name_Length,
    MAX(LEN(snapshot_date)) AS Max_Snapshot_Date_Length,
    MAX(LEN(country)) AS Max_Country_Length,
    MAX(LEN(description)) AS Max_Description_Length,
    MAX(LEN(thumbnail_url)) AS Max_Thumbnail_URL_Length,
    MAX(LEN(video_id)) AS Max_Video_ID_Length,
    MAX(LEN(channel_id)) AS Max_Channel_ID_Length,
    MAX(LEN(video_tags)) AS Max_Video_Tags_Length,
    MAX(LEN(publish_date)) AS Max_Publish_Date_Length,
    MAX(LEN(langauge)) AS Max_Language_Length,
    MAX(LEN(normalized_channelTitle)) AS Max_Normalized_Channel_Title_Length
FROM 
    trending;

-- Alter NVARCHAR columns to fit their optimized sizes.
ALTER TABLE trending
ALTER COLUMN title NVARCHAR(130);
ALTER TABLE trending
ALTER COLUMN channel_name NVARCHAR(51);
ALTER TABLE trending
ALTER COLUMN snapshot_date NVARCHAR(11);
ALTER TABLE trending
ALTER COLUMN country NVARCHAR(3);
ALTER TABLE trending
ALTER COLUMN description NVARCHAR(MAX);  -- Preserve max length for large text.
ALTER TABLE trending
ALTER COLUMN thumbnail_url NVARCHAR(49);
ALTER TABLE trending
ALTER COLUMN video_id NVARCHAR(12);
ALTER TABLE trending
ALTER COLUMN channel_id NVARCHAR(25);
ALTER TABLE trending
ALTER COLUMN video_tags NVARCHAR(574);
ALTER TABLE trending
ALTER COLUMN publish_date NVARCHAR(26);
ALTER TABLE trending
ALTER COLUMN langauge NVARCHAR(8);
ALTER TABLE trending
ALTER COLUMN normalized_channelTitle NVARCHAR(51);



-- Check for invalid date values in 'snapshot_date' and 'publish_date'.
SELECT 
    snapshot_date,
    publish_date
FROM 
    trending
WHERE 
    TRY_CAST(snapshot_date AS DATE) IS NULL 
    OR TRY_CAST(publish_date AS DATE) IS NULL;

-- Update 'publish_date' by removing timezone information.
UPDATE trending
SET publish_date = CAST(publish_date AS DATE);

-- Update 'snapshot_date' by converting it to DATE.
UPDATE trending
SET snapshot_date = CAST(snapshot_date AS DATE);

-- Change the data types of date columns to DATE.
ALTER TABLE trending
ALTER COLUMN publish_date DATE;
ALTER TABLE trending
ALTER COLUMN snapshot_date DATE;



-- Count the number of missing (NULL) values for each column.
SELECT 
    SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END) AS Missing_Title,
    SUM(CASE WHEN channel_name IS NULL THEN 1 ELSE 0 END) AS Missing_Channel_Name,
    SUM(CASE WHEN daily_rank IS NULL THEN 1 ELSE 0 END) AS Missing_Daily_Rank,
    SUM(CASE WHEN daily_movement IS NULL THEN 1 ELSE 0 END) AS Missing_Daily_Movement,
    SUM(CASE WHEN weekly_movement IS NULL THEN 1 ELSE 0 END) AS Missing_Weekly_Movement,
    SUM(CASE WHEN snapshot_date IS NULL THEN 1 ELSE 0 END) AS Missing_Snapshot_Date,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS Missing_Country,
    SUM(CASE WHEN view_count IS NULL THEN 1 ELSE 0 END) AS Missing_View_Count,
    SUM(CASE WHEN like_count IS NULL THEN 1 ELSE 0 END) AS Missing_Like_Count,
    SUM(CASE WHEN comment_count IS NULL THEN 1 ELSE 0 END) AS Missing_Comment_Count,
    SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END) AS Missing_Description,
    SUM(CASE WHEN thumbnail_url IS NULL THEN 1 ELSE 0 END) AS Missing_Thumbnail_URL,
    SUM(CASE WHEN video_id IS NULL THEN 1 ELSE 0 END) AS Missing_Video_ID,
    SUM(CASE WHEN channel_id IS NULL THEN 1 ELSE 0 END) AS Missing_Channel_ID,
    SUM(CASE WHEN video_tags IS NULL THEN 1 ELSE 0 END) AS Missing_Video_Tags,
    SUM(CASE WHEN publish_date IS NULL THEN 1 ELSE 0 END) AS Missing_Publish_Date,
    SUM(CASE WHEN langauge IS NULL THEN 1 ELSE 0 END) AS Missing_Language,
    SUM(CASE WHEN normalized_channelTitle IS NULL THEN 1 ELSE 0 END) AS Missing_Normalized_Channel_Title
FROM trending;

-- Inspect rows where 'langauge' is NULL.
SELECT *
FROM trending
WHERE langauge IS NULL;

-- Inspect distinct language values for normalization.
SELECT DISTINCT langauge
FROM trending;


-- Normalize language values based on patterns and specific cases.
UPDATE trending
SET langauge = CASE
    WHEN langauge LIKE 'en%' THEN 'en'
    WHEN langauge LIKE 'es%' THEN 'es'
    WHEN langauge = 'fr' OR langauge LIKE 'fr%' THEN 'fr'
    WHEN langauge LIKE 'zh%' THEN 'zh'
    WHEN langauge = 'pl' THEN 'pl'
    WHEN langauge = 'ar' THEN 'ar'
    ELSE langauge  -- Preserve any other values as they are.
END
WHERE langauge IN ('en', 'es', 'fr', 'zh', 'pl', 'ar') 
   OR langauge LIKE 'en%' 
   OR langauge LIKE 'es%' 
   OR langauge LIKE 'fr%' 
   OR langauge LIKE 'zh%' 
   OR langauge LIKE 'pl%' 
   OR langauge LIKE 'ar%';

-- Remove rows with undesired language values.
DELETE FROM trending
WHERE langauge NOT LIKE 'en%' 
  AND langauge NOT LIKE 'es%' 
  AND langauge NOT IN ('fr', 'zh', 'pl', 'ar') 
  AND langauge IS NOT NULL;



