SELECT * 
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--SELECT * 
--FROM PortfolioProject..CovidVaccination
--ORDER BY 3,4 

SELECT location, date, total_cases,total_deaths,population
FROM PortfolioProject..CovidDeaths
ORDER BY location,date

--Looking at Total Cases vs Total Deaths
-- This shows the likelihood of dying of Covid in Togo

SELECT location, date, total_cases,total_deaths,CAST(total_deaths AS float)/CAST(total_cases AS float))*100.0  AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%Togo%'
ORDER BY location,date

-- Looking at  Total Cases vs Population
-- This shows the proportion of togolese population who have contracted Covid

SELECT location,date,population,total_cases, (total_cases/CAST(population AS float))*100 as InfectionRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location,date

---Let's look at countries with highest Infection Rate compare to population

SELECT location,CAST(population AS float) AS Population,MAX(CAST(total_cases AS float)) as HighestInfectionCount, MAX((total_cases/CAST(population AS float))*100) as InfectionRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY InfectionRate DESC


-- Showing countries with highest Death Count by population

SELECT location, MAX(CAST(total_deaths AS float)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--let's break it down by continent
--Showing the continent with highest deaths count

SELECT continent, MAX(CAST(total_deaths AS float)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global numbers

SELECT date, 
       SUM(CAST(new_cases AS float)) AS Total_cases,
       SUM(CAST(new_deaths AS float)) AS Total_deaths,
       SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float))*100.0  AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


--Looking at Total Population vs Vaccination by joining the Vaccination table

SELECT Dea.continent,
       Dea.location,
	   Dea.date,
	   Dea.population,
	   Vac.new_vaccinations,
	   SUM(CAST(Vac.new_vaccinations AS float)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS VaccinationCountRollup1,
	   SUM(CONVERT(float,Vac.new_vaccinations)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS VaccinationCountRollup2
       FROM PortfolioProject..CovidDeaths Dea
       JOIN PortfolioProject..CovidVaccination Vac
	   ON Dea.location = Vac.location
	   AND Dea.date = Vac.date
	   WHERE Dea.continent IS NOT NULL
	   ORDER BY Dea.location,Dea.date

-- Calculate the proportion of people vaccinated over the population
-- 1 let's use a CTE

WITH PopvsVac 
(continent, location, date,population,new_vaccination,VaccinationCountRollup1,VaccinationCountRollup2)

AS
(SELECT Dea.continent,
       Dea.location,
	   Dea.date,
	   Dea.population,
	   Vac.new_vaccinations,
	   SUM(CAST(Vac.new_vaccinations AS float)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS VaccinationCountRollup1,
	   SUM(CONVERT(float,Vac.new_vaccinations)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS VaccinationCountRollup2
       FROM PortfolioProject..CovidDeaths Dea
       JOIN PortfolioProject..CovidVaccination Vac
	   ON Dea.location = Vac.location
	   AND Dea.date = Vac.date
	   WHERE Dea.continent IS NOT NULL
	   --ORDER BY Dea.location,Dea.date
	   )
SELECT * , (VaccinationCountRollup1/population)*100 AS PercentVaccinetedPop
FROM PopvsVac

---- 2 let's use a TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated 
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
VaccinationCountRollup1 numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT Dea.continent,
       Dea.location,
	   Dea.date,
	   Dea.population,
	   Vac.new_vaccinations,
	   SUM(CAST(Vac.new_vaccinations AS float)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS VaccinationCountRollup1
	   FROM PortfolioProject..CovidDeaths Dea
       JOIN PortfolioProject..CovidVaccination Vac
	   ON Dea.location = Vac.location
	   AND Dea.date = Vac.date
	   WHERE Dea.continent IS NOT NULL
	   ORDER BY Dea.location,Dea.date

SELECT *, (VaccinationCountRollup1/population)*100 AS PercentVaccinetedPop
FROM  #PercentPopulationVaccinated

--Create view to store date later for visualizations

CREATE VIEW #PercentPopulationVaccinated AS
SELECT Dea.continent,
       Dea.location,
	   Dea.date,
	   Dea.population,
	   Vac.new_vaccinations,
	   SUM(CAST(Vac.new_vaccinations AS float)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS VaccinationCountRollup1
	   FROM PortfolioProject..CovidDeaths Dea
       JOIN PortfolioProject..CovidVaccination Vac
	   ON Dea.location = Vac.location
	   AND Dea.date = Vac.date
	   WHERE Dea.continent IS NOT NULL
	   --ORDER BY Dea.location,Dea.date

SELECT * 
FROM PercentPopulationVaccinated