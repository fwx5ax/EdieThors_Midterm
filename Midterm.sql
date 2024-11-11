use sakila;
use sakila_db;
# at this point, notebook has been run until last step
# CREATE DATE DIMENSTION

use sakila_db;
DROP TABLE IF EXISTS dim_date;
CREATE TABLE dim_date(
 date_key int NOT NULL,
 full_date date NULL,
 date_name char(11) NOT NULL,
 date_name_us char(11) NOT NULL,
 date_name_eu char(11) NOT NULL,
 day_of_week tinyint NOT NULL,
 day_name_of_week char(10) NOT NULL,
 day_of_month tinyint NOT NULL,
 day_of_year smallint NOT NULL,
 weekday_weekend char(10) NOT NULL,
 week_of_year tinyint NOT NULL,
 month_name char(10) NOT NULL,
 month_of_year tinyint NOT NULL,
 is_last_day_of_month char(1) NOT NULL,
 calendar_quarter tinyint NOT NULL,
 calendar_year smallint NOT NULL,
 calendar_year_month char(10) NOT NULL,
 calendar_year_qtr char(10) NOT NULL,
 fiscal_month_of_year tinyint NOT NULL,
 fiscal_quarter tinyint NOT NULL,
 fiscal_year int NOT NULL,
 fiscal_year_month char(10) NOT NULL,
 fiscal_year_qtr char(10) NOT NULL,
  PRIMARY KEY (`date_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

# Here is the PopulateDateDimension Stored Procedure: 
delimiter //

DROP PROCEDURE IF EXISTS PopulateDateDimension//
CREATE PROCEDURE PopulateDateDimension(BeginDate DATETIME, EndDate DATETIME)
BEGIN

	# =============================================
	# Description: http://arcanecode.com/2009/11/18/populating-a-kimball-date-dimension/
	# =============================================

	# A few notes, this code does nothing to the existing table, no deletes are triggered before hand.
    # Because the DateKey is uniquely indexed, it will simply produce errors if you attempt to insert duplicates.
	# You can however adjust the Begin/End dates and rerun to safely add new dates to the table every year.
	# If the begin date is after the end date, no errors occur but nothing happens as the while loop never executes.

	# Holds a flag so we can determine if the date is the last day of month
	DECLARE LastDayOfMon CHAR(1);

	# Number of months to add to the date to get the current Fiscal date
	DECLARE FiscalYearMonthsOffset INT;

	# These two counters are used in our loop.
	DECLARE DateCounter DATETIME;    #Current date in loop
	DECLARE FiscalCounter DATETIME;  #Fiscal Year Date in loop

	# Set this to the number of months to add to the current date to get the beginning of the Fiscal year.
    # For example, if the Fiscal year begins July 1, put a 6 there.
	# Negative values are also allowed, thus if your 2010 Fiscal year begins in July of 2009, put a -6.
	SET FiscalYearMonthsOffset = 6;

	# Start the counter at the begin date
	SET DateCounter = BeginDate;

	WHILE DateCounter <= EndDate DO
		# Calculate the current Fiscal date as an offset of the current date in the loop
		SET FiscalCounter = DATE_ADD(DateCounter, INTERVAL FiscalYearMonthsOffset MONTH);

		# Set value for IsLastDayOfMonth
		IF MONTH(DateCounter) = MONTH(DATE_ADD(DateCounter, INTERVAL 1 DAY)) THEN
			SET LastDayOfMon = 'N';
		ELSE
			SET LastDayOfMon = 'Y';
		END IF;

		# add a record into the date dimension table for this date
		INSERT INTO dim_date
			(date_key
			, full_date
			, date_name
			, date_name_us
			, date_name_eu
			, day_of_week
			, day_name_of_week
			, day_of_month
			, day_of_year
			, weekday_weekend
			, week_of_year
			, month_name
			, month_of_year
			, is_last_day_of_month
			, calendar_quarter
			, calendar_year
			, calendar_year_month
			, calendar_year_qtr
			, fiscal_month_of_year
			, fiscal_quarter
			, fiscal_year
			, fiscal_year_month
			, fiscal_year_qtr)
		VALUES  (
			( YEAR(DateCounter) * 10000 ) + ( MONTH(DateCounter) * 100 ) + DAY(DateCounter)  #DateKey
			, DateCounter #FullDate
			, CONCAT(CAST(YEAR(DateCounter) AS CHAR(4)),'/', DATE_FORMAT(DateCounter,'%m'),'/', DATE_FORMAT(DateCounter,'%d')) #DateName
			, CONCAT(DATE_FORMAT(DateCounter,'%m'),'/', DATE_FORMAT(DateCounter,'%d'),'/', CAST(YEAR(DateCounter) AS CHAR(4)))#DateNameUS
			, CONCAT(DATE_FORMAT(DateCounter,'%d'),'/', DATE_FORMAT(DateCounter,'%m'),'/', CAST(YEAR(DateCounter) AS CHAR(4)))#DateNameEU
			, DAYOFWEEK(DateCounter) #DayOfWeek
			, DAYNAME(DateCounter) #DayNameOfWeek
			, DAYOFMONTH(DateCounter) #DayOfMonth
			, DAYOFYEAR(DateCounter) #DayOfYear
			, CASE DAYNAME(DateCounter)
				WHEN 'Saturday' THEN 'Weekend'
				WHEN 'Sunday' THEN 'Weekend'
				ELSE 'Weekday'
			END #WeekdayWeekend
			, WEEKOFYEAR(DateCounter) #WeekOfYear
			, MONTHNAME(DateCounter) #MonthName
			, MONTH(DateCounter) #MonthOfYear
			, LastDayOfMon #IsLastDayOfMonth
			, QUARTER(DateCounter) #CalendarQuarter
			, YEAR(DateCounter) #CalendarYear
			, CONCAT(CAST(YEAR(DateCounter) AS CHAR(4)),'-',DATE_FORMAT(DateCounter,'%m')) #CalendarYearMonth
			, CONCAT(CAST(YEAR(DateCounter) AS CHAR(4)),'Q',QUARTER(DateCounter)) #CalendarYearQtr
			, MONTH(FiscalCounter) #[FiscalMonthOfYear]
			, QUARTER(FiscalCounter) #[FiscalQuarter]
			, YEAR(FiscalCounter) #[FiscalYear]
			, CONCAT(CAST(YEAR(FiscalCounter) AS CHAR(4)),'-',DATE_FORMAT(FiscalCounter,'%m')) #[FiscalYearMonth]
			, CONCAT(CAST(YEAR(FiscalCounter) AS CHAR(4)),'Q',QUARTER(FiscalCounter)) #[FiscalYearQtr]
		);
		# Increment the date counter for next pass thru the loop
		SET DateCounter = DATE_ADD(DateCounter, INTERVAL 1 DAY);
	END WHILE;
END//

CALL PopulateDateDimension('2000-01-01', '2010-12-31');

SELECT MIN(full_date) AS BeginDate
	, MAX(full_date) AS EndDate
FROM dim_date;

# RUN LAST CELL IN NOTEBOOK

# CREATE DIMENSION TABLE CUSTOMER
# dropped one column - active
use sakila_db;
CREATE TABLE `dim_customer` (
  `customer_id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `store_id` tinyint unsigned NOT NULL,
  `first_name` varchar(45) NOT NULL,
  `last_name` varchar(45) NOT NULL,
  `email` varchar(50) DEFAULT NULL,
  `address_id` smallint unsigned NOT NULL,
  `create_date` datetime NOT NULL,
  `last_update` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`customer_id`),
  KEY `idx_fk_store_id` (`store_id`),
  KEY `idx_fk_address_id` (`address_id`),
  KEY `idx_last_name` (`last_name`)
) ENGINE=InnoDB AUTO_INCREMENT=600 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
INSERT INTO `sakila_db`.`dim_customer`
(`customer_id`,
`store_id`,
`first_name`,
`last_name`,
`email`,
`address_id`,
`create_date`,
`last_update`)
SELECT `customer`.`customer_id`,
    `customer`.`store_id`,
    `customer`.`first_name`,
    `customer`.`last_name`,
    `customer`.`email`,
    `customer`.`address_id`,
    `customer`.`create_date`,
    `customer`.`last_update`
FROM `sakila`.`customer`;

# CREATE FILM DIMENSION TABLE
# dropped two columns - original_language_id and last_update

CREATE TABLE `dim_film` (
  `film_id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(128) NOT NULL,
  `description` text,
  `release_year` year DEFAULT NULL,
  `language_id` tinyint unsigned NOT NULL,
  `rental_duration` tinyint unsigned NOT NULL DEFAULT '3',
  `rental_rate` decimal(4,2) NOT NULL DEFAULT '4.99',
  `length` smallint unsigned DEFAULT NULL,
  `replacement_cost` decimal(5,2) NOT NULL DEFAULT '19.99',
  `rating` enum('G','PG','PG-13','R','NC-17') DEFAULT 'G',
  `special_features` set('Trailers','Commentaries','Deleted Scenes','Behind the Scenes') DEFAULT NULL,
  PRIMARY KEY (`film_id`),
  KEY `idx_title` (`title`)
) ENGINE=InnoDB AUTO_INCREMENT=1001 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
INSERT INTO `sakila_db`.`dim_film`
(`film_id`,
`title`,
`description`,
`release_year`,
`language_id`,
`rental_duration`,
`rental_rate`,
`length`,
`replacement_cost`,
`rating`,
`special_features`)
SELECT `film`.`film_id`,
    `film`.`title`,
    `film`.`description`,
    `film`.`release_year`,
    `film`.`language_id`,
    `film`.`rental_duration`,
    `film`.`rental_rate`,
    `film`.`length`,
    `film`.`replacement_cost`,
    `film`.`rating`,
    `film`.`special_features`
FROM `sakila`.`film`;

#CREATE FACT TABLE
# dropped a column - last update

CREATE TABLE `fact_rentals` (
  `rental_id` int NOT NULL AUTO_INCREMENT,
  `rental_date` datetime NOT NULL,
  `inventory_id` mediumint unsigned NOT NULL,
  `customer_id` smallint unsigned NOT NULL,
  `return_date` datetime DEFAULT NULL,
  `staff_id` tinyint unsigned NOT NULL,
  PRIMARY KEY (`rental_id`),
  UNIQUE KEY `rental_date` (`rental_date`,`inventory_id`,`customer_id`),
  KEY `idx_fk_inventory_id` (`inventory_id`),
  KEY `idx_fk_customer_id` (`customer_id`),
  KEY `idx_fk_staff_id` (`staff_id`)
) ENGINE=InnoDB AUTO_INCREMENT=16050 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
INSERT INTO `sakila_db`.`fact_rentals`
(`rental_id`,
`rental_date`,
`inventory_id`,
`customer_id`,
`return_date`,
`staff_id`)
SELECT `rental`.`rental_id`,
    `rental`.`rental_date`,
    `rental`.`inventory_id`,
    `rental`.`customer_id`,
    `rental`.`return_date`,
    `rental`.`staff_id`
FROM `sakila`.`rental`;

#QUERIES USING FACT TABLE AND DIMENSION TABLES:

#Total revenue by customer - this query involves the fact table, customer dimension table, and payment dimension table
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(p.amount) AS total_revenue
FROM fact_rentals r
JOIN dim_customer c ON r.customer_id = c.customer_id
JOIN dim_payment p ON r.rental_id = p.rental_id
GROUP BY c.customer_id, customer_name
ORDER BY total_revenue DESC;

# Rented films by "popularity" or number of rentals - this query uses the fact table, the inventory dimension table, 
# and the film dimension table
SELECT 
    f.film_id,
    f.title AS film_title,
    COUNT(r.rental_id) AS rental_count
FROM fact_rentals r
JOIN dim_inventory i ON r.inventory_id = i.inventory_id
JOIN dim_film f ON i.film_id = f.film_id
GROUP BY f.film_id, film_title
ORDER BY rental_count DESC;

# Customer information and total payments, total amount paid, average payment, min payment, and max payment
# this query uses the fact table, the customer dimension table, and the payment dimension table
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(p.payment_key) AS total_payments,
    SUM(p.amount) AS total_paid,
    AVG(p.amount) AS avg_payment,
    MIN(p.amount) AS min_payment,
    MAX(p.amount) AS max_payment
FROM dim_customer c
JOIN fact_rentals r ON c.customer_id = r.customer_id
JOIN dim_payment p ON r.rental_id = p.rental_id
GROUP BY c.customer_id, customer_name
ORDER BY total_paid DESC;

# Total movie rentals by year and month; 
SELECT 
    YEAR(r.rental_date) AS rental_year,
    MONTH(r.rental_date) AS rental_month,
    COUNT(r.rental_id) AS total_rentals
FROM fact_rentals r
GROUP BY rental_year, rental_month
ORDER BY rental_year, rental_month;

# How many individuals have rented each movie - ordered by least rented movie
SELECT 
    f.film_id,
    f.title AS film_title,
    COUNT(DISTINCT r.customer_id) AS unique_customers
FROM fact_rentals r
JOIN dim_inventory i ON r.inventory_id = i.inventory_id
JOIN dim_film f ON i.film_id = f.film_id
GROUP BY f.film_id, film_title
ORDER BY unique_customers ASC;

# Top 20 films by total revenue
SELECT 
    f.film_id,
    f.title AS film_title,
    SUM(p.amount) AS total_revenue
FROM fact_rentals r
JOIN dim_inventory i ON r.inventory_id = i.inventory_id
JOIN dim_film f ON i.film_id = f.film_id
JOIN dim_payment p ON r.rental_id = p.rental_id
GROUP BY f.film_id, film_title
ORDER BY total_revenue DESC
LIMIT 20;
