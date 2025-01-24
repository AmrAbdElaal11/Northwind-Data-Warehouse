

--------------------------------------------------------------
(select ep.product_id , ep.product_name ,ep.supplier_id ,ec.category_id ,category_name ,description ,ep.quantity_per_unit ,ep.unit_price 
,ep.units_in_stock ,ep.units_on_order ,ep.reorder_level ,ep.discontinued ,ep.is_stockout 
from edh.edh_products ep inner join edh.edh_categories ec
on ep.category_id = ec.category_id ) ;
-- loading products dimension
select * from dim_products ep ;

truncate table dim_products ;

merge into dim_products ep
using (select epp.product_id , epp.product_name ,epp.supplier_id ,
coalesce (ec.category_id,999) as category_id ,coalesce(category_name,'Notprovided') category_name,coalesce (description,'Notprovided')description,picture ,epp.quantity_per_unit ,epp.unit_price 
,epp.units_in_stock ,epp.units_on_order ,epp.reorder_level ,epp.discontinued ,epp.is_stockout , epp.is_current
from edh.edh_products epp left  join edh.edh_categories ec
on epp.category_id = ec.category_id ) sp 
on ep.product_id = sp.product_id

when matched and sp.is_current = true and ep.is_current = true and (
						 ep.product_name <> sp.product_name
						or ep.supplier_id <> sp.supplier_id
						or ep.category_id <> sp.category_id
						or ep.category_name <> sp.category_name
						or ep.description <> sp.description
						or ep.picture <> sp.picture
						or ep.quantity_per_unit <> sp.quantity_per_unit
						or ep.unit_price <> sp.unit_price
						or ep.units_in_stock <> sp.units_in_stock
						or ep.units_on_order <> sp.units_on_order
						or ep.reorder_level <> sp.reorder_level
						or ep.discontinued <> sp.discontinued
						or ep.is_stockout <> sp.is_stockout
)
			
then
update set valid_to = current_date -1,
		   is_current= false

when not matched then
insert (product_id, product_name, supplier_id, category_id,category_name,description,picture, quantity_per_unit, unit_price, 
units_in_stock, units_on_order, reorder_level, discontinued, valid_from, valid_to, is_current, is_stockout)
values (sp.product_id,sp.product_name,sp.supplier_id,sp.category_id,sp.category_name,sp.description,sp.picture,sp.quantity_per_unit,
sp.unit_price,sp.units_in_stock,sp.units_on_order,sp.reorder_level,sp.discontinued,
current_date,null,true,sp.is_stockout)
;


insert into dim_products (product_id, product_name, supplier_id, category_id,category_name,description,picture, quantity_per_unit, unit_price, 
units_in_stock, units_on_order, reorder_level, discontinued, valid_from, valid_to, is_current, is_stockout)
select ep.product_id , ep.product_name ,ep.supplier_id ,ec.category_id ,category_name ,description,picture ,ep.quantity_per_unit ,ep.unit_price 
,ep.units_in_stock ,ep.units_on_order ,ep.reorder_level ,ep.discontinued,current_date , cast(null as date),true ,ep.is_stockout 
from edh.edh_products ep inner join edh.edh_categories ec
on ep.category_id = ec.category_id   join (
select product_id , product_sk,is_current ,max(product_sk) over (partition by product_id) mx
from dim_products 
) epp on ep.product_id = epp.product_id
where epp.product_sk = mx and  epp.is_current = false and ep.is_current =true;


--------------------------------------------------------------
select * from edh.edh_customers e_customers


-- Loading Customers Dime


select * from dim_customers dc ;



merge into dim_customers dim
using edh.edh_customers ed
on dim.customer_id = ed.customer_id

when matched  and dim.is_current = true and ed.is_current = true
				and (
				dim.company_name <> ed.company_name
				or dim.contact_name <> ed.contact_name
				or dim.contact_title <> ed.contact_title
				or dim.address <> ed.address
				or dim.city <> ed.city
				or dim.region <> ed.region
				or dim.postal_code <> ed.postal_code
				or dim.country <> ed.country
				or dim.phone <> ed.phone
				or dim.fax <> ed.fax
				)


then
update set valid_to = current_date -1,
		   is_current= false
when not matched then
insert (customer_id,company_name,contact_name,contact_title,address,city,region,postal_code,country,phone,fax,
valid_from , valid_to , is_current)
values (ed.customer_id,ed.company_name,ed.contact_name,ed.contact_title,ed.address,ed.city,ed.region,ed.postal_code,ed.country,ed.phone,
ed.fax,current_date , null , true);

insert into dim_customers (customer_id,company_name,contact_name,contact_title,address,city,region,postal_code,country,phone,fax,
valid_from , valid_to , is_current)
select ed.customer_id,ed.company_name,ed.contact_name,ed.contact_title,ed.address,ed.city,ed.region,ed.postal_code,ed.country,ed.phone,
ed.fax,current_date , cast(null as date) , true 
from edh.edh_customers ed join (
select customer_id , customer_sk ,is_current ,max(customer_sk) over (partition by customer_id) mx
from dim_customers 
) ec on ed.customer_id = ec.customer_id
where ec.customer_sk  = mx and  ec.is_current = false and ed.is_current =true ;

--------------------------------------------------------------
select * from edh.edh_employees ee ;
-- loading the Employees Dimension
select * from dim_employees de ;

truncate table dim_employees ;

merge into dim_employees trgt
using  edh.edh_employees s
on trgt.employee_id = s.employee_id
when matched and trgt.is_current = true and s.is_current = true and 
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
	s.photo_path, current_date, null, true);

insert into dim_employees (employee_id,valid_from, valid_to, is_current)values(999,current_date, null, true);


insert into dim_employees (employee_id, last_name, first_name, title, title_of_courtesy, birth_date, hire_date, address, city, region, postal_code,
	country, home_phone, "extension", photo, notes, reports_to, photo_path, valid_from, valid_to, is_current)
select s.employee_id, s.last_name, s.first_name, s.title, s.title_of_courtesy, s.birth_date, s.hire_date, 
	s.address, s.city, s.region, s.postal_code, s.country, s.home_phone, s."extension", s.photo, notes, s.reports_to, 
	s.photo_path, current_date, null::date, true
from edh.edh_employees s join (
select employee_id , employee_sk ,is_current ,max(employee_sk) over (partition by employee_id) mx
from dim_employees 
) ep on s.employee_id = ep.employee_id
where ep.employee_sk  =mx and  ep.is_current = false and s.is_current = true ;



--------------------------------------------------------------
select * from edh.edh_shippers es ;

-- loading the shippers dimension

select * from dim_shippers ds ;

merge into dim_shippers trgt
using edh.edh_shippers s
on trgt.shipper_id = s.shipper_id
when matched and trgt.is_current = true and s.is_current = true
     and (trgt.company_name <> s.company_name or trgt.phone <> s.phone )
     then update set valid_to = current_date - 1,
			   is_current= false 

when not matched then 
insert (shipper_id , company_name , phone,valid_from,valid_to,is_current)
values (s.shipper_id,s.company_name,s.phone,current_date,null,true);

insert into dim_shippers (shipper_id , company_name , phone,valid_from,valid_to,is_current)
select s.shipper_id,s.company_name,s.phone,current_date,cast(null as date),true
from edh.edh_shippers s  join (
select shipper_id , shipper_sk ,is_current ,max(shipper_sk) over (partition by shipper_id) mx
from dim_shippers 
) es on s.shipper_id = es.shipper_id
where es.shipper_sk  = mx and  es.is_current = false s.is_current = true;


--------------------------------------------------------------
select * from edh.edh_suppliers es ;
-- loading the supplier dimension
select * from dim_suppliers ds ;


merge into dim_suppliers es
using edh.edh_suppliers ss
		
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


--------------------------------------------------------------
-- loading the data dimension
select min (order_date)
from edh.edh_orders eo 
union
select max (order_date)
from edh.edh_orders eo 
where order_date <> '2099-12-31'
union
select max (shipped_date)
from edh.edh_orders eo ;


select * from dim_date dd ;

DO $$
DECLARE
    start_date DATE := '1996-01-01';
    end_date DATE := '1999-12-31';
    curr_date DATE;
BEGIN
    curr_date := start_date;
    WHILE curr_date <= end_date LOOP
        INSERT INTO dim_date (
            date_sk,
            date,
            weekday,
            weekday_num,
            day_month,
            day_of_year,
            week_of_year,
            iso_week,
            month_name,
            month_name_short,
            quarter,
            year
        )
        VALUES (
            TO_CHAR(curr_date, 'YYYYMMDD')::INTEGER, -- date_key
            curr_date,                              -- date
            TO_CHAR(curr_date, 'Day')::VARCHAR(9), -- weekday
            EXTRACT(DOW FROM curr_date),           -- weekday_num
            EXTRACT(DAY FROM curr_date),           -- day_month
            EXTRACT(DOY FROM curr_date),           -- day_of_year
            EXTRACT(WEEK FROM curr_date),          -- week_of_year
            TO_CHAR(curr_date, 'IYYY-"W"IW')::VARCHAR(10), -- iso_week
            TO_CHAR(curr_date, 'Month')::VARCHAR(9),       -- month_name
            TO_CHAR(curr_date, 'Mon')::CHAR(3),            -- month_name_short
            EXTRACT(QUARTER FROM curr_date),       -- quarter
            EXTRACT(YEAR FROM curr_date)           -- year
        );
        curr_date := curr_date + INTERVAL '1 day';
    END LOOP;
END $$;

insert into dim_date  (date_sk,date) values(-1,NULL);
select * from dim_date;





--------------------------------------------------------------
-- loadint the fact ordres table

insert into fct_orders ( order_id, customer_fk, employee_fk, product_fk, shipper_fk, order_date_fk, required_date_fk, shipped_date_fk, unitprice, quantity, discount, freight, ship_name)
SELECT eo.order_id, 
customer_sk, 
employee_sk, 
product_sk,
shipper_sk, 
case when dd.date is null then -1 else dd.date_sk end as date_sk_ord,
case when ddd.date is null then -1 else ddd.date_sk end as date_sk_req,
case when dddd.date is null then -1 else dddd.date_sk end as date_sk_ship,
eod.unit_price,
eod.quantity,
eod.discount,
freight, 
ship_name
from edh.edh_orders eo
inner join edh.edh_order_details eod on eo.order_id = eod.order_id
inner join dim_customers dc  on eo.customer_id = dc.customer_id
inner join dim_employees de on eo.employee_id = de.employee_id 
left join dim_date dd on eo.order_date = dd.date
left join dim_date ddd on eo.required_date = ddd.date
left join dim_date dddd on eo.shipped_date = dddd.date
inner join dim_shippers ds on eo.ship_via = ds.shipper_id
inner join dim_products dp on dp.product_id = eod.product_id;



