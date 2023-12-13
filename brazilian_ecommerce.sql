--Sipariş Analizi
--1.Aylık olarak order dağılımını inceleyiniz. Tarih verisi için order_approved_at kullanılmalıdır.)
Select * From orders

SELECT  date_trunc('month', order_approved_at)::date
AS order_approved_month, COUNT(order_id) AS order_count
FROM orders
WHERE order_approved_at IS NOT NULL
GROUP BY order_approved_month
ORDER BY order_approved_month ASC



--Aylık olarak order status kırılımında order sayılarını inceleyiniz. 
--Sorgu sonucunda çıkan outputu excel ile görselleştiriniz. 
--Dramatik bir düşüşün ya da yükselişin olduğu aylar var mı? Veriyi inceleyerek yorumlayınız.

SELECT date_trunc('month',order_approved_at)::date AS order_approved_month,
order_status, COUNT(order_id) AS order_count
FROM orders
WHERE order_approved_at IS NOT NULL
GROUP BY 1,2
ORDER BY 1,2 DESC


--Ürün kategorisi kırılımında sipariş sayılarını inceleyiniz. Özel günlerde öne çıkan kategoriler nelerdir?
--Yılbaşı 
SELECT o.order_approved_at::date, p.product_category_name,eng_product_name.product_category_name_english,count(o.order_id) AS order_count 
FROM products AS p
LEFT JOIN product_category_name_translation AS eng_product_name
ON p.product_category_name = eng_product_name.product_category_name
LEFT JOIN order_items AS ot
ON p.product_id =ot.product_id
LEFT JOIN orders AS o
ON ot.order_id = o.order_id
WHERE 
o.order_approved_at IS NOT NULL
AND p.product_category_name IS NOT NULL
AND EXTRACT(month from o.order_approved_at ) = 12
AND EXTRACT(day from o.order_approved_at ) BETWEEN 25 AND 31
GROUP BY 1,2,3
ORDER BY order_count DESC
LIMIT 10

--Sevgililer Günü

SELECT o.order_approved_at::date, p.product_category_name,eng_product_name.product_category_name_english,count(o.order_id) AS order_count 
FROM products AS p
LEFT JOIN product_category_name_translation AS eng_product_name
ON p.product_category_name = eng_product_name.product_category_name
LEFT JOIN order_items AS ot
ON p.product_id =ot.product_id
LEFT JOIN orders AS o
ON ot.order_id = o.order_id
WHERE 
o.order_approved_at IS NOT NULL
AND p.product_category_name IS NOT NULL
AND EXTRACT(month from o.order_approved_at ) = 2
AND EXTRACT(day from o.order_approved_at ) BETWEEN 7 AND 14
GROUP BY 1,2,3
ORDER BY order_count DESC
LIMIT 10

--Black Friday

--Black friday döneminde zirve yapan kategoriler:


SELECT o.order_approved_at::date, p.product_category_name,eng_product_name.product_category_name_english,count(o.order_id) AS order_count 
FROM products AS p
LEFT JOIN product_category_name_translation AS eng_product_name
ON p.product_category_name = eng_product_name.product_category_name
LEFT JOIN order_items AS ot
ON p.product_id =ot.product_id
LEFT JOIN orders AS o
ON ot.order_id = o.order_id
WHERE 
o.order_approved_at IS NOT NULL
AND p.product_category_name IS NOT NULL
AND EXTRACT(month from o.order_approved_at ) = 11
AND EXTRACT(day from o.order_approved_at ) BETWEEN 25 AND 27
GROUP BY 1,2,3
ORDER BY order_count DESC
LIMIT 10

--Haftanın günleri ve ay günleri bazında order sayılarını inceleyiniz. 
--Yazdığınız sorgunun outputu ile excel’de bir görsel oluşturup yorumlayınız.

--haftanın günleri
SELECT
CASE
WHEN EXTRACT(DOW FROM order_approved_at) = 0 THEN 'Pazar'
WHEN EXTRACT(DOW FROM order_approved_at) = 1 THEN 'Pazartesi'
WHEN EXTRACT(DOW FROM order_approved_at) = 2 THEN 'Salı'
WHEN EXTRACT(DOW FROM order_approved_at) = 3 THEN 'Çarşamba'
WHEN EXTRACT(DOW FROM order_approved_at) = 4 THEN 'Perşembe'
WHEN EXTRACT(DOW FROM order_approved_at) = 5 THEN 'Cuma'
WHEN EXTRACT(DOW FROM order_approved_at) = 6 THEN 'Cumartesi'
END AS day_of_week,
COUNT(order_id) AS order_count
FROM orders
WHERE order_approved_at IS NOT NULL
GROUP BY 1
ORDER BY 1 DESC

--ayın günleri

SELECT
    EXTRACT(DAY FROM order_approved_at) AS day_of_month,
    COUNT(order_id) AS order_count
FROM orders
WHERE order_approved_at IS NOT NULL
GROUP BY 1
ORDER BY 1


--Müşteri Analizi
--Hangi şehirlerdeki müşteriler daha çok alışveriş yapıyor? 
--Müşterinin şehrini en çok sipariş verdiği şehir olarak belirleyip analizi ona göre yapınız.

--en çok sipariş verilen şehir sıralaması		

WITH CustomerOrderAmounts AS (
SELECT c.customer_city,
COUNT(o.order_id) AS order_amount
FROM
customers AS c
LEFT JOIN
orders AS o ON c.customer_id = o.customer_id
GROUP BY c.customer_city)
SELECT customer_city,
SUM(order_amount) AS total_order_amount
FROM CustomerOrderAmounts
GROUP BY customer_city
ORDER By total_order_amount DESC

--müşterilerin Şehri
		
WITH CustomerOrderAmounts AS (
SELECT
c.customer_unique_id,
c.customer_city,
COUNT(o.order_id) AS order_amount
FROM customers c
LEFT JOIN
orders AS o ON c.customer_id = o.customer_id
	GROUP BY c.customer_unique_id, c.customer_city
),
RankedCities AS (
SELECT
coa.customer_unique_id,
coa.customer_city,
RANK() OVER (PARTITION BY coa.customer_unique_id ORDER BY coa.order_amount DESC) AS city_rank
FROM CustomerOrderAmounts AS coa
)
SELECT
rc.customer_unique_id,
rc.customer_city,
CASE WHEN rc.city_rank = 1 THEN 'En Çok Sipariş Verilen Şehir'
ELSE 'Diğer'
END AS city_status
FROM
RankedCities AS rc

--Satıcı Analizi

--Siparişleri en hızlı şekilde müşterilere ulaştıran satıcılar kimlerdir? 
--Top 5 getiriniz. 

WITH SellerOrderDelivery AS (
SELECT
oi.seller_id,
COUNT(DISTINCT o.order_id) AS order_count,
ROUND(AVG(EXTRACT(EPOCH FROM o.order_delivered_customer_date - o.order_purchase_date)::numeric) / 3600, 2) AS avg_delivery_hours
FROM order_items oi
LEFT JOIN orders AS o 
ON oi.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY oi.seller_id
)

SELECT
s.seller_id,
sod.order_count,
sod.avg_delivery_hours::numeric AS rounded_avg_delivery_hours
FROM SellerOrderDelivery sod
LEFT JOIN sellers AS s 
ON sod.seller_id = s.seller_id
ORDER BY 3 ASC
limit 5

--Bu satıcıların order sayıları ile ürünlerindeki yorumlar ve puanlamaları inceleyiniz ve yorumlayınız. 

WITH seller_rates AS (
SELECT
s.seller_id,
COUNT(DISTINCT oi.order_id) AS order_count,
COUNT(DISTINCT reviews_order.review_comment_message) AS order_comment,
ROUND(AVG(reviews_order.review_score), 2) AS avg_rating
FROM order_reviews AS reviews_order
LEFT JOIN order_items AS oi ON oi.order_id = reviews_order.order_id
LEFT JOIN sellers AS s ON s.seller_id = oi.seller_id
WHERE reviews_order.review_score IS NOT NULL
GROUP BY s.seller_id
),
seller_rank AS (
SELECT
seller_id,
order_count,
order_comment,
avg_rating,
RANK() OVER (ORDER BY avg_rating DESC) AS avg_rating_rank,
RANK() OVER (ORDER BY order_count DESC) AS order_count_rank
FROM seller_rates
)
SELECT
seller_id,
order_count,
order_comment,
avg_rating,
avg_rating_rank,
order_count_rank
FROM seller_rank
WHERE seller_id IS NOT NULL
ORDER BY order_count_rank, avg_rating_rank ASC

---Hangi satıcılar daha fazla kategoriye ait ürün satışı yapmaktadır? 
---Fazla kategoriye sahip satıcıların order sayıları da fazla mı?
SELECT s.seller_id,
COUNT(DISTINCT p.product_category_name) AS category_count,
COUNT(DISTINCT oi.order_id) AS order_count
FROM sellers AS s
INNER JOIN order_items AS oi 
ON s.seller_id = oi.seller_id
INNER JOIN products AS p 
ON oi.product_id = p.product_id
WHERE p.product_category_name IS NOT NULL	
GROUP BY s.seller_id
ORDER BY category_count DESC

--Payment Analizi
--Ödeme yaparken taksit sayısı fazla olan kullanıcılar en çok hangi      bölgede yaşamaktadır? 
--Bu çıktıyı yorumlayınız.

SELECT
c.customer_city,
SUM(CASE WHEN p.payment_installments IS NOT NULL THEN 1 ELSE 0 END) AS total_installments
FROM customers AS c
LEFT JOIN orders AS o 
ON c.customer_id = o.customer_id
LEFT JOIN order_payments AS p ON o.order_id = p.order_id
GROUP BY c.customer_city
ORDER BY total_installments DESC

--Ödeme tipine göre başarılı order sayısı ve toplam başarılı ödeme tutarını hesaplayınız. En çok kullanılan ödeme tipinden en az olana göre sıralayınız.

WITH PaymentStatistics AS (
SELECT
p.payment_type,
COUNT(DISTINCT o.order_id) AS order_count,
SUM(CAST(p.payment_value AS NUMERIC)) AS total_payment_amount
FROM order_payments AS p
LEFT JOIN
orders AS o 
ON p.order_id = o.order_id
GROUP BY p.payment_type
)

SELECT
    payment_type,
    order_count,
    total_payment_amount
FROM  PaymentStatistics
ORDER BY  order_count DESC, total_payment_amount DESC

--Tek çekimde ve taksitle ödenen siparişlerin kategori bazlı analizini yapınız. 
--En çok hangi kategorilerde taksitle ödeme kullanılmaktadır?

WITH PaymentDetails AS (
    SELECT
        o.order_id,
        p.payment_type,
        p.payment_installments,
        op.product_id,
        pr.product_category_name  
    FROM
        orders AS o
    LEFT JOIN
        order_payments AS p ON o.order_id = p.order_id
    LEFT JOIN
        order_items AS op ON o.order_id = op.order_id
    LEFT JOIN
        products AS pr ON op.product_id = pr.product_id
)

SELECT
    product_category_name,
    payment_type,
    payment_installments,
    COUNT(DISTINCT order_id) AS order_count,
    CASE
        WHEN payment_installments = 1 THEN 'Tek Çekim'
        WHEN payment_installments > 1 THEN 'Taksitli'
    END AS payment_category
FROM
    PaymentDetails
WHERE
    payment_type IN ('credit_card', 'voucher', 'debit_card') 
    OR payment_installments > 1 
GROUP BY
    product_category_name, 
	payment_type,
    payment_installments
ORDER BY
    payment_installments DESC


