create table commerce_data
( invoice_no varchar(30),
 stock_code varchar(30),
 description varchar(100),
 quantity integer,
 invoice_date varchar(100),
 unitprice varchar(50),
 customer_id integer,
 country varchar (50)
)
select * from commerce_data

select purchase_date from commerce_data 
order by purchase_date desc


ALTER TABLE commerce_data
ADD COLUMN purchase_date timestamp

UPDATE commerce_data
SET purchase_date = to_date(invoice_date, 'MM/DD/YYYY HH24:MI')

------- Recency (Yenilik) Hesaplama
SELECT
    customer_id,
    MAX(purchase_date):: date AS last_purchase_date,
    '2011-12-09'::date - MAX(purchase_date)::date   AS recency
INTO recency
FROM commerce_data
WHERE customer_id IS NOT NULL
GROUP BY customer_id



select * from recency


-- Frequency (Sıklık) Hesaplama

SELECT
    customer_id,
    COUNT(DISTINCT invoice_no) AS frequency
INTO frequency
FROM commerce_data
GROUP BY customer_id

select* from frequency

-- Monetary (Mali Değer) Hesaplama
SELECT
    customer_id,
    SUM(quantity * CAST(unitprice AS numeric)) AS monetary
INTO monetary
FROM commerce_data
GROUP BY customer_id

select * from monetary

---- RFM Skorları Oluşturma
SELECT
    r.customer_id,
    NTILE(5) OVER (ORDER BY r.recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY f.frequency DESC) AS f_score,
    NTILE(5) OVER (ORDER BY m.monetary DESC) AS m_score
INTO rfm_scores
FROM recency AS r
LEFT JOIN frequency AS f 
ON r.customer_id = f.customer_id
LEFT JOIN monetary AS m 
ON r.customer_id = m.customer_id

select* from rfm_scores

-- RFM Skorlarını Birleştirme ve Segmentasyon
SELECT
    rfm.customer_id,
    rfm.r_score,
    rfm.f_score,
    rfm.m_score,
    (rfm.r_score::text || rfm.f_score::text || rfm.m_score::text) AS rfm_score
FROM rfm_scores AS rfm
LEFT JOIN commerce_data AS cd 
ON rfm.customer_id = cd.customer_id
	
-----
SELECT
customer_id,
r_score,
f_score,
m_score,
CASE
WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'VIP Müşteri'
WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Sadık Müşteri'
WHEN r_score >= 2 AND f_score >= 2 AND m_score >= 2 THEN 'Potansiyel Müşteri'
ELSE 'Normal Müşteri'
END AS segment
FROM rfm_scores
ORDER BY segment DESC











