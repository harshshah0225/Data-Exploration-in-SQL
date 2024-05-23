-- Select Data that we are going to be using
SELECT 
	location, date, total_cases, new_cases, total_deaths, population
FROM 
	CovidDeaths
WHERE
	continent is not null
ORDER BY
	1,2

-- Total Cases vs Total Deaths
-- Probability of dying
SELECT
	location, date, total_cases, total_deaths, 
	(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases),0)) * 100 AS DeathPercentage
FROM
	CovidDeaths
WHERE 
	location = 'India' and continent is not null
ORDER BY 
	1,2

-- Total Cases vs Population
-- Shows what percentage of people got Covid
SELECT
	location, date, population, total_cases, 
	(CONVERT(float, total_cases) / NULLIF(CONVERT(float, population),0)) * 100 AS PercentPopulationInfected
FROM
	CovidDeaths
WHERE 
	location = 'India' and continent is not null
ORDER BY 
	1,2

-- Countries with Highest Infection Rate compared to Population
SELECT
	location, population, MAX(total_cases) AS HighestInfectionCount, 
	(MAX(total_cases) / population) * 100 AS PercentPopulationInfected
FROM
	CovidDeaths
WHERE
	continent is not null
GROUP BY
	location, population
ORDER BY 
	PercentPopulationInfected DESC

-- Countries with Higest death rate
SELECT
	location, MAX(cast(total_deaths as int)) AS HighestDeathCount
FROM
	CovidDeaths
WHERE
	continent is not null
GROUP BY
	location
ORDER BY 
	HighestDeathCount DESC

-- Continents with Higest death rate
SELECT
	continent, MAX(cast(total_deaths as int)) AS HighestDeathCount
FROM
	CovidDeaths
WHERE
	continent is not null
GROUP BY
	continent
ORDER BY 
	HighestDeathCount DESC

-- GLOBAL NUMBERS
SELECT
	location, date, SUM(new_cases) AS Total_Cases, SUM(new_deaths) AS Total_Deaths,
	(SUM(new_deaths) / NULLIF(SUM(new_cases),0)) * 100  AS DeathPercentage
FROM
	CovidDeaths
WHERE 
	continent is not null
GROUP BY
	location,date
ORDER BY 
	1,2

-- Total Amount of Vaccinated People
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST (vac.new_vaccinations AS BIGINT)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS RollingPeopleVaccinated
FROM
	CovidDeaths dea
JOIN CovidVaccination vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE 
	dea.continent IS NOT NULL
ORDER BY
	2,3


-- USE CTE
WITH 
	PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST (vac.new_vaccinations AS BIGINT)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS RollingPeopleVaccinated
FROM
	CovidDeaths dea
JOIN CovidVaccination vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE 
	dea.continent IS NOT NULL
--ORDER BY
--	2,3
)

SELECT 
	*, (RollingPeopleVaccinated/Population) * 100
FROM
	PopvsVac


-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST (vac.new_vaccinations AS BIGINT)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS RollingPeopleVaccinated
FROM
	CovidDeaths dea
JOIN CovidVaccination vac
ON dea.location = vac.location
AND dea.date = vac.date
--WHERE 
--	dea.continent IS NOT NULL
--ORDER BY
--	2,3

SELECT 
	*, (RollingPeopleVaccinated/Population) * 100
FROM
	#PercentPopulationVaccinated


-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST (vac.new_vaccinations AS BIGINT)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS RollingPeopleVaccinated
FROM
	CovidDeaths dea
JOIN CovidVaccination vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE 
	dea.continent IS NOT NULL
--ORDER BY
--	2,3