-- Q1) Who is the senior most employee based on job title?
SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;



-- Q2) Which countries has the most invoices?
SELECT billing_country, COUNT(*) AS Total_invoices FROM invoice
GROUP BY billing_country
ORDER BY Total_invoices DESC;



-- Q3) What are the top 3 values of total invoices
SELECT * FROM invoice
ORDER BY total DESC
LIMIT 3;



/* Q4) Which city has the best customers? We would like to throw a promotional music festival in the city we made the 
most money. Write a query that returns one city that has the highest sum of invoice totals. Return both the city 
name and sum of all invoice totals.*/
SELECT billing_city, SUM(total) AS invoice_total FROM invoice
GROUP BY billing_city
ORDER BY invoice_total DESC
LIMIT 1;



/* Q5) Who is the best customer? The customer that has spent the most money will be declared as best customer. Write a
query that returns the person who has spent the most money.*/
SELECT customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) AS invoice_total
FROM customer
JOIN invoice 
ON customer.customer_id=invoice.customer_id 
GROUP BY customer.customer_id
ORDER BY invoice_total DESC
LIMIT 1;



/* Q6) Write query to return the email, first name, last name and genre of all Rock music listeners. Return your list
ordered alphabetically by email starting with 'A'. */
SELECT DISTINCT email, first_name, last_name FROM customer
JOIN invoice ON customer.customer_id=invoice.customer_id
JOIN invoice_line ON invoice.invoice_id=invoice_line.invoice_id
JOIN track ON invoice_line.track_id=track.track_id
JOIN genre ON track.genre_id=genre.genre_id WHERE genre.name LIKE 'Rock'
ORDER BY email;

-- OR CAN BE ALSO SOLVED AS BELOW

SELECT DISTINCT email, first_name, last_name FROM customer
JOIN invoice ON customer.customer_id=invoice.customer_id
JOIN invoice_line ON invoice.invoice_id=invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id=genre.genre_id
	WHERE genre.name LIKE 'Rock')
ORDER BY email;



/* Q6) Let's invite the artists who have written the most rock music in our dataset. Write a query that returns 
the artist name and the total track count of the total 10 rock bands. */
SELECT artist.name, COUNT(artist.artist_id) AS total_artist_songs FROM artist
JOIN album ON album.artist_id=artist.artist_id
JOIN track ON album.album_id=track.album_id
JOIN genre ON track.genre_id=genre.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id 
ORDER BY total_artist_songs DESC
LIMIT 10;



/* Q7) Return all the track names that have a song length longer than the average song length. Return the name and 
milliseconds for each track. Order by the song length with the longest songs listed first. */
SELECT name, milliseconds FROM track
WHERE milliseconds>(SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds DESC;



/* Q8) Find how much amount spent by each customer on best selling artist? Write a query to return customer 
name, artist name, and total spent. */

WITH best_selling_artist AS(
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, 
	SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales FROM invoice_line
	JOIN track ON track.track_id=invoice_line.track_id
	JOIN album ON album.album_id=track.album_id
	JOIN artist ON artist.artist_id=album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity)
AS amount_spent FROM invoice i
JOIN customer c ON c.customer_id=i.customer_id
JOIN invoice_line il ON il.invoice_id=i.invoice_id
JOIN track t ON t.track_id=il.track_id
JOIN album al ON al.album_id=t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id=al.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;



/* Q9) We want to find out the most popular music genre for each country. We determine the most popular genre 
as the genre of the highest amount of purchases. Write a query that returns each country along with the top genre.
For countries where the maximum number of purchases is shared return all genres. */
WITH popular_genre AS(
	SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id,
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity)DESC) AS RowNo
	FROM invoice_line
	JOIN invoice ON invoice.invoice_id=invoice_line.invoice_id
	JOIN customer ON customer.customer_id=invoice.customer_id
	JOIN track ON track.track_id=invoice_line.track_id
	JOIN genre ON genre.genre_id=track.genre_id
	GROUP BY 2, 3, 4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo<=1;

-- OR Can also be solved using below

WITH RECURSIVE
	sales_per_country AS(
	SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
	FROM invoice_line
	JOIN invoice ON invoice.invoice_id=invoice_line.invoice_id
	JOIN customer ON customer.customer_id=invoice.customer_id
	JOIN track ON track.track_id=invoice_line.track_id
	JOIN genre ON genre.genre_id=track.genre_id
	GROUP BY 2, 3, 4
	ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
	FROM sales_per_country
	GROUP BY 2
	ORDER BY 2)
	
SELECT sales_per_country.*
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country=max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre=max_genre_per_country.max_genre_number;



/* Write a query that determines the customer that has spent the most on music for 
each country. Write a query that returns the country along with the top customer and 
how much they spent. For countries where the top amount spent is shared provide all 
customers who spent this amount. */
WITH RECURSIVE
	customer_with_country AS(
		SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) 
		AS total_spending FROM invoice
		JOIN customer ON customer.customer_id=invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),
	country_max_spending AS(
		SELECT billing_country, MAX(total_spending) AS max_spending
		FROM customer_with_country
		GROUP BY billing_country)
SELECT cc.billing_country, cc.total_Spending, cc.first_name, cc.last_name
FROM customer_with_country cc
JOIN country_max_spending ms
ON cc.billing_country=ms.billing_country
WHERE cc.total_spending=ms.max_spending
ORDER BY 1;

-- OR also can be solved in below method

WITH customer_with_country AS(
	SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending,
	ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo
	FROM invoice
	JOIN customer ON customer.customer_id=invoice.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 4 ASC, 5 DESC)
SELECT * FROM customer_with_country WHERE RowNo<=1;
