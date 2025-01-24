
-- the date dimension 

create table dim_date (
date_sk int not null ,
date date ,
weekday VARCHAR(9),
    weekday_num INTEGER,
    day_month INTEGER,
    day_of_year INTEGER,
    week_of_year INTEGER,
    iso_week VARCHAR(10),
    month_name VARCHAR(9),
    month_name_short CHAR(3),
    quarter INTEGER,
    year INTEGER

);

-------------------------------------------------------------------------------------------------------------------

-- customers dimensions

CREATE TABLE dim_customers (
	customer_sk serial not null,
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
	fax varchar(24) null,
	valid_from date,
	valid_to date,
	is_current boolean
);

-------------------------------------------------------------------------------------------------------------------
-- the shippers dimension
CREATE TABLE dim_shippers (
	shipper_sk serial not null,
	shipper_id int2 NOT NULL,
	company_name varchar(40) NOT NULL,
	phone varchar(24) null,
	valid_from date,
	valid_to date,
	is_current boolean 
);


-------------------------------------------------------------------------------------------------------------------
-- the employees dimension

CREATE TABLE dim_employees (
	employee_sk serial not null,
	employee_id int2 NOT NULL,
	last_name varchar(20)  NULL,
	first_name varchar(10)  NULL,
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
	photo_path varchar(255) null,
	valid_from date,
	valid_to date,
	is_current boolean
);

-------------------------------------------------------------------------------------------------------------------

-- supplier dimension
CREATE TABLE dim_suppliers (
	supplier_sk serial not null,
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
-------------------------------------------------------------------------------------------------------------------
-- products dimension

CREATE TABLE dim_products (
	product_sk serial not null,
	product_id int2 NOT NULL,
	product_name varchar(40) NOT NULL,
	supplier_id int2 NULL,
	category_id int2 NULL,
	category_name varchar(15) NOT NULL,
	description text NULL,
	picture bytea null,
	quantity_per_unit varchar(20) NULL,
	unit_price float4 NULL,
	units_in_stock int2 NULL,
	units_on_order int2 NULL,
	reorder_level int2 NULL,
	discontinued int4 NOT null,
	is_stockout boolean,
	valid_from date,
	valid_to date,
	is_current boolean

);


-------------------------------------------------------------------------------------------------------------------
-- ordres fact table
create table fct_orders (
order_sk serial not null,
order_id bigint not null,
customer_fk bigint,
employee_fk bigint,
product_fk bigint,
shipper_fk bigint,
order_date_fk bigint,
required_date_fk bigint,
shipped_date_fk bigint,
unitprice float4,
quantity bigint,
discount float4,
freight float4,
ship_name varchar(50)
);

