
SELECT *
FROM "CovidDeaths"
WHERE continent IS NOT NULL
ORDER BY 3, 4;

SELECT *
FROM "CovidVaccinations"
ORDER BY 3, 4;

SELECT location, date, total_cases,
       new_cases, total_deaths, population
FROM "CovidDeaths"
ORDER BY 1, 2;

-- altering date column with correct values instead of excel format
SELECT date '1900-01-01' + interval '1 day' * ("date"::int - 2) AS corrected_date
FROM "CovidDeaths"
LIMIT 10;

ALTER TABLE "CovidDeaths" ALTER COLUMN "date" TYPE DATE USING date '1900-01-01' + interval '1 day' * ("date"::int - 2);

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in X country
SELECT location, date, total_cases,
        total_deaths, (total_deaths / total_cases * 100) AS Death_Percentage
FROM "CovidDeaths"
WHERE location = 'Mexico'
ORDER BY 1, 2;

-- Looking at the Total Cases vs Population
-- shows what percentage of population got Covid
SELECT location, date, total_cases, population,
     (total_cases / population * 100) AS Death_Percentage
FROM "CovidDeaths"
WHERE location = 'Mexico'
ORDER BY 1, 2;

-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS highest_infection_count,
       MAX((total_cases/population))*100 AS percent_population_infected
FROM "CovidDeaths"
GROUP BY 1, 2
ORDER BY percent_population_infected DESC;

-- LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing the continents with the highest death count per population
SELECT location, MAX(cast(total_deaths as int)) AS total_death_count
FROM "CovidDeaths"
WHERE continent IS NULL
GROUP BY 1
ORDER BY total_death_count DESC;

-- Global numbers
SELECT  SUM(new_Cases) as total_cases, SUM(cast(new_deaths as int)) AS total_Deaths,
       SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS death_percentage
FROM "CovidDeaths"
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;


-- Looking at Total Population vs Vaccinations
WITH PopsvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
    SELECT dea.continent, dea.location, dea.date,
           dea.population, vac.new_vaccinations,
           SUM(cast(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location
               ORDER BY dea.location, dea.date) as rolling_people_vaccinated
    FROM "CovidDeaths" dea
    JOIN "CovidVaccinations" vac
    ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated / population) * 100
FROM PopsvsVac;


-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(COALESCE(cast(vac.new_vaccinations AS int), 0))
               OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_people_vaccinated
    FROM "CovidDeaths" dea
    JOIN "CovidVaccinations" vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL;
