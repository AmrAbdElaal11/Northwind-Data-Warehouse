
select *
from src.orders;

-- 1. stg_orders
CREATE TABLE stg_orders (
	order_id int2 NOT NULL,
	customer_id varchar(5) NULL,
	employee_id int2 NULL,
	order_date date NULL,
	required_date date NULL,
	shipped_date date NULL,
	ship_via int2 NULL,
	freight float4 NULL,
	ship_name varchar(40) NULL,
	ship_address varchar(60) NULL,
	ship_city varchar(15) NULL,
	ship_region varchar(15) NULL,
	ship_postal_code varchar(10) NULL,
	ship_country varchar(15) NULL
);

-- Initial Load of stg_orders from source
insert into stg_orders
select *
from src.orders;

select * from stg_orders so ;

-- Dela Load of stg_orders from source
truncate table stg_orders ;
insert into stg_orders 
select * 
from src.orders 
where order_date = current_date -1 ; -- get all the orders of yesterday
--------------------------------------------------------------------------------------------------------

-- 2. stg_orders_details
CREATE TABLE stg_order_details (
	order_id int2 NOT NULL,
	product_id int2 NOT NULL,
	unit_price float4 NOT NULL,
	quantity int2 NOT NULL,
	discount float4 NOT NULL
);

-- Initial Load of stg_orders from source

insert into stg_order_details
select *
from src.order_details;

select distinct * from stg_order_details sod order by order_id ;

-- Dela Load of stg_order_details from source
truncate table order_details ;

insert into stg_orders 
select od.order_id ,od.product_id ,od.unit_price ,od.quantity ,od.discount 
from src.orders o join src.order_details od on o.order_id = od.order_id 
where order_date = current_date -1 ; -- get all the orders of yesterday

--------------------------------------------------------------------------------------------------------------------
select * from src.employees; 

-- 3. stg_employess
CREATE TABLE stg_employees (
	employee_id int2 NOT NULL,
	last_name varchar(20) NOT NULL,
	first_name varchar(10) NOT NULL,
	title varchar(30) NULL,
	title_of_courtesy varchar(25) NULL,
	birth_date date NULL,
	hire_date date NULL,
	address varchar(60) NULL,
	city varchar(15) NULL,
	region varchar(15) NULL,
	postal_code varchar(10) NULL,
	country varchar(15) NULL,
	home_phone varchar(24) NULL,
	"extension" varchar(4) NULL,
	photo bytea NULL,
	notes text NULL,
	reports_to int2 NULL,
	photo_path varchar(255) NULL
);

-- initial load of the stg_employees
insert into stg_employees
select *
from src.employees;

select * from stg_employees se ;
-- Full Load as No delata load strategy as their is no field indicating deltas
truncate table stg_employees ;
insert into stg_employees
select *
from src.employees;

---------------------------------------------------------------------------------------------------------------
select * from src.shippers s ;
-- 4. stg_shippers
CREATE TABLE stg_shippers (
	shipper_id int2 NOT NULL,
	company_name varchar(40) NOT NULL,
	phone varchar(24) NULL
);


-- initial load of the stg_shippers
insert into stg_shippers
select *
from src.shippers ;

select * from stg_shippers se ;
-- Full Load as No delata load strategy as their is no field indicating deltas
truncate table stg_shippers ;
insert into stg_shippers
select *
from src.shippers ;


----------------------------------------------------------------------------------------
select * from src.categories c ;

-- 5. stg_categories
CREATE TABLE stg_categories (
	category_id int2 NOT NULL,
	category_name varchar(15) NOT NULL,
	description text NULL,
	picture bytea NULL
);

-- initial load of the stg_shippers
insert into stg_categories 
select *
from src.categories ;

select * from stg_categories sc ;
-- Full Load as No delata load strategy as their is no field indicating deltas
truncate table stg_categories ;
insert into stg_categories 
select *
from src.categories ;

----------------------------------------------------------------------------------------
select * from src.suppliers s ;
-- 6. stg_suppliers

CREATE TABLE stg_suppliers (
	supplier_id int2 NOT NULL,
	company_name varchar(40) NOT NULL,
	contact_name varchar(30) NULL,
	contact_title varchar(30) NULL,
	address varchar(60) NULL,
	city varchar(15) NULL,
	region varchar(15) NULL,
	postal_code varchar(10) NULL,
	country varchar(15) NULL,
	phone varchar(24) NULL,
	fax varchar(24) NULL,
	homepage text NULL
);

-- initial load of the stg_suppliers
insert into stg_suppliers 
select *
from src.suppliers ;

select * from stg_suppliers ss ;
-- Full Load as No delata load strategy as their is no field indicating deltas
truncate table stg_suppliers ;
insert into stg_suppliers 
select *
from src.suppliers ;

----------------------------------------------------------------------------------------
select * from src.products p ;

-- 7. stg_products
CREATE TABLE stg_products (
	product_id int2 NOT NULL,
	product_name varchar(40) NOT NULL,
	supplier_id int2 NULL,
	category_id int2 NULL,
	quantity_per_unit varchar(20) NULL,
	unit_price float4 NULL,
	units_in_stock int2 NULL,
	units_on_order int2 NULL,
	reorder_level int2 NULL,
	discontinued int4 NOT NULL
);


-- initial load of the stg_proudcts
insert into stg_products 
select *
from src.products ;

select * from stg_products sp ;
-- Full Load as No delata load strategy as their is no field indicating deltas
truncate table stg_suppliers ;
insert into stg_products 
select *
from src.products ;

----------------------------------------------------------------------------------------
select * from src.customers;
-- 8. stg_customers

CREATE TABLE stg_customers (
	customer_id varchar(5) NOT NULL,
	company_name varchar(40) NOT NULL,
	contact_name varchar(30) NULL,
	contact_title varchar(30) NULL,
	address varchar(60) NULL,
	city varchar(15) NULL,
	region varchar(15) NULL,
	postal_code varchar(10) NULL,
	country varchar(15) NULL,
	phone varchar(24) NULL,
	fax varchar(24) NULL
);



-- initial load of the stg_proudcts
insert into stg_customers 
select *
from src.products ;

select * from stg_customers sc ;
-- Full Load as No delata load strategy as their is no field indicating deltas
truncate table stg_suppliers ;
insert into stg_customers 
select *
from src.customers ;

----------------------------------------------------------------------------------------
select * from src.employee_territories et ;
-- 9. stg_emloyee_territories

CREATE TABLE stg_employee_territories (
	employee_id int2 NOT NULL,
	territory_id varchar(20) NOT NULL
);

truncate table stg_employee_territories ;
insert into stg_employee_territories 
select * from src.employee_territories ;


----------------------------------------------------------------------------------------

select * from src.territories t  ;
-- 10. stg_territories

CREATE TABLE stg_territories (
	territory_id varchar(20) NOT NULL,
	territory_description varchar(60) NOT NULL,
	region_id int2 NOT NULL
);

truncate table stg_territories ;
insert into stg_territories 
select * from src.territories ;

----------------------------------------------------------------------------------------

select * from src.region r   ;
-- 11. stg_region


CREATE TABLE stg_region (
	region_id int2 NOT NULL,
	region_description varchar(60) NOT NULL
);

truncate table stg_region ;
insert into stg_region
select * from src.region ;


----------------------------------------------------------------------------------------

create table results(
    table_name TEXT,
    column_name TEXT,
    data_type TEXT,
    min_value text,
    max_value text,
    avg_value numeric,
    min_length bigint,
    max_length bigint ,
    null_count bigint ,
    total_count bigint,
    null_percentage float
);


CREATE OR REPLACE procedure data_quality_profiling()
 AS $$
DECLARE
rec record;
query text;
begin
for rec in (with get_tables as (select oid , relname  
					from pg_class
					where relnamespace = (select oid from pg_namespace where nspname = 'staging')
      						and relname <> 'results') ,
             get_columns as (select  relname , attname , atttypid
      				         from pg_attribute p inner join get_tables g on p.attrelid = g.oid 
      				         where attname not in ('xmin','cmin','tableoid','xmax','cmax','ctid'))
select relname , attname , typname , typcategory
from get_columns inner join pg_type on pg_type.oid = get_columns.atttypid)

loop 
query = format(
			'SELECT 
                    %L AS table_name,
                    %L AS column_name,
                    %L AS data_type,
                cast( %s as text) AS min_value,
                cast (   %s as text ) AS max_value,
                  %s AS avg_value,
                 %s AS min_length,
                  %s AS max_length,
                    COUNT(*) FILTER (WHERE %I IS NULL)  AS null_count,
                   COUNT(*)  AS total_count,
                   100.0 * COUNT(*) FILTER (WHERE %I IS NULL) / nullif(COUNT(*),0) AS null_percentage
                 FROM %I',
 				rec.relname,
                rec.attname,
                rec.typcategory,
                CASE WHEN rec.typcategory in ('N','D') THEN FORMAT('MIN(%I)', rec.attname) ELSE format('NULL') END,
                CASE WHEN rec.typcategory in ('N','D') THEN FORMAT('MAX(%I)', rec.attname) ELSE format('NULL')  END,
                CASE WHEN rec.typcategory = 'N' THEN FORMAT('AVG(%I)', rec.attname) ELSE format('NULL')  END,
                CASE WHEN rec.typcategory = 'S' THEN FORMAT('MIN(LENGTH(%I))', rec.attname) ELSE format('NULL') END,
                CASE WHEN rec.typcategory = 'S' THEN FORMAT('MAX(LENGTH(%I))', rec.attname) ELSE format('NULL')  END,
                rec.attname,
                rec.attname,
                rec.relname );

query = 'insert into results (
    table_name ,
    column_name ,
    data_type ,
    min_value ,
    max_value ,
    avg_value ,
    min_length ,
    max_length  ,
    null_count  ,
    total_count ,
    null_percentage 
) ' || query;


EXECUTE query;

end loop;
end;
$$ language plpgsql;

-- run the inital load procedure 
call data_quality_profiling();

select * from results;
