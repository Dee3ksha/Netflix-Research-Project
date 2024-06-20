create database netflix;
use netflix;

create table netflix(show_id	int,type	varchar(10),title varchar(50),	director	varchar(100),cast	varchar(200),country	varchar(50), 
date_added	char(20),release_year	int,rating	varchar(10), duration	varchar(20), listed_in	varchar(100), description varchar(200));
create table imdb(title varchar(50),imbd float);

select * from netflix limit 20;
alter table user add column rdate datetime;
set sql_safe_updates=0;
update user set rdate = str_to_date(record_date, "%d-%m-%y %H:%i");

select count(*) from netflix;
select distinct country from netflix where country is not null and country not like '%,%';
select min(year(date_added2)),max(year(date_added2)) from netflix;


select distinct country from netflix where country is not null and country not like '%,%';

/* distribution of content based on age*/

select distinct rating from netflix where rating regexp'^[a-z]';
with c as(with cte as(select rating,case
when rating regexp '^[a-z]' and rating in('NC-17','NR','R','TV-MA') then "Adult"
when rating regexp '^[a-z]' and rating in("PG-13",'TV-14') then "Teen"
when rating regexp '^[a-z]' and rating in('TV-Y','PG','TV-Y7','TV-PG') then "Children"
else "General"
end as tag from netflix   order by tag)
select tag, count(*)  as cnt from cte group by tag)
select tag,round(cnt/total*100,2)as percentage from c, (select sum(cnt) as total from c) as total_sum;


/* which type - movie or tv series  netflix have the most or least*/
/*tv shows Vs movies over 10 yrs*/

SELECT 
    release_year, type,
    COUNT(*) AS movie_count,
    round(AVG(imdb.rating),2) AS avg_rating
FROM netflix inner join imdb using(title)
where release_year>=2000
GROUP BY release_year,type order by release_year;

select type,count(*) as cnt  from netflix group by type;

select type,avg(i.rating) 
from netflix inner join imdb i using(title) group by type;


with cte as(SELECT title, 
cast(left(duration, locate(" ",duration,1)-1) as unsigned)as real_time from netflix 
where type='movie' and duration is not null)select min(real_time),max(real_time) from cte;

select distinct duration from netflix where type='TV show'; 


/* which country produces mass content on netflix*/
SELECT country, COUNT(*) as count FROM netflix inner join imdb using(title) where country is NOT NULL 
GROUP BY country order by count desc limit 10;

/*top 10 countries that have the most movies on Netflix with IMDb ratings higher than the average IMDb rating of all movies*/
with cte as(select country,imdb.rating as r from netflix inner join imdb on 
imdb.title=netflix.title where country is not null and country not like '%,%' and imdb.rating>(select round(avg(rating)) from imdb))
select country,count(*)as counting,round(avg(r),2) as ratings  from cte group by country order by counting desc limit 10;
 
 /* correlation between rating and Duration of movies*/


with c as(with cte as(SELECT title, 
cast(left(duration, locate(" ",duration,1)-1) as unsigned)as real_time from netflix 
where duration not like '%season%' and duration is not null)-- min-3 max-312 avg- 99.5
select cte.title,case
when real_time<90 then 'short movies'
when real_time>=90 and real_time<120 then 'medium duration'
else 'long duration' end as duration_category,i.rating as r from cte inner join imdb i on i.title=cte.title)
select duration_category, round(avg(r),2) as average,count(*)  from c group by duration_category;
-- there is no vast difference in the average of the three categories of duration



with cte as(SELECT  
i.title,i.rating as rating,cast(left(duration, locate(" ",duration,1)-1) as unsigned)as duration from netflix inner join imdb i using(title)
where type='movie' and duration is not null and i.rating is not null)
select  round((COUNT(*) * SUM(duration * rating) - SUM(duration) * SUM(rating)) /
        (SQRT((COUNT(*) * SUM(duration * duration) - SUM(duration) * SUM(duration)) * 
              (COUNT(*) * SUM(rating * rating) - SUM(rating) * SUM(rating)))),2) as correlation_coefficient from cte; -- there is no such or less correlation between rating and duration of movies

with cte as(SELECT  
avg(i.rating) as rating,cast(left(duration, locate(" ",duration,1)-1) as unsigned)as duration from netflix inner join imdb i using(title)
where type='TV show' and duration is not null and i.rating is not null group by duration)
select  round((COUNT(*) * SUM(duration * rating) - SUM(duration) * SUM(rating)) /
        (SQRT((COUNT(*) * SUM(duration * duration) - SUM(duration) * SUM(duration)) * 
              (COUNT(*) * SUM(rating * rating) - SUM(rating) * SUM(rating)))),2) as correlation_coefficient from cte;
 

/*change in people's choice over years wrt genre*/
/* Evolving genre per year*/
with new as(with cte as(select release_year, listed_in, round(avg(i.rating),2) as average_rating
from netflix n inner join imdb i on i.title=n.title  where release_year is not null group by release_year, listed_in order by release_year)
select release_year,listed_in,average_rating,dense_rank() over(partition by release_year order by average_rating desc) as n from cte)
select release_year,listed_in as genre,average_rating
from new where n=1 and release_year>=2010; 


/*originals vs Added*/

with c as(select title,type,if(release_year=year(date_added2), 'Netflix original', 'other source') as platform
from netflix) select platform,type,count(*),round(avg(rating),2) from c inner join imdb using(title) group by platform,type order by platform;



/*the month on which most movies launched on netflix*/
SELECT DATE_FORMAT(date_added2, '%b') as x,
       COUNT(DISTINCT show_id) AS production
FROM netflix
where date_added2 is not null 
GROUP BY x
ORDER BY production desc;

set sql_safe_updates=0;
update netflix 
set duration=null where duration="";





 