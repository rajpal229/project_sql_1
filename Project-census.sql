/*use sql_server;
select * from project.dbo.data1;

select * from project.dbo.data2;

-- number of rows into our dataset
*/
select count(*) from data1
select count(*) from data2

-- dataset for Delhi and Uttar Pradesh 
select d1.State, d1.District, d2.Population, d2.Area_km2,
	   d1.Growth, d1.Literacy, d1.Sex_Ratio
from data1 d1
join data2 d2 on d1.state = d2.State
where d1.state in ('Delhi' ,'Uttar Pradesh')
order by d1.state

-- finding Density
select *, round(Population/Area_km2, 2) as Density
from data2
where state in ('Delhi' ,'Uttar Pradesh')
order by state

-- population of India
select sum(population) as Population
from data2

-- avg growth 
select state,round(avg(growth)*100,2) as avg_growth
from data1 group by state;

-- avg sex ratio

select state,round(avg(sex_ratio),0) as avg_sex_ratio
from data1 group by state
order by avg_sex_ratio desc;

-- avg literacy rate
 
select state,round(avg(literacy),0) as avg_literacy_ratio
from data1  group by state having round(avg(literacy),0)>90
union
select state,round(avg(literacy),0) as avg_literacy_ratio
from data1  group by state having round(avg(literacy),0)<70
order by avg_literacy_ratio desc ;

-- top 5 state showing highest growth ratio
/*
select state,round(avg(growth)*100,2) as avg_growth
from data1 group by state
order by avg_growth desc
limit 3;
*/
--bottom 5 state showing lowest sex ratio

select top 5 state,round(avg(sex_ratio),0) as avg_sex_ratio
from data1 group by state
order by avg_sex_ratio asc;

-- top and bottom 5 states in literacy state

drop table if exists #topstates;
create table #topstates
( state nvarchar(255),
  topstate float
  )

insert into #topstates
select state,round(avg(literacy),0) avg_literacy_ratio
from data1 group by state
order by avg_literacy_ratio desc;

select top 5 *
from #topstates
order by #topstates.topstate desc;

drop table if exists #bottomstates;
create table #bottomstates
( state nvarchar(255),
  bottomstate float
  )

insert into #bottomstates
select state,round(avg(literacy),0) avg_literacy_ratio
from data1 group by state
order by avg_literacy_ratio desc;

select top 5 *
from #bottomstates
order by #bottomstates.bottomstate asc;

--union opertor using subqueries

select * from (
select top 5 * 
from #topstates
order by #topstates.topstate desc) a
union
select * from (
select top 5 *
from #bottomstates
order by #bottomstates.bottomstate asc) b;


-- states starting with letter a or b

select distinct state
from data1
where lower(state) like 'a%' or lower(state) like 'b%'

-- sql is case-insensitive

-- states starting with letter a and ends at m

select distinct state
from data1
where lower(state) like 'a%' and lower(state) like '%m'


-- joining both table of total polulation and total literacy rate

--total males and females
select *
from (
select d.state,sum(d.males) as total_males,sum(d.females) as total_females
from(
select c.district,c.state,
round(c.population/(c.sex_ratio+1),0) as males,
round((c.population*c.sex_ratio)/(c.sex_ratio+1),0) females
from(
select a.district,a.state,a.sex_ratio/1000 sex_ratio,b.population
from data1 a
inner join data2 b on a.district=b.district) c) d
group by d.state) t1

-- total literacy rate
join(
select c.state,sum(literate_people) total_literate_population,sum(illiterate_people) total_lliterate_population
from(
select d.district,d.state,
round(d.literacy_ratio*d.population,0) literate_people,
round((1-d.literacy_ratio)* d.population,0) illiterate_people
from(
select a.district,a.state,a.literacy/100 literacy_ratio,b.population
from data1 a 
inner join data2 b on a.district=b.district) d) c
group by c.state) t2
on t2.state = t1.state 


-- population in previous census

select sum(m.previous_census_population) previous_census_population,
       sum(m.current_census_population) current_census_population
from(
select e.state,sum(e.previous_census_population) previous_census_population,
       sum(e.current_census_population) current_census_population
from
(select d.district,d.state,round(d.population/(1+d.growth),0) previous_census_population,
        d.population current_census_population
from
(select a.district,a.state,a.growth growth,b.population
from data1 a
inner join data2 b on a.district=b.district) d) e
group by e.state)m


-- population vs area

select (g.total_area/g.previous_census_population)  as previous_census_population_vs_area,
       (g.total_area/g.current_census_population) as current_census_population_vs_area
from
(select q.*,r.total_area 
from
(select '1' as keyy,n.* 
from
(select sum(m.previous_census_population) previous_census_population,
        sum(m.current_census_population) current_census_population
from(
select e.state,sum(e.previous_census_population) previous_census_population,
       sum(e.current_census_population) current_census_population
from
(select d.district,d.state,round(d.population/(1+d.growth),0) previous_census_population,
        d.population current_census_population
from
(select a.district,a.state,a.growth growth,b.population 
from data1 a 
inner join data2 b on a.district=b.district) d) e
group by e.state)m) n) q

inner join (
select '1' as keyy,z.* 
from
(select sum(area_km2) total_area
from data2)z) r on q.keyy=r.keyy)g


-- output top 3 districts from each state with highest literacy rate

select a.* 
from
(select district,state,literacy,rank() over(partition by state order by literacy desc) rnk 
from data1) a
where a.rnk in (1,2,3)
order by state