-- Queries to be used for  our Tableau Project
-- The aim si to visualiaze our Covid data in Tableau and as we can't connect Tableau Desktop to this Database we will run
-- the queries and copying the results in Excel table that we will import in Tableau later.

-- 1- Let's create our first table which will give as the death percentage at a global level

SELECT SUM(CAST(new_cases AS float))AS total_cases, 
       SUM(CAST(new_deaths as float)) AS total_deaths, 
	   SUM(CAST(new_deaths as float))/SUM(CAST(New_Cases AS float))*100 AS DeathPercentage
       FROM PortfolioProject..CovidDeaths
       WHERE continent IS NOT NULL 
       ORDER BY total_cases,total_deaths

-- 2- Our second table to get death count at continent level

SELECT location, SUM(cast(new_deaths as float)) AS TotalDeathCount
       FROM PortfolioProject..CovidDeaths
       WHERE continent IS NULL 
       AND location NOT IN ('World', 'European Union', 'International', 'Upper middle income', 'High income', 'Lower middle income', 'Low income')
       GROUP BY location
       ORDER BY TotalDeathCount DESC

-- 3- Our third table will look at number of people infected in each country and the proportion in regard of the population

SELECT location, 
       CAST(population AS float) as Population, 
	   MAX(CAST(total_cases as float)) as HighestInfectionCount,  
       MAX(CAST(total_cases AS float)/CAST(population as float))*100 as PercentPopulationInfected
       FROM PortfolioProject..CovidDeaths
       GROUP BY location, population
       ORDER BY PercentPopulationInfected DESC

-- 4- This fourth table will look infection count and percentage over the time for all countries

SELECT location, 
       CAST(population AS float) AS Population,
	   date, 
	   MAX(CAST(total_cases as float)) AS HighestInfectionCount,  
	   MAX((CAST(total_cases as float)/CAST(population AS float)))*100 as PercentPopulationInfected
       FROM PortfolioProject..CovidDeaths
       GROUP BY location, population, date
       ORDER BY PercentPopulationInfected DESC