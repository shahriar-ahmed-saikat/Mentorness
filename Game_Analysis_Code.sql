use game_analysis;
-- 1. Extract `P_ID`, `Dev_ID`, `PName`, and `Difficulty_level` of all players at Level 0.
select
	level_details2.P_ID,level_details2.Dev_Id,player_details.PName,level_details2.Difficulty
from
	level_details2
    join player_details
    on level_details2.P_ID = player_details.P_ID
where
	level_details2.Level=0
;
-- 2. Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3 stages are crossed.
select
	player_details.L1_Code,avg(level_details2.Kill_Count) as avg_kill_counts
from
	level_details2
    join player_details
    on level_details2.P_ID = player_details.P_ID
where
	level_details2.Lives_Earned=2 and level_details2.Stages_crossed>=3
group by
	player_details.L1_Code;
-- 3. Find the total number of stages crossed at each difficulty level for Level 2 with players using `zm_series` devices. 
-- Arrange the result in decreasing order of the total number of stages crossed.
select
	level_details2.Dev_Id,
    level_details2.Difficulty,
    level_details2.Level,
    sum(level_details2.Stages_crossed) as total_stages_crossed
from
	level_details2
where
	level_details2.Level=2 and level_details2.Dev_Id like 'zm%'
group by
	 level_details2.Dev_Id,
     level_details2.Difficulty
order by
	total_stages_crossed asc;
-- 4.Extract `P_ID` and the total number of unique dates for those players who have played games on multiple days
select
	level_details2.P_ID,count(distinct level_details2.start_datetime) as count_unique_date
from
	level_details2
group by
	level_details2.P_ID
having
	count(distinct level_details2.start_datetime)>1
;
-- 5.Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than the average kill count for Medium difficulty
WITH MediumAvg AS (
    SELECT AVG(Kill_Count) AS avg_kill
    FROM level_details2
    WHERE Difficulty = 'Medium'
)
SELECT
    ld.P_ID,
    ld.Level,
    SUM(ld.Kill_Count) AS total_kills
FROM
    level_details2 AS ld
INNER JOIN
    MediumAvg ON ld.Difficulty = 'Medium'
WHERE
    ld.Kill_Count > MediumAvg.avg_kill
GROUP BY
    ld.P_ID,
    ld.Level;
-- 6.Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level 0. Arrange in ascending order of level.
SELECT 
    level_details2.Level,
    CASE
        WHEN player_details.L1_Code IS NULL THEN player_details.L2_Code
        ELSE player_details.L1_Code
    END AS Level_code,
    SUM(level_details2.Lives_Earned) AS total_lives
FROM
    level_details2
JOIN player_details 
ON level_details2.P_ID = player_details.P_ID
WHERE
    level_details2.Level!= 0
GROUP BY
    level_details2.Level,
    Level_code
ORDER BY
    level_details2.Level ASC;
-- 7. Find the top 3 scores based on each `Dev_ID` and rank them in increasing order using `Row_Number`. Display the difficulty as well
with top_three as(
	select 
	level_details2.Dev_Id,
    level_details2.Score,
	level_details2.Difficulty,
    row_number() over(partition by level_details2.Dev_Id order by level_details2.Score desc) as row_s
from
	level_details2
)
select 
	top_three.*
from
	top_three
where
	row_s<=3
;
-- 8.Find the `first_login` datetime for each device ID
select
	level_details2.Dev_Id,
    min(level_details2.start_datetime) as first_login
from
	level_details2
group by
	level_details2.Dev_Id;
-- 9. Find the top 5 scores based on each difficulty level and rank them in increasing order using `Rank`. Display `Dev_ID` as well.
with top_five as(
	select
		level_details2.Dev_Id,
		level_details2.Difficulty,
		level_details2.Score,
		rank() over(partition by level_details2.Difficulty order by level_details2.Score desc) as ranks
	from
		level_details2)
select
	top_five.*
from
	top_five
where
	ranks<=5;
-- 10.Find the device ID that is first logged in (based on `start_datetime`) for each player(`P_ID`). 
-- Output should contain player ID, device ID, and first login datetime.
select
	level_details2.P_ID,
    level_details2.Dev_Id,
    min(level_details2.start_datetime) as first_login
from
	level_details2
group by
	level_details2.P_ID,
    level_details2.Dev_Id;
-- 11.For each player and date, determine how many `kill_counts` were played by the playerso far.
-- a) Using window functions
select
	ld.P_ID,
    date(ld.start_datetime) as Dates,
    sum(ld.Kill_Count) over(partition by ld.P_ID order by ld.start_datetime) as total_kills
from
	level_details2 as ld
;
-- without window function
select
	ld.P_ID,
    date(ld.start_datetime) as dates,
    sum(ld.Kill_Count) as total_kill
from
	level_details2 as ld
group by
	1,
    2;
-- 12.Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`,
-- excluding the most recent `start_datetime
with Cummulative_Sum as(
	select
		ld.P_ID,
		max(ld.start_datetime) as max_dates,
		sum(ld.Stages_crossed) as total_stages
	from
		level_details2 as ld
	group by
		1
)
select
	cs.P_ID,
    cs.total_stages
from
	Cummulative_Sum as cs
	join level_details2
    on level_details2.P_ID=cs.P_ID
where
	level_details2.start_datetime<cs.max_dates
;
-- 13. Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`.

WITH TopScores AS (
    SELECT
        level_details2.P_ID,
        level_details2.Dev_Id,
        SUM(Score) AS total_score,
        row_number() OVER (PARTITION BY Dev_ID ORDER BY SUM(Score) DESC) AS ranked
    FROM
        level_details2
    GROUP BY
        1,2
)
SELECT
    P_ID,
    Dev_ID,
    total_score
FROM
    TopScores
WHERE
    ranked <= 3;
-- 14.Find players who scored more than 50% of the avg score scored by sum of scores for each player_id.
select
	ld.P_ID,
    sum(ld.Score) as total_score
from
	level_details2 as ld
group by
	1
having
	sum(ld.Score)>(select avg(total_score)*0.5
					from
						(select
							sum(level_details2.Score) as total_score
						from
							level_details2
						group by
							level_details2.P_ID)
						as avg_socres)
;
-- 15.Create a stored procedure to find the top `n` `headshots_count` based on each `Dev_ID`
-- and rank them in increasing order using `Row_Number`. Display the difficulty as well.
DELIMITER //
CREATE PROCEDURE FindTopHeadshots(
    IN n INT
)
BEGIN
    SELECT
        ld.Dev_Id,
        ld.Difficulty,
        ld.Headshots_Count,
        RANK() OVER (PARTITION BY ld.Dev_Id ORDER BY ld.Headshots_Count ASC) AS headshots_rank
    FROM
        level_details2 AS ld
    ORDER BY
        ld.Dev_Id,
        headshots_rank
    LIMIT n;
END //

DELIMITER ;


	

