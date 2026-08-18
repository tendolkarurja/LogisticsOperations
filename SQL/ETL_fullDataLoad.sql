select * from logistics;

select * from dim_transport;


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

SELECT
    COUNT(*) FILTER (WHERE origin_port_id IS NULL) AS null_origin,
    COUNT(*) FILTER (WHERE destination_port_id IS NULL) AS null_destination,
    COUNT(*) FILTER (WHERE transport_id IS NULL) AS null_transport,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product,
    COUNT(*) FILTER (WHERE risk_id IS NULL) AS null_risk,
    COUNT(*) FILTER (WHERE weather_id IS NULL) AS null_weather,
    COUNT(*) FILTER (WHERE time_id IS NULL) AS null_time
FROM fact_shipment;
