--- selecting data that is needed
SELECT location, continent, date, population, total_cases, new_cases, total_deaths
FROM portfolioprojects.dbo.CovidDeaths_new
WHERE continent IS NULL
ORDER BY location, date


---calculating total cases vs total deaths on a given day
---likelihood of dying if you contract covid-19 virus
SELECT
    location,
    date,
    total_cases,
    total_deaths,
    CAST(total_deaths AS DECIMAL(18, 2)) / CAST(total_cases AS DECIMAL(18, 2))*100 AS death_percentage --- Here the total_cases/total_deaths was returning 0 instead of decimal values. Reason was int/int returns answers in int data type
FROM
    portfolioprojects.dbo.CovidDeaths_new
WHERE location LIKE '%india%'
ORDER BY
    location, date;


--- Looking at total cases vs Population
--- shows what percentage of people got covid on each day
SELECT
    location,
    date,
    population,
    total_cases,
    CAST(total_cases AS DECIMAL(18, 2)) / CAST(population AS DECIMAL(18, 2))*100 AS PercentPopulationInfected --- Here the total_cases/population was returning 0 instead of decimal values. Reason was int/int returns answers in int data type
FROM
    portfolioprojects.dbo.CovidDeaths_new
WHERE location LIKE '%india%'
ORDER BY
    location, date;


---looking at highest infection Rate per population
SELECT
    location,
    population,
    MAX(total_cases) as highest_infection_count,
    MAX(CAST(total_cases AS DECIMAL(18, 2)) / CAST(population AS DECIMAL(18, 2))*100) AS PercentPopulationInfected --- Here the total_cases/population was returning 0 instead of decimal values. Reason was int/int returns answers in int data type
FROM
    portfolioprojects.dbo.CovidDeaths_new
GROUP BY location, population
order by PercentPopulationInfected DESC;


---showing countries with highest death count per population


SELECT
    location,
    population,
    MAX(total_deaths) as highest_Death_count,
    MAX(CAST(total_deaths AS DECIMAL(18, 2)) / CAST(population AS DECIMAL(18, 2))*100) AS PercentPopulationDied --- Here the total_cases/population was returning 0 instead of decimal values. Reason was int/int returns answers in int data type
FROM
    portfolioprojects.dbo.CovidDeaths_new
WHERE continent IS NOT NULL
GROUP BY location, population
order by PercentPopulationDied DESC;


---finding out which location got most cases between 2020 and 2021
SELECT TOP(10)
    location,
    SUM(CAST(total_cases as bigint)) as cases_between_2020_to_2021
FROM
    portfolioprojects.dbo.CovidDeaths_new
WHERE date BETWEEN '2020-01-01' AND '2021-01-01' AND continent IS NOT NULL
GROUP BY location 
ORDER BY cases_between_2020_to_2021 DESC;


---LET'S BREAK THINGS DOWN BY CONTINENT
---Showing continents with highest death count
SELECT
    continent,
    MAX(CAST(total_deaths as bigint)) as max_deaths_in_a_continent
FROM
    portfolioprojects.dbo.CovidDeaths_new
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY max_deaths_in_a_continent DESC;


---showing maximum deaths for each countries of a specific continent
SELECT
    location,
    MAX(CAST(total_deaths as bigint)) as max_deaths_in_a_continent
FROM
    portfolioprojects.dbo.CovidDeaths_new
WHERE continent ='asia'
GROUP BY location
ORDER BY max_deaths_in_a_continent DESC;

---showing  total new cases on a given date among the world
SELECT
    date,
    SUM(new_cases) as total_new_cases,
    SUM(new_deaths) as total_new_deaths,
    (SUM(CAST(new_deaths AS DECIMAL(18,2)))/SUM(CAST(new_cases AS DECIMAL(18,2) )))*100 AS death_percentage
FROM
    portfolioprojects.dbo.CovidDeaths_new
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date DESC;


--- total new cases so far around the world
SELECT
    SUM(new_cases) as total_new_cases,
    SUM(new_deaths) as total_new_deaths,
    (SUM(CAST(new_deaths AS DECIMAL(18,2)))/SUM(CAST(new_cases AS DECIMAL(18,2) )))*100 AS death_percentage
FROM
    portfolioprojects.dbo.CovidDeaths_new
WHERE continent IS NOT NULL



---observing covid vaccinations data
SELECT
    *
FROM portfolioprojects..CovidVaccinations


--- joining two tables covid deaths and covid vaccinations to do further more depth analysis

SELECT 
    *
FROM 
    portfolioprojects..CovidDeaths_new dea 
JOIN 
    portfolioprojects..CovidVaccinations vac
ON 
    dea.location = vac.location 
AND 
    dea.date = vac.date


---looking at population vs vaccinations

SELECT
    dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
FROM
    portfolioprojects..CovidDeaths_new dea 
JOIN 
    portfolioprojects..CovidVaccinations vac
ON 
    dea.location = vac.location 
AND 
    dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
ORDER BY
    1, 2, 3

--- To find out how many people vaccinated till a given date

SELECT
    dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM
    portfolioprojects..CovidDeaths_new dea 
JOIN 
    portfolioprojects..CovidVaccinations vac
ON 
    dea.location = vac.location 
AND 
    dea.date = vac.date
WHERE
    dea.continent IS NOT NULL 
ORDER BY
     2, 3

---We get error when we try to call out a column name when we have aliased column name from a calculation
--- so we try to use cte or temp table to make it work.
--- First we are gonna try using CTE

WITH POPvsVAC (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS (
SELECT
    dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM
    portfolioprojects..CovidDeaths_new dea 
JOIN 
    portfolioprojects..CovidVaccinations vac
ON 
    dea.location = vac.location 
AND 
    dea.date = vac.date
WHERE
    dea.continent IS NOT NULL 

)
SELECT *, (RollingPeopleVaccinated/population) *100 AS percentPeopleVaccinatedSoFar
FROM POPvsVAC



--- 2) now we use Temp tables to get our desired results
DROP TABLE if EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255), 
location nvarchar(255), 
date datetime, 
population numeric, 
new_vaccinations numeric, 
RollingPeopleVaccinated numeric);

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM
    portfolioprojects..CovidDeaths_new dea 
JOIN 
    portfolioprojects..CovidVaccinations vac
ON 
    dea.location = vac.location 
AND 
    dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;

SELECT *, (RollingPeopleVaccinated/population) *100 AS percentPeopleVaccinatedSoFar
FROM #PercentPopulationVaccinated


---creating views 

CREATE VIEW PercentPopulationVaccinated AS
SELECT
    dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM
    portfolioprojects..CovidDeaths_new dea 
JOIN 
    portfolioprojects..CovidVaccinations vac
ON 
    dea.location = vac.location 
AND 
    dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;

