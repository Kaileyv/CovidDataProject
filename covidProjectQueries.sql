-- QUERIES ON COVID DEATHS AND COVID VACCINATIONS DATABASES

-- #1 Total Deaths vs Total Cases
-- Death Percentage shows probability of dying based on country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as "Death Percentage"
from CovidDeaths
order by 1,2 

-- #2 Total Cases vs Population
-- Infected Percentage shows the percentage of population (based on country) that was infected
select location, date, total_cases, population, (total_cases/population)*100 as "Infected Percentage"
from CovidDeaths
order by 1,2 

-- #3a Countries with Highest Infection Rate
select location, population, MAX(total_cases) as "Highest Infection Count", MAX(total_cases/population)*100 as "Infected Percentage"
from CovidDeaths
group by location, population
order by "Infected Percentage" DESC

-- #3b Countries with Highest Infection Rate with Date
select location, population, date, MAX(total_cases) as "Highest Infection Count", MAX(total_cases/population)*100 as "Infected Percentage"
from CovidDeaths
group by location, population, date
order by "Infected Percentage" DESC

-- #4 Countries with Highest Total Death Count
select location, MAX(total_deaths) as "Total Death Count"
from CovidDeaths
where continent is not NULL
group by location
order by "Total Death Count" DESC

-- #5 Continents with Highest Total Death Count
select location, SUM(new_deaths) as "Total Death Count"
from CovidDeaths
where continent is NULL and location not in ('World', 'European Union', 'International')
group by location
order by "Total Death Count" DESC

-- #6 Global Numbers: Death Percentage by Date
select date, SUM(new_cases) as "Total Cases", SUM(new_deaths) as "Total Deaths", SUM(new_deaths)/SUM(new_cases)*100 as "Death Percentage"
from CovidDeaths
where continent is not NULL
group by date
order by 1,2

-- #7 Global Numbers: Death Percentage
select SUM(new_cases) as "Total Cases", SUM(new_deaths) as "Total Deaths", SUM(new_deaths)/SUM(new_cases)*100 as "Death Percentage"
from CovidDeaths
where continent is not NULL
order by 1,2


-- JOIN DEATHS AND VACCINATIONS TABLES

-- #8 Total Population vs Vaccinations
select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION by death.location Order by death.location, death.date) as "Rolling Vaccinations"
from CovidDeaths death join CovidVaccinations vacc
    on death.location = vacc.location and death.date = vacc.date
where death.continent is not null 
order by 2,3


with popVSvacc (continent, location, date, population, new_vaccinations, "Rolling Vaccinations") as 
(
select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION by death.location Order by death.location, death.date) as "Rolling Vaccinations"
from CovidDeaths death join CovidVaccinations vacc
    on death.location = vacc.location and death.date = vacc.date
where death.continent is not null 
)

select *, ("Rolling Vaccinations"/population)*100 from popVSvacc

-- Temp Table
drop table if EXISTS #vaccinationPercentage
create table #vaccinationPercentage
(
continent NVARCHAR(255), location NVARCHAR(255), date DATETIME, population NUMERIC, new_vaccinations NUMERIC, "Rolling Vaccinations" NUMERIC
)

insert into #vaccinationPercentage
select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION by death.location Order by death.location, death.date) as "Rolling Vaccinations"
from CovidDeaths death join CovidVaccinations vacc
    on death.location = vacc.location and death.date = vacc.date
where death.continent is not null 

select *, ("Rolling Vaccinations"/population)*100 from #vaccinationPercentage


-- CREATE VIEWS FOR VISUALIZATIONS

-- #9 Population Vaccinations Percentage
CREATE VIEW vaccinationPercentage as 
select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION by death.location Order by death.location, death.date) as "Rolling Vaccinations"
from CovidDeaths death join CovidVaccinations vacc
    on death.location = vacc.location and death.date = vacc.date
where death.continent is not null

select * from vaccinationPercentage