### creating database supermarket
create database supermarket;
use supermarket;

create table aisles(id int, aisle varchar(50) not null, primary key(id));
create table departments(id int(10),department varchar(30) not null, primary key(id));
create table product(id int(11), name varchar(20) not null, aisle_id int(10) not null, department_id int(10) not null, primary key(id),
foreign key(aisle_id)
		references aisles(id)
        on delete no action
        on update cascade,
	
foreign key(department_id)
		references departments(id)
        on delete no action
        on update cascade
);

create table orders(
id int,
user_id int not null,
eval_set varchar(10) not null,
order_number int not null,
order_dow int,
order_hour_of_day int,
days_since_prior_order int,
primary key(id)
);

create table order_products(
order_id int not null,
product_id int not null,
add_to_cart_order int not null,
reordered int not null,

foreign key (order_id)
		references orders(id)
    on delete no action
    on update cascade,
    
foreign key(product_id)
		references product(id)
    on delete no action
    on update cascade
    );

## importing data
load data local infile 'C:/Users/surbh/Downloads/Supermarket-Data-Analysis-using-SQL-master/Supermarket-Data-Analysis-using-SQL-master/aisles.csv' into table aisles
fields terminated by ',' lines terminated by '\n' ignore 1 lines;
show global variables like 'local_infile';
set global local_infile = true;
-- local_infile=1 -u root -root supermarket;

load data local infile 'C:/Users/surbh/Downloads/Supermarket-Data-Analysis-using-SQL-master/Supermarket-Data-Analysis-using-SQL-master/departments.csv' into table departments
fields terminated by ',' lines terminated by '\n' ignore 1 lines;

load data local infile 'C:/Users/surbh/Downloads/Supermarket-Data-Analysis-using-SQL-master/Supermarket-Data-Analysis-using-SQL-master/orders_small_version.csv' into table orders
fields terminated by ',' lines terminated by '\n' ignore 1 lines;

load data local infile 'C:/Users/surbh/Downloads/Supermarket-Data-Analysis-using-SQL-master/Supermarket-Data-Analysis-using-SQL-master/products.csv' into table product
fields terminated by ',' lines terminated by '\n' ignore 1 lines;

set global max_allowed_packet=104857600; 

load data local infile 'C:/Users/surbh/Downloads/Supermarket-Data-Analysis-using-SQL-master/Supermarket-Data-Analysis-using-SQL-master/order_products.csv' into table orders_product
fields terminated by ',' lines terminated by '\n' ignore 1 lines;

# top 10 products sales for each day of the week
SET @rank := 0; # initial value

SELECT day, id, name, total_amount
FROM
	(SELECT id, name, total_amount , day,
	@rank := IF(@current_day = day, @rank + 1, 1) AS rankval,
	@current_day := day
	FROM
			(SELECT p.id, p.name , count(*) AS total_amount, o.order_dow AS day
			FROM
			product AS p INNER JOIN
			orders_product AS op ON op.product_id = p.id INNER JOIN
			orders AS o ON op.order_id=o.id
			GROUP BY id,name,day
            HAVING day BETWEEN 1 AND 5) AS t1
	ORDER BY day,total_amount DESC) AS t2
WHERE rankval<=10;

# 5 most popular products in each aisle from Monday to Friday

SET @rank := 0; # initial value

SELECT  aisle, day, id as product_id FROM
	(SELECT day, aisle, id, total_amount, 
	@rank := IF(@current_aisle=aisle AND @current_day = day, @rank + 1, 1) AS rankval,
	@current_day := day,
    @current_aisle := aisle
    FROM
			(SELECT p.id ,a.aisle as aisle, count(*) AS total_amount, o.order_dow AS day
			FROM
			product AS p INNER JOIN
			order_products AS op ON op.product_id = p.id INNER JOIN
			orders AS o ON op.order_id=o.id
            INNER JOIN aisles AS a ON p.aisle_id=a.id
			GROUP BY id, a.aisle ,day
            Having day BETWEEN 1 AND 5) AS t1
	ORDER BY aisle, day,total_amount DESC) as t2
WHERE rankval<=5;

# top 10 products that the users have the most frequent reorder rate

SELECT product_id
FROM orders_product
GROUP BY product_id
ORDER BY sum(reordered)/count(*) DESC
LIMIT 10;


# shopper’s aisle list for each order

SELECT op.order_id, a.id as aisle_id
FROM orders_product AS op
INNER JOIN aisles AS a ON op.product_id=a.id
GROUP BY op.order_id, a.id;


#most popular shopping path
SELECT aisles, COUNT(*) AS count FROM
	(SELECT order_id, GROUP_CONCAT(DISTINCT(a.id) ORDER BY a.id SEPARATOR ' ') as aisles
	FROM orders_product AS op
	INNER JOIN product AS p ON op.product_id=p.id
    INNER JOIN aisles AS a ON p.aisle_id=a.id
	GROUP BY op.order_id
    HAVING COUNT(DISTINCT(a.id))>=2 ) AS t
GROUP BY aisles
ORDER BY count DESC ;


