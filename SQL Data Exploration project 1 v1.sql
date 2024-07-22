-- SELECT ALL DATA FROM THE COVIDDEATHS TABLE AND ORDER BY COLUMNS 3 AND 4
SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3, 4;

-- SELECT SPECIFIC COLUMNS FROM THE COVIDDEATHS TABLE
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2;

-- CALCULATE DEATH PERCENTAGE
SELECT location,
       date,
       total_cases,
       total_deaths,
       (CAST(total_deaths AS DECIMAL) / CAST(total_cases AS DECIMAL)) * 100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%EGYPT%'
ORDER BY 1, 2;

-- CALCULATE POPULATION INFECTED PERCENTAGE
SELECT location,
       date,
       population,
       total_cases,
       (CAST(population AS DECIMAL) / CAST(total_cases AS DECIMAL)) * 100 AS populationInfected_percentage
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2;

-- HIGHEST INFECTION RATE
SELECT location,
       population,
       MAX(total_cases) AS HighestInfectionCount,
       (CAST(MAX(total_cases) AS DECIMAL) / CAST(population AS DECIMAL)) * 100 AS populationInfected_percentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY populationInfected_percentage DESC;

-- HIGHEST DEATH RATE
SELECT location,
       CAST(MAX(total_deaths) AS INT) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location, population
ORDER BY HighestDeathCount DESC;

-- HIGHEST DEATH COUNT BY CONTINENT
SELECT continent,
       CAST(MAX(total_deaths) AS INT) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC;

-- TOTAL DEATHS PER CONTINENT
SELECT continent,
       SUM(CAST(total_deaths AS BIGINT)) AS TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeaths DESC;

-- GLOBAL NEW CASES AND NEW DEATHS FOR THE FIRST DAY OF EACH MONTH
SELECT 
    date,
    SUM(CAST(new_cases AS BIGINT)) AS GlobalNewCases,
    SUM(CAST(new_deaths AS BIGINT)) AS GlobalNewDeaths
FROM PortfolioProject..CovidDeaths
WHERE DAY(date) = 1
GROUP BY date
ORDER BY date;

-- TOTAL CASES AND DEATHS FOR AFRICAN COUNTRIES
SELECT 
    location AS Country,
    SUM(CAST(total_cases AS BIGINT)) AS TotalCases,
    SUM(CAST(total_deaths AS BIGINT)) AS TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent = 'AFRICA'
GROUP BY location
ORDER BY location ASC;

-- DEATH PERCENTAGE ACROSS THE WORLD
SELECT 
    date,
    SUM(CAST(new_cases AS BIGINT)) AS NewCases,
    SUM(CAST(new_deaths AS BIGINT)) AS NewDeaths,
    CASE 
        WHEN SUM(CAST(new_cases AS DECIMAL)) = 0 THEN 0
        ELSE (SUM(CAST(new_deaths AS DECIMAL)) / SUM(CAST(new_cases AS DECIMAL))) * 100
    END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY date
ORDER BY date;

-- JOIN COVIDDEATHS AND COVIDVACCINATIONS TABLES FOR CUMULATIVE VACCINATIONS
SELECT 
    d.continent,
    d.location AS country,
    d.date,
    d.population,
    v.new_vaccinations,
    SUM(CONVERT(DECIMAL, COALESCE(v.new_vaccinations, 0))) OVER (PARTITION BY d.location ORDER BY d.date) AS CumulativeVaccinations
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY d.location, d.date;

-- USING CTE FOR CUMULATIVE VACCINATIONS AND PERCENTAGE
WITH POPvsVAC (continent, location, date, population, new_vaccinations, CumulativeVaccinations) AS 
(
SELECT 
    d.continent,
    d.location AS country,
    d.date,
    d.population,
    v.new_vaccinations,
    SUM(CONVERT(DECIMAL, COALESCE(v.new_vaccinations, 0))) OVER (PARTITION BY d.location ORDER BY d.date) AS CumulativeVaccinations
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
)

SELECT *, (CumulativeVaccinations / population) * 100 AS VaccinationPercentage
FROM POPvsVAC;

-- USING TEMP TABLE FOR CUMULATIVE VACCINATIONS AND PERCENTAGE
DROP TABLE IF EXISTS #POPvsVAC;
CREATE TABLE #POPvsVAC (
    continent NVARCHAR(255),
    country NVARCHAR(255),
    date DATE,
    population BIGINT,
    new_vaccinations BIGINT,
    CumulativeVaccinations DECIMAL(20, 2)
);

INSERT INTO #POPvsVAC (continent, country, date, population, new_vaccinations, CumulativeVaccinations)
SELECT 
    d.continent,
    d.location AS country,
    d.date,
    d.population,
    v.new_vaccinations,
    SUM(CONVERT(DECIMAL, COALESCE(v.new_vaccinations, 0))) OVER (PARTITION BY d.location ORDER BY d.date) AS CumulativeVaccinations
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL;

SELECT *,
       (CumulativeVaccinations / population) * 100 AS VaccinationPercentage
FROM #POPvsVAC
ORDER BY country, date;

-- CREATE VIEW FOR CUMULATIVE VACCINATIONS FOR LATER Visualization

CREATE VIEW POPvsVACfirstView AS  
SELECT  
    d.continent,
    d.location AS country,
    d.date,
    d.population,
    v.new_vaccinations,
    SUM(CONVERT(DECIMAL, COALESCE(v.new_vaccinations, 0))) OVER (PARTITION BY d.location ORDER BY d.date) AS CumulativeVaccinations
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL;

SELECT *
FROM POPvsVACfirstView;
