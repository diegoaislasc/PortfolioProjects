/*
 Cleaning data in SQL Queries
 */

SELECT saledate_formatted
FROM nashville_housing;

-- Standardize Date Format
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'nashville_housing' AND column_name = 'saledate'; -- returned text data type

ALTER TABLE nashville_housing ADD COLUMN saledate_formatted DATE;

UPDATE nashville_housing
SET saledate_formatted = TO_DATE(saledate, 'FMMonth DD, YYYY');

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'nashville_housing' AND column_name = 'saledate_formatted'; -- returned date data type

-- Populate Property Address data
SELECT *
FROM nashville_housing
WHERE propertyaddress IS NULL
ORDER BY parcelid;

SELECT a.parcelid, a.propertyaddress,
       b.parcelid AS matching_parcelid, b.propertyaddress AS matching_propertyaddress,
    COALESCE(a.propertyaddress, b.propertyaddress) AS propertyaddress_filled
FROM nashville_housing a
JOIN nashville_housing b
    ON a.parcelid = b.parcelid
    AND a.uniqueid <> b.uniqueid
WHERE a.propertyaddress IS NULL;

UPDATE nashville_housing
SET propertyaddress = COALESCE(a.propertyaddress, nashville_housing.propertyaddress)
FROM nashville_housing a
WHERE nashville_housing.parcelid = a.parcelid
    AND nashville_housing.uniqueid <> a.uniqueid
    AND a.propertyaddress IS NULL;

-- Breaking out Address into Individual Columns (Address, City, State)
SELECT propertyaddress
FROM nashville_housing
ORDER BY parcelid;

SELECT
    SUBSTRING(propertyaddress FROM 1 FOR POSITION(',' IN propertyaddress) - 1) AS address,
    SUBSTRING(propertyaddress FROM POSITION(',' IN propertyaddress) + 1) AS city
FROM nashville_housing;

ALTER TABLE nashville_housing
    ADD COLUMN property_split_address varchar(255);
UPDATE nashville_housing
SET property_split_address = SUBSTRING(propertyaddress FROM 1 FOR POSITION(',' IN propertyaddress) - 1);

ALTER TABLE nashville_housing
    ADD property_split_city varchar(255);
UPDATE nashville_housing
SET property_split_city = SUBSTRING(propertyaddress FROM POSITION(',' IN propertyaddress) + 1);

SELECT * FROM nashville_housing;

SELECT owneraddress FROM nashville_housing;

ALTER TABLE nashville_housing
    ADD owner_split_address varchar(255);
UPDATE nashville_housing
SET owner_split_address = SPLIT_PART(REPLACE(owneraddress, ',', '.'), '.', 3);


ALTER TABLE nashville_housing
    ADD owner_split_city varchar(255);
UPDATE nashville_housing
SET owner_split_city = SPLIT_PART(REPLACE(owneraddress, ',', '.'), '.', 2);


ALTER TABLE nashville_housing
    ADD owner_split_state varchar(255);
UPDATE nashville_housing
SET owner_split_state = SPLIT_PART(REPLACE(owneraddress, ',', '.'), '.', 1);

SELECT *
FROM nashville_housing;


-- Change Y and N to Yes and No in "Sold as Vacant" field
SELECT DISTINCT (soldasvacant), COUNT(soldasvacant)
FROM nashville_housing
GROUP BY soldasvacant
ORDER BY 2;

SELECT soldasvacant,
       CASE WHEN soldasvacant = 'Y' THEN 'Yes'
            WHEN soldasvacant = 'N' THEN 'No'
            ELSE soldasvacant
            END
FROM nashville_housing;

UPDATE nashville_housing
SET soldasvacant = CASE WHEN soldasvacant = 'Y' THEN 'Yes'
            WHEN soldasvacant = 'N' THEN 'No'
            ELSE soldasvacant
            END;

-- REMOVE DUPLICATES
DELETE FROM nashville_housing
WHERE uniqueid IN (
    SELECT uniqueid
    FROM (
        SELECT uniqueid,
               ROW_NUMBER() OVER(
                   PARTITION BY parcelid, propertyaddress, saleprice,
                                saledate, legalreference
                   ORDER BY uniqueid
               ) AS row_num
        FROM nashville_housing
    ) AS subquery
    WHERE row_num > 1
);

WITH RowNumCTE AS(
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY parcelid, propertyaddress, saleprice,
                            saledate, legalreference
               ORDER BY uniqueid
               )row_num
    FROM nashville_housing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1;


-- DELETE UNUSED COLUMNS
ALTER TABLE nashville_housing
DROP COLUMN owneraddress,
DROP COLUMN taxdistrict,
DROP COLUMN  propertyaddress;

ALTER TABLE nashville_housing
DROP COLUMN saledate;

SELECT * FROM nashville_housing;