Select * 
From portfolio..covid_deaths
--Filter out data that has no continent 
Where continent is not null
Order by 3,4

--Select * 
--From portfolio..covid_vaccination
--Order by 3,4

-- Data we are using 
Select location, date, total_cases, new_cases, total_deaths, population
From portfolio..covid_deaths
Where continent is not null
Order by 1,2

--Death Percentage: Total Cases vs Total Deaths 
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
From portfolio..covid_deaths
Where location like 'Australia' and continent is not null
Order by 1,2

--Total cases vs Population 
Select location, date, total_cases, population, (total_cases/population)*100 AS Population_Percentage_Contracted
From portfolio..covid_deaths
Where location like 'Australia' and continent is not null
Order by 1,2

--Countries with highest infection rates compared to population
Select location, MAX(total_cases) AS Highest_Infection_Count, population, MAX((total_cases/population))*100 AS Percentage_Population_Infected
From portfolio..covid_deaths
Where continent is not null
Group by location, population 
Order by Percentage_Population_Infected desc

--Countries with highest death count per population
Select location, MAX(cast(total_deaths as int)) AS Total_Death_Count
From portfolio..covid_deaths
Where continent is not null
Group by location
Order by Total_Death_Count desc

--Continent with highest death count per population
-- To drill down further when using visualisation tools
Select continent, MAX(cast(total_deaths as int)) AS Total_Death_Count
From portfolio..covid_deaths
Where continent is not null
Group by continent
Order by Total_Death_Count desc

--Global Numbers 
Select date, SUM(total_cases) AS Total_Cases, SUM(cast(new_deaths as int)) AS Total_Deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS Death_Percentage
From portfolio..covid_deaths
Where continent is not null
Group by date
Order by 1,2

--Joining with vaccination data table
--Looking at Total Population vs Vaccination
Select d.continent, d.location, d.date, d.population, v.new_vaccinations 
From portfolio ..covid_vaccination v
Join portfolio ..covid_deaths d
	On v.location = d.location
	and v.date = d.date
Where d.continent is not null
Order by 1,2,3

Select d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(bigint, v.new_vaccinations)) OVER (Partition by d.location order by d.location, d.date) AS Rolling_Vaccination
--, (Rolling_Vaccination/d.popultion)*100
From portfolio ..covid_vaccination v
Join portfolio ..covid_deaths d
	On v.location = d.location
	and v.date = d.date
Where d.continent is not null
Order by 2,3

--USE Common Table Expression
--Number of columns in CTE must match the subquery columns
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_Vaccination)
as 
(
Select d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(bigint, v.new_vaccinations)) OVER (Partition by d.location order by d.location, d.date) AS Rolling_Vaccination
--, (Rolling_Vaccinations/d.popultion)*100
From portfolio ..covid_vaccination v
Join portfolio ..covid_deaths d
	On v.location = d.location
	and v.date = d.date
Where d.continent is not null
--Order by 2,3
)
Select *, (Rolling_Vaccinations/population)*100 as Vaccination_Percentage
From PopvsVac

--TEMP TABLE 
DROP Table if exists #Percent_Population_Vaccinated
Create Table  #Percent_Population_Vaccinated
(
Continent nvarchar(255), --need specify data type
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_vaccinations numeric
)

Insert into #Percent_Population_Vaccinated
Select d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(bigint, v.new_vaccinations)) OVER (Partition by d.location order by d.location, d.date) AS Rolling_Vaccination
--, (Rolling_Vaccination/d.popultion)*100
From portfolio ..covid_vaccination v
Join portfolio ..covid_deaths d
	On v.location = d.location
	and v.date = d.date
Where d.continent is not null
Order by 2,3

Select *, (Rolling_Vaccinations/population)*100 as Vaccination_Percentage
From #Percent_Population_Vaccinated


--Create view to store data for visualisations 
--You can now create queries out of this table under view (Work Table/View)
Create View Percent_Population_Vaccinated as 
Select d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(bigint, v.new_vaccinations)) OVER (Partition by d.location order by d.location, d.date) AS Rolling_Vaccination
--, (Rolling_Vaccination/d.popultion)*100
From portfolio ..covid_vaccination v
Join portfolio ..covid_deaths d
	On v.location = d.location
	and v.date = d.date
Where d.continent is not null
--Order by 2,3