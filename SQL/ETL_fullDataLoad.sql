select * from logistics;

select * from dim_transport;

select * from dim_corridor

CREATE TABLE fact_shipment (
    fact_id SERIAL PRIMARY KEY,

    port_id INT,
    transport_id INT,
    product_id INT,
    risk_id INT,
    weather_id INT,
    time_id INT,

    weight_mt DOUBLE PRECISION,
    fuel_price_index DOUBLE PRECISION,
    geopolitical_risk_score DOUBLE PRECISION,
    carrier_reliability_score DOUBLE PRECISION,
    lead_time_days DOUBLE PRECISION,

	   CONSTRAINT fk_port
        FOREIGN KEY (port_id)
        REFERENCES dim_port(port_id),

    CONSTRAINT fk_transport
        FOREIGN KEY (transport_id)
        REFERENCES dim_transport(transport_id),

    CONSTRAINT fk_product
        FOREIGN KEY (product_id)
        REFERENCES dim_product(product_id),

    CONSTRAINT fk_risk
        FOREIGN KEY (risk_id)
        REFERENCES dim_risk(risk_id),

    CONSTRAINT fk_weather
        FOREIGN KEY (weather_id)
        REFERENCES dim_weather(weather_id),

    CONSTRAINT fk_time
        FOREIGN KEY (time_id)
        REFERENCES dim_time(time_id)
);

alter table fact_shipment
add column corridor_id int;

alter table fact_shipment
add constraint fk_corridor
foreign key (corridor_id) 
references dim_corridor(corridor_id);

ALTER TABLE fact_shipment
DROP COLUMN port_id;

ALTER TABLE fact_shipment
ADD COLUMN origin_port_id INT,
ADD COLUMN destination_port_id INT;

ALTER TABLE fact_shipment
ADD CONSTRAINT fk_origin_port
    FOREIGN KEY (origin_port_id)
    REFERENCES dim_port(port_id),

ADD CONSTRAINT fk_destination_port
    FOREIGN KEY (destination_port_id)
    REFERENCES dim_port(port_id);

select * from fact_shipment;

insert into fact_shipment(
    origin_port_id,
	destination_port_id,
    transport_id,
    product_id,
    risk_id,
    weather_id,
    time_id,
    weight_mt,
    fuel_price_index,
    geopolitical_risk_score,
    carrier_reliability_score,
    lead_time_days
)
SELECT
    o.port_id,
	d.port_id,
    t.transport_id,
    pr.product_id,
    r.risk_id,
    w.weather_id,
    ti.time_id,
    l.weight_mt,
    l.fuel_price_index,
    l.geopolitical_risk_score,
    l.carrier_reliability_score,
    l.lead_time_days
FROM logistics l

JOIN dim_port o
    ON l.origin_port = o.port_name

JOIN dim_port d 
   ON l.destination_port = d.port_name

JOIN dim_transport t
    ON l.transport_mode = t.transport_mode

JOIN dim_product pr
    ON l.product_category = pr.product_category

JOIN dim_risk r
    ON l.geopolitical_risk_class = r.risk_category

JOIN dim_weather w
    ON l.weather_condition = w.weather_condition

JOIN dim_time ti
    ON l.shipment_date = ti.shipment_date;

select * from fact_shipment;

-- Handling columns or values that were originally missed out
UPDATE fact_shipment f
SET corridor_id = c.corridor_id
FROM dim_corridor c
WHERE LEAST(f.origin_port_id, f.destination_port_id) = c.port1_id
  AND GREATEST(f.origin_port_id, f.destination_port_id) = c.port2_id

alter table fact_shipment
add column disruption bool

alter table fact_shipment
add column shipmentId char(10)

-- For future update, checking if all numerical attributes uniquely identifies a row.
SELECT
    weight_mt,
    fuel_price_index,
    geopolitical_risk_score,
    carrier_reliability_score,
    lead_time_days,
    COUNT(*)
FROM logistics
GROUP BY
    weight_mt,
    fuel_price_index,
    geopolitical_risk_score,
    carrier_reliability_score,
    lead_time_days
HAVING COUNT(*) > 1;

-- Mere numerical values matching would have worked as each record is unique. 
-- To be safe, the most robus version is implemented through joins.
UPDATE fact_shipment f
SET shipmentId = l.shipment_id,
    disruption = l.disruption_occurred
FROM logistics l
JOIN dim_transport tr
    ON tr.transport_mode = l.transport_mode
JOIN dim_product d
    ON d.product_category = l.product_category
JOIN dim_risk r
    ON r.risk_category = l.geopolitical_risk_class
JOIN dim_weather w
    ON w.weather_condition = l.weather_condition
JOIN dim_time t
    ON t.shipment_date = l.shipment_date
JOIN dim_corridor c
    ON c.trade_corridor = l.trade_corridor
WHERE f.transport_id = tr.transport_id
  AND f.product_id = d.product_id
  AND f.risk_id = r.risk_id
  AND f.weather_id = w.weather_id
  AND f.time_id = t.time_id
  AND f.corridor_id = c.corridor_id
  AND f.weight_mt = l.weight_mt
  AND f.fuel_price_index = l.fuel_price_index
  AND f.geopolitical_risk_score = l.geopolitical_risk_score
  AND f.carrier_reliability_score = l.carrier_reliability_score
  AND f.lead_time_days = l.lead_time_days;

select * from fact_shipment;

SELECT
    COUNT(*) FILTER (WHERE origin_port_id IS NULL) AS null_origin,
    COUNT(*) FILTER (WHERE destination_port_id IS NULL) AS null_destination,
    COUNT(*) FILTER (WHERE transport_id IS NULL) AS null_transport,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product,
    COUNT(*) FILTER (WHERE risk_id IS NULL) AS null_risk,
    COUNT(*) FILTER (WHERE weather_id IS NULL) AS null_weather,
    COUNT(*) FILTER (WHERE time_id IS NULL) AS null_time,
	COUNT(*) FILTER (WHERE disruption is null) as null_disruption,
	count(*) filter (where corridor_id is null) as null_corridor,
	count(*) filter (where shipmentId is null) as null_ship
FROM fact_shipment;