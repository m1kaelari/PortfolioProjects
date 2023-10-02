/*
Created by: Mikael Aringberg
Date: 25/09-2023
Purpose: Memphis is one of the most dangerous and high crime rated cities in the US with Tenessee being one of the most dangerous states.
		 This dataset has been collected from the Memphis Police Department with crime data reaching all the way back to 1983.
		 In this script I will clean the data brought from the MPD, analyze it and lastly visualize it in Power BI.
*/

--------------------------------------------------------------------------------------------------------------------------
/*
SECTION 1: CLEANING AND STRUCTURING OUR DATA
*/


-- Some of the City names has been misspelled (MEMPHIS, mphs, MemhisTN, MEM etc.) and will all be formatted to Memphis
-- Changing City name

UPDATE crime_data
SET city = 'Memphis';

-- Making sure there are no anomalies left
SELECT *
FROM your_table_name
WHERE city_column_name NOT LIKE 'Memphis';

-- Same process but with the State

UPDATE crime_data
SET state = 'TN';

--------------------------------------------------------------------------------------------------------------------------

-- From the start, the Offense Date was structured; d/m/y tt:tt:tt AM/PM and I will divide these into smaller datapoints (date, time, am/pm)
-- I would remove the time in other datasets but since this is crime based, time is more important
-- Dividing offense_date column

-- First I will add the new column 'time' to the table
ALTER TABLE crime_data
ADD COLUMN time TEXT;

-- Adding 'am_pm' as well
ALTER TABLE crime_data
ADD COLUMN am_pm TEXT;

-- Here I use SUBSTR to choose which indexes from offense_date I want for each column
UPDATE crime_data
SET
    offense_date = SUBSTR(offense_date, 1, 10),
    time = SUBSTR(offense_date, 12, 9),
    am_pm = SUBSTR(offense_date, 21, 2);


-- As I said in the description, this dataset covers crime data going back to 1983, I will only keep dates >= January 1 2006 00:00:01 AM
-- I choose the year 2006 since that is the year that The City of Memphis launched 'Operation: Safe Community'
-- Keeping relevant dates

DELETE FROM 
	crime_data
WHERE 
	offense_date < '01/01/2006';

-- In this query I find out that some of the data earlier than 2006 has not been removed so this query removes them as well

SELECT
	substr(offense_date, 7, 10) as [Year],
	count(Category),
	*
FROM
	crime_data
WHERE
	Year < '2006'
GROUP BY
	Year
ORDER BY
	Year DESC;
	
-- This query deletes the remaining data of years not yet removed between the years 2005-1972
	
DELETE FROM crime_data
WHERE
    offense_date LIKE '%2005',
	OR offense_date LIKE '%2004',
    OR offense_date LIKE '%2003'
    OR offense_date LIKE '%2002'
    OR offense_date LIKE '%2001'
-- all the way down to;
    OR offense_date LIKE '%1972';

--------------------------------------------------------------------------------------------------------------------------
-- In the dataset some Crime IDs have duplicates but different crimes, this could be because multiple crimes were commited at the same time
-- but a individual ID is still necessary for a more precise analysis
-- Checking for Duplicates

SELECT crime_id, COUNT(crime_id) AS count
FROM your_table_name
GROUP BY crime_id
HAVING count > 1;

-- The Crime ID consists of many numbers which most likely represent a prefix, location, metadata or similar. In the real world the duplicate
-- would need to be updated according to this system but since I do not have access to that type of information I will only change the last
-- number of the ID to one number after the duplicate (if the ID ends with 34 the duplicate will become 35).
-- Removing Duplicates

UPDATE crime_data
SET crime_id = 'xxxxxxxxxz [xx:xxx]' -- The 'z' is the only thing being changed to become a Unique Value
WHERE crime_id = 'xxxxxxxxxx [xx:xxx]' AND agency_crimetype_id = 'crimetype_name'; -- I choose Crime type rather than Category since Category is more general


-- Here I will drop the columns I feel are not necessary to continue the analysis without losing important datapoints.
-- I used SQLite and did this manually but for other SQL Programs this would be my method.
-- Removing Columns

ALTER TABLE
	crime_data
DROP COLUMN
	CommunityNeighborhoodsBoundaries,
	CommunityNeighborhoodsBoundaries1,
	CommunityNeighborhoodsBoundaries2,
	Mid-SouthFairgroundsHalfMileBuffer,
	CrosstownConcourseHalfMileBuffer,
	CouncilDistrictBoundariesDec2022,
	CouncilSuperDistrictBoundariesDec2022

--------------------------------------------------------------------------------------------------------------------------
/*
SECTION 2: ANALYZING OUR DATA
*/

-- This query shows the top crimes in Memphis and the total crime count for each Category

SELECT
	Category,
	COUNT(*) AS [TotalCrimes]
FROM
	crime_data
GROUP BY
	Category
ORDER BY
	TotalCrimes DESC;



-- This query gives me a insight of the most common crime for every Category and the total count to each Category

SELECT
    c.Category,
    sub.MostCommonCrimeType,
    COUNT(*) AS TotalCrimesForMostCommon
FROM
    crime_data c
INNER JOIN (
    SELECT
        Category,
        MAX(agency_crimetype_id) AS MostCommonCrimeType
    FROM
        crime_data
    GROUP BY
        Category
) sub
ON
    c.Category = sub.Category AND c.agency_crimetype_id = sub.MostCommonCrimeType
GROUP BY
    c.Category, sub.MostCommonCrimeType
ORDER BY 
    TotalCrimesForMostCommon DESC;

	
-- Most crimes do not have a location or zip registered so the NULL in this query can be seen as 'Unknown'
-- This query shows us wich area (ZIP) have the most crimes commited

SELECT
	ShelbyCountyZipCodes AS [ZipCode],
	COUNT(*) AS [TotalCrimesZip]
FROM
	crime_data
GROUP BY
	ZipCode
ORDER BY
	TotalCrimesZip DESC
	
-- Most common time for crime (AM or PM)
-- This query shows that from the data containing AM or PM, there has been 474 568 more crimes committed in the PM

SELECT
	am_pm,
	COUNT(*) AS [TotalCrimesAMorPM]
FROM
	crime_data
GROUP BY
	am_pm
ORDER BY
	TotalCrimesAMorPM;
	
-- Five most common crimes during PM times

SELECT
	agency_crimetype_id,
	COUNT(*) AS [TotalCrimesAMorPM]
FROM
	crime_data
WHERE
	am_pm = 'PM'
GROUP BY
	am_pm,
	agency_crimetype_id
ORDER BY
	TotalCrimesAMorPM DESC
LIMIT
	5;

-- For some reason this query shows me the year 2023 even though it does not exist in the database, so for a more precise view I will exclude 2023 from it.
-- This insight shows us that since 2006 the crime rate has dropped and became the lowest (since 2006) in 2021 which could also be because of the pandemic.
-- In 2022 15 308 more crimes were committed compared to 2021 and in general the crime rates have dropped most years since 'Safe Community' started.
-- Overview of total crimes committed every year between 2006-2022
	
SELECT
	substr(offense_date, 7, 10) as [Year],
	count(Category) AS [TotalCrimesYear]
FROM
	crime_data
WHERE
	Year  != '2023'
GROUP BY
	Year
ORDER BY
	TotalCrimesYear DESC;
	
--------------------------------------------------------------------------------------------------------------------------
/*
SECTION 3: VISUALIZING MY DATA
*/

-- To see my visualizations on this project and other projects, visit my portfolio which you can find on my Linkedin


