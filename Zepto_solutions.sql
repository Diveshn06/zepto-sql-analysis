-- 1. Count total number of products available in the dataset.
SELECT SUM(availableQuantity) AS Total_products_avialable
FROM zepto_v1;


-- 2. List all unique product categories.
SELECT DISTINCT(Category)
FROM zepto_v1;

-- 3. Find products that are currently out of stock.
SELECT * FROM zepto_v1
WHERE outOfStock = 'TRUE';

-- 4. Calculate the discount amount for each product.
SELECT Category, name, (mrp*discountPercent/100) AS Discount_Amount
FROM zepto_v1;

-- 5. Find top 10 products with the highest discount percentage.
SELECT Category, name, discountPercent AS Discount_Percenatge
FROM zepto_v1
ORDER BY discountPercent DESC
LIMIT 10;

-- 6. Verify whether the discount percentage matches the actual price difference.
SELECT Category, name, 
discountedSellingPrice, ROUND(mrp-(mrp*discountPercent/100),2) AS Discount_Price_Counted,
CASE
    WHEN ROUND(mrp-(mrp*discountPercent/100),2) = discountedSellingPrice
    THEN 'MATCHED'
    ELSE 'NOT_MATCHED'
END AS Discount_Validation    
FROM zepto_v1;

-- 7. Find total available stock by category.
SELECT Category, SUM(availableQuantity)AS TOTAL_STOCK FROM zepto_v1
GROUP BY Category;

-- 8. Identify products with low stock (less than 5 units).
SELECT * FROM zepto_v1
WHERE availableQuantity BETWEEN 1 AND 4;


-- 9. Calculate potential revenue for each product.
SELECT name, SUM((ROUND(mrp-(mrp*discountPercent/100),2)) * availableQuantity) AS Total_revenue
FROM zepto_v1
GROUP BY name;

-- 10. Find top 5 revenue-generating categories.
SELECT Category, SUM((ROUND(mrp-(mrp*discountPercent/100),2)) * availableQuantity) AS Total_revenue
FROM zepto_v1
GROUP BY Category
ORDER BY Total_revenue DESC
LIMIT 5;

-- 11. Calculate price per gram for each product.
SELECT name, (ROUND(mrp-(mrp*discountPercent/100),2)/weightInGms) AS price_per_gram
FROM zepto_v1
WHERE weightInGms > 0
ORDER BY price_per_gram;

-- 12. Find best value products based on lowest price per gram.
SELECT name, (mrp-(mrp*discountPercent/100))/weightInGms AS price_per_gram
FROM zepto_v1
WHERE weightInGms > 0
ORDER BY price_per_gram ASC
LIMIT 5;

-- 13. Rank products by discount within each category using window functions.
SELECT Category, name, discountPercent, DENSE_RANK() OVER(PARTITION BY category ORDER BY discountPercent DESC) AS Rank_no
FROM zepto_v1
WHERE discountPercent > 0;

-- 14. Find categories with average discount above 15%.
SELECT Category, AVG(discountPercent) AS Avg_discount 
FROM zepto_v1
GROUP BY Category
HAVING AVG(discountPercent) > 15;

-- 15. Identify products with high discount (>20%) and high revenue potential.
SELECT name, discountPercent, (discountedSellingPrice * availableQuantity) AS Total_revenue
FROM zepto_v1
WHERE discountPercent > 20 AND availableQuantity > 0 
ORDER BY Total_revenue DESC
LIMIT 5;

-- 16. Find products where discount percentage does not match price difference.
SELECT * FROM(SELECT name, discountPercent, ROUND((mrp-discountedSellingPrice),2) AS Pice_diff_original, ROUND((mrp*discountPercent/100),2) AS Calculated_discount_Price,
CASE
	WHEN ROUND((mrp-discountedSellingPrice),2) = ROUND((mrp*discountPercent/100),2)
    THEN 'MATCHED'
    ELSE 'NOT_MATCHED'
END AS Validation    
FROM zepto_v1) AS x
WHERE x.Validation = 'NOT_MATCHED';

------- -- With CTE -------


WITH discount_validation AS ( SELECT name, discountPercent, ROUND((mrp-discountedSellingPrice),2) AS Pice_diff_original, ROUND((mrp*discountPercent/100),2) AS Calculated_discount_Price,
CASE
	WHEN ROUND((mrp-discountedSellingPrice),2) = ROUND((mrp*discountPercent/100),2)
    THEN 'MATCHED'
    ELSE 'NOT_MATCHED'
END AS validation
FROM zepto_v1)
SELECT * FROM discount_validation
WHERE validation = 'NOT_MATCHED';

-- 17. Identify high-priced products at risk of stockout.
SELECT name, discountedSellingPrice AS Price, availableQuantity AS AVL_Stock
FROM zepto_v1
WHERE discountedSellingPrice > 20000 AND availableQuantity BETWEEN 1 AND 3
ORDER BY discountedSellingPrice DESC;

-- 18. Find best value product per category using window functions.
WITH X AS(SELECT Category, name, discountedSellingPrice, ROUND((discountedSellingPrice*1.0/weightInGms),2) AS Price_per_gram,
DENSE_RANK() OVER(PARTITION BY Category ORDER BY ROUND((discountedSellingPrice*1.0/weightInGms),2)) AS Rnk
FROM zepto_v1
WHERE weightInGms > 0)
SELECT * FROM X
WHERE X.Rnk = 1;

-- 19. Detect products with unusually high discounts and low stock.
SELECT name, discountPercent, availableQuantity
FROM zepto_v1
WHERE discountPercent > 40 AND availableQuantity BETWEEN 1 AND 3
LIMIT 5;


-- 20. Identify top 3 products per category by revenue using window functions.
WITH X AS(SELECT Category, name, ROUND((discountedSellingPrice * availableQuantity),2) AS Total_revenue,
RANK()OVER(PARTITION BY Category ORDER BY ROUND((discountedSellingPrice * availableQuantity),2) DESC) AS Rnk
FROM zepto_v1
WHERE availableQuantity > 0)
SELECT * FROM X
WHERE Rnk BETWEEN 1 AND 3;
