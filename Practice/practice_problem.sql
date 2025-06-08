SELECT job_posted_date::DATE AS posted_date,
job_schedule_type,
AVG(salary_year_avg),
AVG(salary_hour_avg)
FROM job_postings_fact
WHERE job_posted_date > '2023-06-01'
GROUP BY posted_date, job_schedule_type
ORDER BY posted_date;

SELECT 
COUNT(job_id),
EXTRACT(MONTH FROM job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EDT')  AS month
FROM job_postings_fact
GROUP BY month 
ORDER BY month;

SELECT company_dim.name AS company_name,
job_postings_fact.job_health_insurance
FROM job_postings_fact
INNER JOIN company_dim ON job_postings_fact.company_id = company_dim.company_id
WHERE job_postings_fact.job_health_insurance = TRUE 
AND EXTRACT(QUARTER FROM job_postings_fact.job_posted_date) = 2;

CREATE TABLE jan_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1

CREATE TABLE feb_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 2

CREATE TABLE mar_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 3

SELECT skills, COUNT(skills) AS skill_count
FROM skills_dim
GROUP BY skills
ORDER BY skill_count DESC
LIMIT 5

SELECT skills, top_skills FROM(
    SELECT skill_id, COUNT(skill_id) AS skill_count
    FROM skills_job_dim
    GROUP BY skill_id
    ORDER BY skill_count DESC
    LIMIT 5
) AS top_skills
JOIN skills_dim ON skills_dim.skill_id =  top_skills.skill_id

SELECT name,
CASE
WHEN total_jobs < 100 THEN 'Small'
WHEN total_jobs > 100 THEN 'Large'
ELSE 'Medium'
END AS company_category,
company_count
FROM (
    SELECT COUNT(job_id) AS total_jobs, job_postings_fact.company_id
    FROM job_postings_fact
    GROUP BY job_postings_fact.company_id
    ORDER BY total_jobs DESC
) AS company_count
JOIN company_dim ON company_dim.company_id = company_count.company_id

WITH remote_jobs_skills AS(
    SELECT skill_id, 
    COUNT(*) AS skill_count
    FROM skills_job_dim
    JOIN job_postings_fact ON job_postings_fact.job_id = skills_job_dim.job_id
    WHERE job_postings_fact.job_work_from_home = TRUE
    GROUP BY skill_id
)
SELECT skills_dim.skill_id, 
skills_dim.skills AS skill_name,
skill_count
FROM remote_jobs_skills
JOIN skills_dim ON remote_jobs_skills.skill_id = skills_dim.skill_id
ORDER BY skill_count DESC
LIMIT 5

WITH salary_data AS (
    SELECT job_postings_fact.job_id,
    skills_job_dim.skill_id,
    skills_dim.skills,
    skills_dim.type
    FROM job_postings_fact
    LEFT JOIN skills_job_dim ON job_postings_fact.job_id = skills_job_dim.job_id
    LEFT JOIN skills_dim ON skills_job_dim.skill_id = skills_dim.skill_id
    WHERE EXTRACT(QUARTER FROM job_postings_fact.job_posted_date) = 1 AND
    job_postings_fact.salary_year_avg > 70000
    ORDER BY salary_year_avg
)
SELECT * 
FROM salary_data;

SELECT 
quarter_jobs.job_id,
quarter_jobs.job_location,
quarter_jobs.job_via,
quarter_jobs.job_posted_date::DATE
FROM (
    SELECT *
    FROM jan_jobs
    UNION ALL
    SELECT *
    FROM feb_jobs
    UNION ALL
    SELECT *
    FROM mar_jobs
) AS quarter_jobs
WHERE quarter_jobs.salary_year_avg > 70000
ORDER BY quarter_jobs.salary_year_avg DESC;