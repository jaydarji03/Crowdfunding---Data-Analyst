use training_projects;
#1 -- Convert the Date fields to Natural Time
SELECT 
    ProjectID,
    FROM_UNIXTIME(created_at) AS CreatedDate,
    FROM_UNIXTIME(deadline) AS DeadlineDate,
    FROM_UNIXTIME(launched_at) AS LaunchedDate,
    FROM_UNIXTIME(successful_at) AS SuccessfulDate,
    FROM_UNIXTIME(updated_at) AS UpdatedDate,
    FROM_UNIXTIME(state_changed_at) AS StateChangedDate
FROM 
    projects;
drop table if exists calendar;
#2 -- Calendar Table
SELECT 
    DATE(MIN(FROM_UNIXTIME(created_at))) AS MinDate,
    DATE(MAX(FROM_UNIXTIME(created_at))) AS MaxDate
FROM 
    projects;

SET cte_max_recursion_depth = 10000;

CREATE TABLE calendar AS
WITH RECURSIVE DateSeries AS (
    SELECT DATE('2009-04-28') AS CalendarDate  -- Replace with your MinDate
    UNION ALL
    SELECT DATE_ADD(CalendarDate, INTERVAL 1 DAY)
    FROM DateSeries
    WHERE CalendarDate < DATE('2020-12-31')   -- Replace with your MaxDate
)
SELECT
    CalendarDate,
    
    -- A. Year
    YEAR(CalendarDate) AS Year,

    -- B. Month Number
    MONTH(CalendarDate) AS MonthNo,

    -- C. Month Full Name
    MONTHNAME(CalendarDate) AS MonthFullName,

    -- D. Quarter (Q1, Q2, Q3, Q4)
    CONCAT('Q', QUARTER(CalendarDate)) AS Quarter,

    -- E. YearMonth (YYYY-MMM)
    DATE_FORMAT(CalendarDate, '%Y-%b') AS YearMonth,

    -- F. Weekday Number (1=Sunday, 7=Saturday)
    DAYOFWEEK(CalendarDate) AS WeekdayNo,

    -- G. Weekday Name
    DAYNAME(CalendarDate) AS WeekdayName,

    -- H. Financial Month (April = FM1, ..., March = FM12)
    CASE
        WHEN MONTH(CalendarDate) = 4 THEN 'FM1'
        WHEN MONTH(CalendarDate) = 5 THEN 'FM2'
        WHEN MONTH(CalendarDate) = 6 THEN 'FM3'
        WHEN MONTH(CalendarDate) = 7 THEN 'FM4'
        WHEN MONTH(CalendarDate) = 8 THEN 'FM5'
        WHEN MONTH(CalendarDate) = 9 THEN 'FM6'
        WHEN MONTH(CalendarDate) = 10 THEN 'FM7'
        WHEN MONTH(CalendarDate) = 11 THEN 'FM8'
        WHEN MONTH(CalendarDate) = 12 THEN 'FM9'
        WHEN MONTH(CalendarDate) = 1 THEN 'FM10'
        WHEN MONTH(CalendarDate) = 2 THEN 'FM11'
        WHEN MONTH(CalendarDate) = 3 THEN 'FM12'
    END AS FinancialMonth,

    -- I. Financial Quarter (April–June = FQ1, etc.)
    CASE
        WHEN MONTH(CalendarDate) BETWEEN 4 AND 6 THEN 'FQ1'
        WHEN MONTH(CalendarDate) BETWEEN 7 AND 9 THEN 'FQ2'
        WHEN MONTH(CalendarDate) BETWEEN 10 AND 12 THEN 'FQ3'
        WHEN MONTH(CalendarDate) BETWEEN 1 AND 3 THEN 'FQ4'
    END AS FinancialQuarter

FROM DateSeries;
-- Join Calendar with projects
SELECT 
    p.ProjectID,
    c.Year,
    c.MonthFullName,
    c.Quarter,
    c.FinancialQuarter
FROM 
    projects p
JOIN 
    calendar c 
ON DATE(FROM_UNIXTIME(p.created_at)) = c.CalendarDate;

#3 -- Data Model
CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(255)
);

CREATE TABLE locations (
    location_id INT PRIMARY KEY,
    location_name VARCHAR(255),
    country VARCHAR(100)
);

CREATE TABLE creators (
    creator_id INT PRIMARY KEY,
    creator_name VARCHAR(255)
);

CREATE VIEW crowdfunding_data_model AS
SELECT
    p.ProjectID,
    p.name AS ProjectName,
    p.state,
    p.country,
    c.category_name AS Category,
    l.location_name AS Location,
    cr.creator_name AS Creator,
    FROM_UNIXTIME(p.created_at) AS CreatedDate,
    FROM_UNIXTIME(p.launched_at) AS LaunchedDate,
    FROM_UNIXTIME(p.deadline) AS DeadlineDate,
    FROM_UNIXTIME(p.successful_at) AS SuccessfulDate,
    p.goal,
    p.pledged,
    (p.pledged * p.static_usd_rate) AS AmountRaised_USD,
    p.backers_count,
    p.spotlight,
    p.staff_pick,
    p.blurb
FROM 
    projects p
LEFT JOIN 
    categories c ON p.category_id = c.category_id
LEFT JOIN 
    locations l ON p.location_id = l.location_id
LEFT JOIN 
    creators cr ON p.creator_id = cr.creator_id;
    
#4 -- convert Goal to usd
SELECT 
    ProjectID,
    name AS ProjectName,
    country,
    goal AS Goal_LocalCurrency,
    static_usd_rate,
    (goal * static_usd_rate) AS Goal_USD
FROM 
    projects;

-- Total Projects
SELECT 
    COUNT(*) AS ProjectID
FROM 
    training_projects.projects;


-- Total Categories
SELECT 
    COUNT(DISTINCT category_id) AS total_categories
FROM 
    training_projects.projects;


-- % of successful projects
SELECT 
    (SUM(CASE WHEN state = 'successful' THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS percent_successful_projects
FROM 
   training_projects.projects;


#5(1)-- Total Number of Projects based on Outcome
SELECT state, COUNT(*) AS total_projects
FROM training_projects.projects
GROUP BY state
ORDER BY total_projects DESC;


#5(2)-- Total Number of Projects Based on Locations --
SELECT country, COUNT(*) AS total_projects
FROM training_projects.projects
GROUP BY country
ORDER BY total_projects DESC;


#5(3) -- Total no.of projects based on category
SELECT 
    category_id,
    COUNT(ProjectID) AS Total_Projects
FROM 
    projects
GROUP BY 
    category_id
ORDER BY 
    Total_Projects DESC;
    
 
 
 #5(4)-- Total Number of Projects By Year, Quarter & Month --
SELECT 
    YEAR(FROM_UNIXTIME(created_at)) AS year,
    QUARTER(FROM_UNIXTIME(created_at)) AS quarter,
    MONTHNAME(FROM_UNIXTIME(created_at)) AS month,
    COUNT(*) AS total_projects
FROM 
    training_projects.projects
GROUP BY 
    YEAR(FROM_UNIXTIME(created_at)), 
    QUARTER(FROM_UNIXTIME(created_at)), 
    MONTHNAME(FROM_UNIXTIME(created_at))
ORDER BY 
    YEAR(FROM_UNIXTIME(created_at)) DESC, 
    QUARTER(FROM_UNIXTIME(created_at)), 
    MONTHNAME(FROM_UNIXTIME(created_at));
    
    
#6(1)-- Total Number of Projects By Amount Raised-
SELECT 
    ROUND(SUM(pledged * static_usd_rate), 2) AS total_amount_raised_usd
FROM 
    projects
WHERE 
    state = 'successful';

 
#6(2)-- No of backers for successful project
SELECT 
    SUM(backers_count) AS total_backers_successful
FROM 
    training_projects.projects
WHERE 
    state = 'successful';


#6(3)-- Avg no of days for successful Projects
SELECT 
    ROUND(AVG(DATEDIFF(
        FROM_UNIXTIME(successful_at), 
        FROM_UNIXTIME(created_at)
    )), 2) AS avg_days_successful_projects
FROM 
    training_projects.projects
WHERE 
    state = 'successful';
    
    
#7(1) -- Top 10 successful projects based on no.of backers
SELECT 
    ProjectID,
    name AS ProjectName,
    country,
    category_id,
    backers_count,
    (pledged * static_usd_rate) AS AmountRaised_USD
FROM 
   projects
WHERE 
    LOWER(TRIM(state)) = 'successful'
ORDER BY 
    backers_count DESC
LIMIT 10;

 
#7(2) -- Top 10 successful projects based on amount raised
SELECT 
    ProjectID,
    name AS ProjectName,
    country,
    category_id,
    backers_count,
    (pledged * static_usd_rate) AS AmountRaised_USD
FROM 
    projects
WHERE 
    LOWER(TRIM(state)) = 'successful'
ORDER BY 
    AmountRaised_USD DESC
LIMIT 10;


#8(1)-- Percentage of Successful Projects Overall --
SELECT 
    (COUNT(CASE WHEN state = 'successful' THEN 1 END) * 100.0 / COUNT(*)) AS success_percentage
FROM 
    training_projects.projects;
 
 
 #8(2) -- % of successful projects based on category
SELECT 
    category_id,
    COUNT(CASE WHEN LOWER(TRIM(state)) = 'successful' THEN 1 END) AS Successful_Projects,
    COUNT(ProjectID) AS Total_Projects,
    ROUND(
        (COUNT(CASE WHEN LOWER(TRIM(state)) = 'successful' THEN 1 END) / 
         COUNT(ProjectID)) * 100, 2
    ) AS Success_Percentage
FROM 
    projects
GROUP BY 
    category_id
ORDER BY 
    Success_Percentage DESC;
    
 
#8(3)-- Percentage of Successful Projects by Year, Quarter, Month 
SELECT 
    YEAR(FROM_UNIXTIME(created_at)) AS year,
    QUARTER(FROM_UNIXTIME(created_at)) AS quarter,
    MONTH(FROM_UNIXTIME(created_at)) AS month_number,
    MONTHNAME(FROM_UNIXTIME(created_at)) AS month_name,
    
    COUNT(*) AS total_projects,
    
    SUM(CASE WHEN state = 'successful' THEN 1 ELSE 0 END) AS successful_projects,
    
    ROUND(
        (SUM(CASE WHEN state = 'successful' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 
        2
    ) AS success_percentage
FROM 
    training_projects.projects
GROUP BY 
    YEAR(FROM_UNIXTIME(created_at)), 
    QUARTER(FROM_UNIXTIME(created_at)), 
    MONTH(FROM_UNIXTIME(created_at)),
    MONTHNAME(FROM_UNIXTIME(created_at))
ORDER BY 
    year DESC, 
    quarter, 
    month_number;
    
    
#8(4)-- Percentage of Successful Projects by Goal Range --
SELECT 
    CASE 
        WHEN (goal * static_usd_rate)  <5000 THEN '<5000'
        WHEN (goal * static_usd_rate) BETWEEN 5000 AND 20000 THEN '5000 to 20000'
        WHEN (goal * static_usd_rate) BETWEEN 20000 AND 50000 THEN '20000 to 50000'
        WHEN (goal * static_usd_rate) BETWEEN 50000 AND 100000 THEN '50000 to 100000'
        ELSE ' >100000'
    END AS goal_range,
    COUNT(ProjectID) AS total_projects,
    COUNT(CASE WHEN state = 'successful' THEN 1 END) AS successful_projects,
    (COUNT(CASE WHEN state = 'successful' THEN 1 END) * 100.0 / COUNT(ProjectID)) AS success_percentage
FROM 
    training_projects.projects
GROUP BY 
    goal_range
ORDER BY 
    success_percentage DESC;
    


    


    

    




    


