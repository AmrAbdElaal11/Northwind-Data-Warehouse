call public.truncate_tables_in_schema('dwh' );
select table_name , column_name , null_count,total_count from staging.results;
---------------------------------------------------------------------------------------------------------------
select distinct * from staging.stg_orders;

-- 1. edh_orders
drop table edh_orders ;
CREATE TABLE edh_orders (
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
	ship_postal_code varchar(20) NULL,
	ship_country varchar(15) NULL
);
-- loading the edh_orders table

insert into edh_orders ( order_id, customer_id,employee_id , order_date, required_date, shipped_date, ship_via, freight, ship_name, ship_address, ship_city, ship_region, ship_postal_code, ship_country)
SELECT distinct order_id, customer_id, coalesce (employee_id,999), order_date, required_date, shipped_date, ship_via,
freight, ship_name, ship_address, ship_city, coalesce (ship_region,'NotProvided')as ship_region , 
coalesce (ship_postal_code ,'NotProvided')as ship_postal_code, ship_country
FROM staging.stg_orders;

select * from edh_orders eo ;


---------------------------------------------------------------------------------------------------------------
select count(*) from staging.stg_order_details sod ;
select table_name , column_name , null_count,total_count from staging.results where table_name='stg_order_details';

-- 2. edh_order_details
CREATE TABLE edh_order_details (
	order_details_sk serial not null,
	order_id int2 NOT NULL,
	product_id int2 NOT NULL,
	unit_price float4 NOT NULL,
	quantity int2 NOT NULL,
	discount float4 NOT NULL
);

-- loading the edh_order_details table from the staging table
insert into  edh_order_details (order_id , product_id , unit_price , quantity , discount)
select distinct * from staging.stg_order_details  ;



---------------------------------------------------------------------------------------------------------------
select * from staging.stg_employees se ;
select table_name , column_name , null_count,total_count from staging.results where table_name='stg_employees';

-- 3. edh_employees
CREATE TABLE edh_employees (
	employee_sk serial not null,
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
	photo_path varchar(255) null,
	valid_from date,
	valid_to date,
	is_current boolean
);

-- prepare sql query for improving the data quality
select distinct
employee_id, last_name, first_name, title, title_of_courtesy, birth_date, 
hire_date, address, city, coalesce(region,'NotProvided') as region, postal_code, 
country, '+'||REGEXP_REPLACE(home_phone , '(\.|\(|\)| |\-)','','g') as  home_phone, "extension", photo, notes,coalesce(reports_to,-1) as reports_to , photo_path
FROM staging.stg_employees;

-- loading and applying type 2
merge into edh_employees trgt
using  (select distinct
employee_id, last_name, first_name, title, title_of_courtesy, birth_date, 
hire_date, address, city, coalesce(region,'NotProvided') as region, postal_code, 
country, '+'||REGEXP_REPLACE(home_phone , '(\.|\(|\)| |\-)','','g') as  home_phone, "extension", photo, notes,coalesce(reports_to,-1) as reports_to , photo_path
FROM staging.stg_employees) s
on trgt.employee_id = s.employee_id
when matched and
		(   trgt.last_name <>s.last_name 
			or trgt.first_name <>s.first_name 
			or trgt.title <>s.title 
			or trgt.title_of_courtesy<>s.title_of_courtesy
			or trgt.birth_date <>s.  birth_date 
			or trgt.hire_date <>s.hire_date 
			or trgt.address <>s.address 
			or trgt.city <>s.city 
			or trgt.region <>s.region
			or trgt.postal_code <>s.postal_code 
			or trgt.country <>s.country 
			or trgt.home_phone <>s.home_phone 
			or trgt."extension" <>s."extension" 
			or trgt.photo <>s.photo 
			or trgt.notes <>s.notes 
			or trgt.reports_to <>s.reports_to
			or trgt.photo_path <>s.photo_path 
)
then
	update set valid_to = current_date - 1,
			   is_current= false 
	
when not matched then 
	insert (employee_id, last_name, first_name, title, title_of_courtesy, birth_date, hire_date, address, city, region, postal_code,
	country, home_phone, "extension", photo, notes, reports_to, photo_path, valid_from, valid_to, is_current)
	values (s.employee_id, s.last_name, s.first_name, s.title, s.title_of_courtesy, s.birth_date, s.hire_date, 
	s.address, s.city, s.region, s.postal_code, s.country, s.home_phone, s."extension", s.photo, notes, s.reports_to, 
	s.photo_path, current_date-2, null, true);

truncate table edh_employees;
select * from edh_employees ee ;


insert into edh_employees (employee_id, last_name, first_name, title, title_of_courtesy, birth_date, hire_date, address, city, region, postal_code,
	country, home_phone, "extension", photo, notes, reports_to, photo_path, valid_from, valid_to, is_current)
select distinct sp.employee_id, last_name, first_name, title, title_of_courtesy, birth_date, 
hire_date, address, city, coalesce(region,'NotProvided') as region, postal_code, 
country, '+'||REGEXP_REPLACE(home_phone , '(\.|\(|\)| |\-)','','g') as  home_phone, "extension", photo,
notes,coalesce(reports_to,-1) as reports_to , photo_path ,current_date , cast(null as date ) , true
from staging.stg_employees sp join (
select employee_id , employee_sk ,is_current ,max(employee_sk) over (partition by employee_id) mx
from edh_employees 
) ep on sp.employee_id = ep.employee_id
where employee_sk  =mx and  is_current = false ;



------------------------------------------------------------------------------------------------------
select * from staging.stg_shippers ss ;
select table_name , column_name , null_count,total_count from staging.results where table_name='stg_shippers';

--4. edh_shipper

CREATE TABLE edh_shippers (
	shipper_sk serial not null,
	shipper_id int2 NOT NULL,
	company_name varchar(40) NOT NULL,
	phone varchar(24) null,
	valid_from date,
	valid_to date,
	is_current boolean 
);

merge into edh_shippers trgt
using (select distinct shipper_id , company_name ,'+'||REGEXP_REPLACE(phone, '(\.|\(|\)| |\-)','','g') as phone
from staging.stg_shippers) s
on trgt.shipper_id = s.shipper_id
when matched and is_current = true 
     and (trgt.company_name <> s.company_name or trgt.phone <> s.phone )
     then update set valid_to = current_date - 1,
			   is_current= false 

when not matched then 
insert (shipper_id , company_name , phone,valid_from,valid_to,is_current)
values (s.shipper_id,s.company_name,s.phone,current_date,null,true);



select * from edh_shippers es ;

truncate table edh_shippers ;

-- insert the updated record 
insert into edh_shippers (shipper_id , company_name , phone,valid_from,valid_to,is_current)
select distinct  s.shipper_id,s.company_name,
'+'||REGEXP_REPLACE(s.phone, '(\.|\(|\)| |\-)','','g') as phone,
current_date , cast (null as date),true
from staging.stg_shippers s  join (
select shipper_id , shipper_sk ,is_current ,max(shipper_sk) over (partition by shipper_id) mx
from edh_shippers 
) es on s.shipper_id = es.shipper_id
where shipper_sk  = mx and  is_current = false ;

------------------------------------------------------------------------------------------------------
select * from staging.stg_categories sc ;
select table_name , column_name , null_count,total_count from staging.results where table_name='stg_categories';

-- 5. edh_categories type 1
CREATE TABLE edh_categories (
	category_id int2 NOT NULL,
	category_name varchar(15) NOT NULL,
	description text NULL,
	picture bytea NULL
);
insert into edh_categories values(999,'NotProvided','NotProvided',null);
-- loading the edh_categories applying type 1

merge into edh_categories ec
using (select distinct * from staging.stg_categories) sc
on ec.category_id = sc.category_id

when matched then
update set category_name = sc.category_name,
		   description = sc.description,
		   picture= sc.picture
when not matched then
insert (category_id, category_name, description, picture)
values (sc.category_id, sc.category_name, sc.description, sc.picture) 
;

select * from edh_categories ec ;

------------------------------------------------------------------------------------------------------
select *
from staging.stg_suppliers ss ;
select table_name , column_name , null_count,total_count from staging.results where table_name='stg_suppliers';


-- 6. edh_suppliers type 1
CREATE TABLE edh_suppliers (
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


-- loading the edh_suppliers applying type 1

merge into edh_suppliers es
using (select distinct 
			supplier_id,
			company_name,
			contact_name,
			contact_title,
			address,
			city,
			coalesce (region,'Not Provided') as region,
			postal_code,
			country,
			'+'||REGEXP_REPLACE(phone, '(\.|\(|\)| |\-)','','g') as phone,
			coalesce('+'||REGEXP_REPLACE( fax, '(\.|\(|\)| |\-)','','g'),'NotProvided')as fax ,
			coalesce (homepage,'Not Provided') as homepage
		from staging.stg_suppliers) ss
		
on es.supplier_id = ss.supplier_id

when matched then
update set 
supplier_id = ss.supplier_id,
company_name = ss.company_name,
contact_name = ss.contact_name,
contact_title = ss.contact_title,
address  = ss.address ,
city  = ss.city ,
region  = ss.region ,
postal_code = ss.postal_code,
country  = ss.country ,
phone  = ss.phone ,
fax  = ss.fax ,
homepage  = ss.homepage
when not matched then
insert (supplier_id,company_name,contact_name,contact_title,address ,city ,region ,postal_code,country ,phone ,fax ,homepage )
values (ss.supplier_id,ss.company_name,ss.contact_name,ss.contact_title,ss.address ,ss.city ,ss.region ,ss.postal_code,ss.country ,ss.phone ,ss.fax ,ss.homepage) 
;

select * from edh_suppliers es ;

truncate table edh_suppliers ;
------------------------------------------------------------------------------------------------------
select *
from staging.stg_products sp ;
select table_name , column_name , null_count,total_count from staging.results where table_name='stg_products';


-- 7. edh_products type 2

CREATE TABLE edh_products (
	product_sk serial not null,
	product_id int2 NOT NULL,
	product_name varchar(40) NOT NULL,
	supplier_id int2 NULL,
	category_id int2 NULL,
	quantity_per_unit varchar(20) NULL,
	unit_price float4 NULL,
	units_in_stock int2 NULL,
	units_on_order int2 NULL,
	reorder_level int2 NULL,
	discontinued int4 NOT null,
	valid_from date,
	valid_to date,
	is_current boolean,
	is_stockout boolean
);


-- loading and applying type 2

merge into edh_products ep
using (select distinct *,units_in_stock < reorder_level as stockout from staging.stg_products) sp 
on ep.product_id = sp.product_id

when matched and is_current = true and (
						 ep.product_name <> sp.product_name
						or ep.supplier_id <> sp.supplier_id
						or ep.category_id <> sp.category_id
						or ep.quantity_per_unit <> sp.quantity_per_unit
						or ep.unit_price <> sp.unit_price
						or ep.units_in_stock <> sp.units_in_stock
						or ep.units_on_order <> sp.units_on_order
						or ep.reorder_level <> sp.reorder_level
						or ep.discontinued <> sp.discontinued
						or ep.is_stockout <> sp.stockout
)
			
then
update set valid_to = current_date -1,
		   is_current= false

when not matched then
insert (product_id, product_name, supplier_id, category_id, quantity_per_unit, unit_price, 
units_in_stock, units_on_order, reorder_level, discontinued, valid_from, valid_to, is_current, is_stockout)
values (sp.product_id,sp.product_name,sp.supplier_id,sp.category_id,sp.quantity_per_unit,
sp.unit_price,sp.units_in_stock,sp.units_on_order,sp.reorder_level,sp.discontinued,
current_date,null,true,sp.stockout)
;

select *
from edh_products ep ;


insert into edh_products (product_id, product_name, supplier_id, category_id, quantity_per_unit, unit_price, 
units_in_stock, units_on_order, reorder_level, discontinued, valid_from, valid_to, is_current, is_stockout)
select distinct sp.product_id,sp.product_name,sp.supplier_id,sp.category_id,sp.quantity_per_unit,
sp.unit_price,sp.units_in_stock,sp.units_on_order,sp.reorder_level,sp.discontinued,
current_date,cast(null as date),true , units_in_stock < reorder_level as stockout
from staging.stg_products sp join (
select product_id , product_sk,is_current ,max(product_sk) over (partition by product_id) mx
from edh_products 
) ep on sp.product_id = ep.product_id
where product_sk  =mx and  is_current = false ;



------------------------------------------------------------------------------------------------------
select distinct * 
from staging.stg_customers sc where customer_id ~ '\d+' = true

intersect 

select * 
from staging.stg_customers sc where customer_id ~ '\d+' = false;

select table_name , column_name , null_count,total_count from staging.results where table_name='stg_customers';

-- 8. edh_custoemrs type 2
CREATE TABLE edh_customers (
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

merge into edh_customers ec
using (
SELECT distinct customer_id, company_name, contact_name, contact_title, address, city,
coalesce (region,'IncorrectRegion') as region, postal_code, country, 
'+'||REGEXP_REPLACE(phone, '(\.|\(|\)| |\-)','','g') as phone, 
coalesce('+'||REGEXP_REPLACE(fax, '(\.|\(|\)| |\-)','','g'),'NotProvided' )as fax
from staging.stg_customers 
where customer_id ~ '\d+' = false
order by customer_id ) sc 
on ec.customer_id = sc.customer_id

when matched and is_current = true 
			 and (
			   ec.company_name <> sc.company_name
			or ec.contact_name <> sc.contact_name
			or ec.contact_title <> sc.contact_title
			or ec.address <> sc.address
			or ec.city <> sc.city
			or ec.region <> sc.region
			or ec.postal_code <> sc.postal_code
			or ec.country <> sc.country
			or ec.phone <> sc.phone
			or ec.fax <> sc.fax		 
			 )
then
update set valid_to = current_date -1,
		   is_current= false

when not matched  then 
insert (customer_id,company_name,contact_name,contact_title,address,city,region,postal_code,country,phone,fax,
valid_from , valid_to , is_current)
values (sc.customer_id,sc.company_name,sc.contact_name,sc.contact_title,sc.address,sc.city,sc.region,sc.postal_code,sc.country,sc.phone,
sc.fax,current_date , null , true);

select * from edh_customers ec ;
truncate table edh_customers ;




insert into edh_customers (customer_id,company_name,contact_name,contact_title,address,city,region,postal_code,country,phone,fax,
valid_from , valid_to , is_current)
select distinct sc.customer_id,sc.company_name,sc.contact_name,sc.contact_title,sc.address,sc.city,
coalesce (sc.region,'IncorrectRegion') as region,sc.postal_code,
sc.country,
'+'||REGEXP_REPLACE(sc.phone, '(\.|\(|\)| |\-)','','g') as phone, 
coalesce('+'||REGEXP_REPLACE(sc.fax, '(\.|\(|\)| |\-)','','g'),'NotProvided' )as fax,
current_date, cast(null as date) , true 
from staging.stg_customers sc join (
select customer_id , customer_sk ,is_current ,max(customer_sk) over (partition by customer_id) mx
from edh_customers 
) ec on sc.customer_id = ec.customer_id
where customer_sk  = mx and  is_current = false ;

------------------------------------------------------------------------------------------------------
with cte as (
select distinct * from 
staging.stg_employee_territories et )
select * , count(territory_id) over (partition by territory_id) from cte;

select table_name , column_name , null_count,total_count from staging.results where table_name='stg_employee_territories';


-- 9. edh_emloyee_territories
CREATE TABLE edh_employee_territories (
	employee_id int2 NOT NULL,
	territory_id varchar(20) NOT NULL
);


merge into edh_employee_territories trgt
using (select distinct * from staging.stg_employee_territories) ss
on trgt.territory_id = ss.territory_id
when matched then
update set 
employee_id = ss.employee_id
when not matched then
insert (employee_id , territory_id)
values (ss.employee_id , ss.territory_id) 
;


select * from edh_employee_territories eet  ;


------------------------------------------------------------------------------------------------------
select * from staging.stg_territories st ;
-- 10. edh_territories
drop table stg_territories;
CREATE TABLE edh_territories (
	territory_id varchar(20) NOT NULL,
	territory_description varchar(60) NOT NULL,
	region_id int2 NOT NULL
);

merge into edh_territories trgt
using (select distinct * from staging.stg_territories) ss
on trgt.territory_id = ss.territory_id
when matched then
update set 
territory_description = ss.territory_description,
region_id = ss.region_id

when not matched then
insert (territory_description , territory_id, region_id)
values (ss.territory_description , ss.territory_id,ss.region_id ) 
;



------------------------------------------------------------------------------------------------------
select * from staging.stg_region sr ;
-- 11. edh_region

CREATE TABLE edh_region (
	region_id int2 NOT NULL,
	region_description varchar(60) NOT NULL
);

merge into edh_region trgt
using (select distinct * from staging.stg_region) ss
on trgt.region_id = ss.region_id
when matched then
update set 
region_description = ss.region_description
when not matched then
insert (region_id,region_description)
values (ss.region_id , ss.region_description) 
;






