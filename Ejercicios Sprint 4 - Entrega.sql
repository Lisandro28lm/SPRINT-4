CREATE DATABASE if not exists operaciones;

USE operaciones;

###  -- Creamos una tabla de usuarios general
    
	CREATE TABLE IF NOT EXISTS users_gral (
	id INT PRIMARY KEY,
	name VARCHAR(100),
	surname VARCHAR(100),
	phone VARCHAR(150),
	email VARCHAR(150),
	birth_date VARCHAR(100),
	country VARCHAR(150),
	city VARCHAR(150),
	postal_code VARCHAR(100),
	address VARCHAR(255));
    
	CREATE TABLE IF NOT exists credit_cards (
	id VARCHAR(15) PRIMARY KEY,
	user_id INT,
	iban VARCHAR(80),
    pan VARCHAR(80),
    pin CHAR(4),
    cvv CHAR(4),
    track1 VARCHAR(70),
    track2 VARCHAR(70),
    expiring_date VARCHAR(80),
    FOREIGN KEY (user_id) REFERENCES users_gral(id)
    );
    
	CREATE TABLE IF NOT EXISTS products (
	id VARCHAR(50) PRIMARY KEY,
	product_name VARCHAR(50),
	price DECIMAL(8,2),
	colour CHAR(7),
	weight SMALLINT,
	warehouse_id VARCHAR(10));
    
      CREATE TABLE IF NOT EXISTS companies (
	company_id VARCHAR(15) PRIMARY KEY,
	company_name VARCHAR(255),
	phone VARCHAR(15),
	email VARCHAR(100),
	country VARCHAR(100),
	website VARCHAR(255)
    );

	CREATE TABLE IF NOT EXISTS transacciones (
	id VARCHAR(255) PRIMARY KEY,
	card_id VARCHAR(15) REFERENCES credit_cards(id),
	business_id VARCHAR(15) REFERENCES companies(company_id), 
	timestamp TIMESTAMP,
    amount DECIMAL(10, 2),
    declined BOOLEAN,
    product_ids VARCHAR(50),
	user_id INT REFERENCES users_gral(id),
	lat FLOAT,
	longitude FLOAT
    );
  
###--- agregar clave foranea, me olvide de agregrarlas cuando creer la tabla transacciones

ALTER TABLE transacciones
ADD CONSTRAINT fk_card_id
FOREIGN KEY (card_id) REFERENCES credit_cards(id),
ADD CONSTRAINT fk_business_id
FOREIGN KEY (business_id) REFERENCES companies(company_id);  

ALTER TABLE transacciones
ADD CONSTRAINT fk_user_id
FOREIGN KEY (user_id) REFERENCES users_gral(id);  
  
SHOW VARIABLES LIKE 'secure_file_priv';  ### --- para poder ver la carpeta donde instalar los archivos.

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_ca.csv'
INTO TABLE users_gral
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_uk.csv'
INTO TABLE users_gral
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_usa.csv'
INTO TABLE users_gral
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

select *
from users_gral;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, product_name, @price, colour, weight, warehouse_id)
SET price = REPLACE(@price, '$', '');

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv'
INTO TABLE transacciones
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select *
from products;

SELECT distinct t.user_id, u.name, u.surname, count(user_id) AS nro_transacc
FROM transacciones t
JOIN users_gral as u
ON t.user_id =u.id
WHERE t.user_id IN (
    SELECT t1.user_id
    FROM transacciones AS t1
    GROUP BY t1.user_id
    HAVING COUNT(user_id) >= 30
)
group by t.user_id;

SELECT c.id, c.iban, AVG(t.amount)
FROM transacciones AS t
JOIN credit_cards AS c
ON t.card_id = c.id
WHERE t.business_id = (
				SELECT c1.company_id
                FROM companies as c1
                WHERE c1.company_name = "Donec Ltd")
group by c.id, c.iban;

CREATE TABLE transaccionesv2 AS SELECT * FROM transacciones;

ALTER TABLE transaccionesv2
ADD PRIMARY KEY (id),
ADD CONSTRAINT fk_card_id_v2
FOREIGN KEY (card_id) REFERENCES credit_cards(id),
ADD CONSTRAINT fk_business_id_v2
FOREIGN KEY (business_id) REFERENCES companies(company_id),
ADD CONSTRAINT fk_user_id_v2
FOREIGN KEY (user_id) REFERENCES users_gral(id);


WITH clasificacion AS(
SELECT card_id,
    SUM(declined) OVER(PARTITION BY card_id ORDER BY timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Acum
FROM transaccionesv2)
SELECT card_id, count(DISTINCT card_id) as Recuento
FROM clasificacion
WHERE card_id NOT IN (
				SELECT card_id
                FROM clasificacion
                GROUP BY card_id
                HAVING MAX(Acum) >= 3)
group by card_id ;

### agregué nuevos registros para poner a prueba la consulta cuando el acumuluado de decline es mayor o igual a 3

INSERT INTO transaccionesv2 
(id, card_id, business_id, timestamp, amount, declined, product_ids, user_id, lat, longitude) 
VALUES 
('69D90229-AD26-43C3-5AAF-8D332D3B3E63', 'CcU-2959', 'b-2362', '2022-03-17 14:01:00', 100, 1, '67, 29', 92, 40753650688, 1297231412224),
('69D90229-AD26-43C3-5AAF-8D332D3B3E64', 'CcU-2959', 'b-2362', '2022-03-18 14:01:00', 100, 1, '67, 29', 92, 40753650688, 1297231412224),
('69D90229-AD26-43C3-5AAF-8D332D3B3E65', 'CcU-2959', 'b-2362', '2022-03-19 14:01:00', 100, 1, '67, 29', 92, 40753650688, 1297231412224);





