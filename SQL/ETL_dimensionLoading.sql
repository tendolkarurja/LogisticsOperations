-- create a base table for extracting the feature engineered CSV file in pgsql
CREATE TABLE logistics (
    shipment_id VARCHAR(20) PRIMARY KEY,
    shipment_date DATE,

    origin_port VARCHAR(50),
    destination_port VARCHAR(50),

    transport_mode VARCHAR(20),
    product_category VARCHAR(30),

    distance_km DOUBLE PRECISION,
    weight_mt DOUBLE PRECISION,

    fuel_price_index DOUBLE PRECISION,
    geopolitical_risk_score DOUBLE PRECISION,

    weather_condition VARCHAR(20),
    carrier_reliability_score DOUBLE PRECISION,

    lead_time_days DOUBLE PRECISION,

    disruption_occurred BOOLEAN,

    geopolitical_risk_class VARCHAR(20),

    year INTEGER,
    month INTEGER,
    month_name VARCHAR(15),
    quarter INTEGER,
    day INTEGER,
    weekday VARCHAR(15),
    week INTEGER,

    weekend BOOLEAN,

    trade_corridor VARCHAR(50)
);


-- Loading done using IMPORT/EXPORT OPTION


-- Creating dimension tables for our use case, following a snowflake schema
create table dim_time(
	time_id serial primary key,
	shipment_date date,
	year integer,
	month integer, 
	month_name VARCHAR(15),
    quarter INTEGER,
    day INTEGER,
    weekday VARCHAR(15),
    week INTEGER,
    weekend BOOLEAN
);

create table dim_product(
	product_id serial primary key,
	product_category varchar(30)
);

create table dim_transport(
	transport_id serial primary key,
	transport_mode varchar(20)
);

create table dim_risk(
	risk_id serial primary key,
	risk_category varchar(20)
);

create table dim_weather(
	weather_id serial primary key,
	weather_condition varchar(20)
);

create table dim_port(
	port_id serial primary key,
	port_name varchar(50)
);

create table dim_corridor(
	corridor_id serial primary key,
	origin_port_id int,
	destination_port_id int,
	trade_corridor varchar(100),

	constraint fk_origin
	foreign key (origin_port_id)
	references dim_port(port_id), 

	constraint fk_dest
	foreign key (destination_port_id) 
	references dim_port(port_id)
);


-- loading each dimension table with appropriate content

insert into dim_time (shipment_date, year, month, month_name, quarter, day, weekday, week, weekend)
select distinct shipment_date, year, month, month_name, quarter, day, weekday, week, weekend
from logistics;

insert into dim_product(product_category)
select distinct product_category
from logistics;

insert into dim_transport(transport_mode)
select distinct transport_mode 
from logistics;

insert into dim_risk(risk_category)
select distinct geopolitical_risk_class
from logistics;

insert into dim_weather(weather_condition)
select distinct weather_condition
from logistics;

insert into dim_port(port_name)
select distinct origin_port 
from logistics
union
select distinct destination_port
from logistics;

insert into dim_corridor(trade_corridor, origin_port_id, destination_port_id)
Select distinct trade_corridor, LEAST(o.port_id, d.port_id), GREATEST(o.port_id, d.port_id)
From logistics
Join dim_port as o 
On o.port_name = logistics.origin_port
Join dim_port as d 
On d.port_name = logistics.destination_port;

SELECT COUNT(*) FROM dim_time;
SELECT COUNT(*) FROM dim_product;
SELECT COUNT(*) FROM dim_transport;
SELECT COUNT(*) FROM dim_weather;
SELECT COUNT(*) FROM dim_risk;
SELECT COUNT(*) FROM dim_port;
SELECT COUNT(*) FROM dim_corridor;
