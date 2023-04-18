## Webiste Anaylsis

## 1.Finding most website page with highest sessions

SELECT
	pageview_url,
    count(website_pageview_id) as pagviewd
FROM
	website_pageviews
WHERE created_at < '2012-06-09'
group by pageview_url
order by count(website_pageview_id) DESC;

--------------------------------------------------------------------------

#### 2.Fidnig Top Entry Pages

SELECT 
	a.landing_page,
    count(w.website_session_id) as sessions
FROM
(
SELECT 
	website_session_id,
    min(website_pageview_id) as first_pageviewd,
    pageview_url as landing_page
FROM
	website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY website_session_id) as a

LEFT JOIN
		website_pageviews w on w.website_pageview_id = a.first_pageviewd
GROUP BY a.landing_page;

--------------------------------------------------------------------------------------------------------
####  3.Bounce rate analysis

CREATE temporary TABLE bounced_session
SELECT 
    a.landing_page,
    a.website_session_id,
	count(w.website_pageview_id) as bounced_sessions
FROM
(
SELECT 
	website_session_id,
   min(website_pageview_id) as first_pageviewd,
    pageview_url as landing_page
FROM
	website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY website_session_id) as a

LEFT JOIN
		website_pageviews w on w.website_session_id  = a.website_session_id
GROUP BY a.website_session_id
HAVING count( w.website_pageview_id ) = 1;


DROP TABLE IF EXISTS Not_bounced_sessions;
CREATE temporary TABLE Not_bounced_sessions
SELECT 
    a.landing_page,
    a.website_session_id,
	count(w.website_pageview_id) as bounced_sessions
FROM	
(
SELECT 
	website_session_id,
   min(website_pageview_id) as first_pageviewd,
    pageview_url as landing_page
FROM
	website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY website_session_id) as a

LEFT JOIN
		website_pageviews w on w.website_session_id  = a.website_session_id
GROUP BY a.website_session_id;

SELECT * FROM Not_bounced_sessions;

SELECT 
	count(distinct sessions) as total_sessions,
    count(distinct bounce_session) as total_bounce_session,
    count(distinct bounce_session) / count(distinct sessions) as bounce_rate
FROM
(
SELECT 
	w.landing_page,
	w.website_session_id as sessions,
	a.website_session_id as bounce_session
FROM
	(
		SELECT 
	website_session_id,
   min(website_pageview_id) as first_pageviewd,
    pageview_url as landing_page
FROM
	website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY website_session_id ) as w
LEFT JOIN
	bounced_session a on w.website_session_id = a.website_session_id) as b
GROUP BY b.landing_page;

-----------------------------------------------------------------------------------------------------------------------------------
### 4.AB test for landing page

SELECT
	min(created_at) as first_created_at,
    website_pageview_id
FROM
	website_pageviews
WHERE pageview_url = '/lander-1';

## Finding Intial pageview_id

SELECT 
	website_session_id,
    min(website_pageview_id) as landing_page_id,
    pageview_url
FROM
	website_pageviews 
WHERE created_at < '2012-07-28'
	AND website_pageview_id >= '23504'
GROUP BY website_session_id;

DROP TABLE IF exists bounce_session;
CREATE temporary TABLE bounce_session
SELECT 
	a.website_session_id,
    a.pageview_url,
    count(w.website_pageview_id) as bounced_session
FROM
	(
		SELECT 
	website_session_id,
    min(website_pageview_id) as landing_page_id,
    pageview_url
FROM
	website_pageviews 
WHERE created_at < '2012-07-28'
	AND website_pageview_id > '23504'
GROUP BY website_session_id) as a

LEFT JOIN
	website_pageviews w on a.website_session_id = w.website_session_id
WHERE created_at < '2012-07-28'
	AND website_pageview_id > '23504'
GROUP BY a.website_session_id, a.pageview_url
HAVING count(w.website_pageview_id) = 1;


SELECT
	pageview_url,
    count(distinct sessions) as Sessions,
    count(distinct bounced_session) as bounce_sessions,
    count(distinct bounced_session) / count(distinct sessions) as bounce_rate
FROM
(
SELECT 
	a.pageview_url,
    a.landing_page_id,
	a.website_session_id as sessions,
    w.website_session_id as bounced_session
FROM
(
    SELECT 
	website_session_id,
    min(website_pageview_id) as landing_page_id,
    pageview_url
FROM
	website_pageviews 
WHERE created_at < '2012-07-28'
	AND website_pageview_id >= '23504'
GROUP BY website_session_id) as a

LEFT JOIN
	bounce_session w on w.website_session_id =a.website_session_id) as b
GROUP BY 1;
----------------------------------------------------------------------------------------------------------------------
### 5.Analyzing convesrion Funnel
    
    SELECT 
		count(distinct website_session_id) as sessions,
        count(CASE WHEN products_page=1 THEN website_session_id ELSE NULL END) as product_page,
        count(CASE WHEN mrfuzzy_page=1 THEN website_session_id ELSE NULL END) as mrfuzzy_page,
        count(CASE WHEN cart_page=1 THEN website_session_id ELSE NULL END) as cart_page,
        count(CASE WHEN shipping_page=1 THEN website_session_id ELSE NULL END) as shipping_page,
        count(CASE WHEN billing_page=1 THEN website_session_id ELSE NULL END) as billing_page,
        count(CASE WHEN thankyou_page=1 THEN website_session_id ELSE NULL END) as thankyou_page
	FROM
    (
    SELECT 
		w.website_session_id,
        p.pageview_url,
        CASE WHEN p.pageview_url ='/products' THEN 1 ELSE 0 END as products_page,
		CASE WHEN p.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END as mrfuzzy_page,
		CASE WHEN p.pageview_url ='/cart' THEN 1 ELSE 0 END as cart_page,
		CASE WHEN p.pageview_url ='/shipping' THEN 1 ELSE 0 END as shipping_page,
		CASE WHEN p.pageview_url ='/billing' THEN 1 ELSE 0 END as billing_page,
		CASE WHEN p.pageview_url ='/thank-you-for-your-order' THEN 1 ELSE 0 END as thankyou_page
        
	FROM
		website_sessions w
	LEFT JOIN
		website_pageviews p on w.website_session_id = p.website_session_id
        
	WHERE w.utm_source = 'gsearch'
		AND w.created_at > '2012-08-05'
        AND w.created_at < '2012-09-05') as a;
        
	SELECT distinct pageview_url from website_pageviews
    WHERE created_at > '2012-08-05'
        AND created_at < '2012-09-05';
    
    
SELECT 
        count(CASE WHEN products_page=1 THEN website_session_id ELSE NULL END) / count(distinct website_session_id) as lander_click_rate,
        count(CASE WHEN mrfuzzy_page=1 THEN website_session_id ELSE NULL END) / count(CASE WHEN products_page=1 THEN website_session_id ELSE NULL END) as prodcut_page_click_rate,
        count(CASE WHEN cart_page=1 THEN website_session_id ELSE NULL END) / count(CASE WHEN mrfuzzy_page=1 THEN website_session_id ELSE NULL END) as mrfuzzy_page_clickrate,
        count(CASE WHEN shipping_page=1 THEN website_session_id ELSE NULL END) / count(CASE WHEN cart_page=1 THEN website_session_id ELSE NULL END) as cart_page_clickrate,
        count(CASE WHEN billing_page=1 THEN website_session_id ELSE NULL END) / count(CASE WHEN shipping_page=1 THEN website_session_id ELSE NULL END) as shipping_page_clickrate,
        count(CASE WHEN thankyou_page=1 THEN website_session_id ELSE NULL END) / count(CASE WHEN billing_page=1 THEN website_session_id ELSE NULL END) as blling_page_clickrate
	FROM
    (
    SELECT 
		w.website_session_id,
        p.pageview_url,
        CASE WHEN p.pageview_url ='/products' THEN 1 ELSE 0 END as products_page,
		CASE WHEN p.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END as mrfuzzy_page,
		CASE WHEN p.pageview_url ='/cart' THEN 1 ELSE 0 END as cart_page,
		CASE WHEN p.pageview_url ='/shipping' THEN 1 ELSE 0 END as shipping_page,
		CASE WHEN p.pageview_url ='/billing' THEN 1 ELSE 0 END as billing_page,
		CASE WHEN p.pageview_url ='/thank-you-for-your-order' THEN 1 ELSE 0 END as thankyou_page
        
	FROM
		website_sessions w
	LEFT JOIN
		website_pageviews p on w.website_session_id = p.website_session_id
        
	WHERE w.utm_source = 'gsearch'
		AND w.created_at > '2012-08-05'
        AND w.created_at < '2012-09-05') as a;
        
	
    --------------------------------------------------------------------------------------------------------------------------------
    ### 6.Order rate comparison on new billing page with old billing page
    SELECT
		created_at,
		min(website_pageview_id) as first_pageview_id
	FROM
		website_pageviews
	WHERE pageview_url = '/billing-2';
	
    SELECT 
		p.pageview_url as billig_version_seen,
       count(distinct p.website_session_id) as sessions,
       count(distinct o.order_id) as orders,
       count(distinct o.order_id) / count(distinct p.website_session_id) as billing_to_order_rate_conv
	FROM
		website_pageviews p
	LEFT JOIN
		orders o on p.website_session_id = o.website_session_id
	WHERE p.website_pageview_id >= 53550
		AND p.pageview_url IN ('/billing-2','/billing')
		AND p.created_at < '2012-11-10'
	GROUP BY 1;
    
