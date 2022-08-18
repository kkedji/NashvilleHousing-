/****** Script de la commande SelectTopNRows à partir de SSMS  ******/
SELECT TOP (1000) [UniqueID ]
      ,[ParcelID]
      ,[LandUse]
      ,[PropertyAddress]
      ,[SaleDate]
      ,[SalePrice]
      ,[LegalReference]
      ,[SoldAsVacant]
      ,[OwnerName]
      ,[OwnerAddress]
      ,[Acreage]
      ,[TaxDistrict]
      ,[LandValue]
      ,[BuildingValue]
      ,[TotalValue]
      ,[YearBuilt]
      ,[Bedrooms]
      ,[FullBath]
      ,[HalfBath]
  FROM [PortfolioProject].[dbo].[NashvilleHousing]

-- In this Project we will be running queries to  clean NashvilleHousing dataset going through all different
-- cleaning methods such as formating, removing duplicates, spliting columns, replacing and updating data and finally removing unused columns.

-- 1- First let's standardize the sales date format.

SELECT SaleDate,
       CONVERT(Date, SaleDate)
       FROM PortfolioProject..NashvilleHousing

UPDATE NashvilleHousing
       SET SaleDate = CONVERT(Date, SaleDate)

-- This can be done also by adding a new column to the dataset

ALTER TABLE NashvilleHousing
       ADD  SaleDateConverted Date;

UPDATE NashvilleHousing
       SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDate,
       SaleDateConverted
	   FROM PortfolioProject..NashvilleHousing


--2 - let's populate the Property Address data where we have NUll values based on the ParcelID
   -- Properties sharing the same ParcelID will have the same address.We will join the table with 
   -- itself on ParcelID by making sure the UniqueID identifying the house is different in a matching 
   -- row and one Property Address is NULL. The ISNULL function check if the first value is Null and update with the second value.

SELECT A.ParcelID,
       A.PropertyAddress,
	   B.ParcelID,
	   B.PropertyAddress,
	   ISNULL(A.PropertyAddress,B.PropertyAddress)
       FROM PortfolioProject..NashvilleHousing A
	   JOIN PortfolioProject..NashvilleHousing B
	   on A.ParcelID= B.ParcelID
	   AND A.[UniqueID ]<> B.[UniqueID ]
	   WHERE A.PropertyAddress IS NULL

UPDATE A
       SET PropertyAddress = ISNULL(A.PropertyAddress,B.PropertyAddress)
	   FROM PortfolioProject..NashvilleHousing A
	   JOIN PortfolioProject..NashvilleHousing B
	   on A.ParcelID= B.ParcelID
	   AND A.[UniqueID ]<> B.[UniqueID ]
	   WHERE A.PropertyAddress IS NULL


-- 3 Let's get the Address, the City and the State from the Proprerty Address by splitting the column by delimiter.
     -- Using the SUBSTRING function we splitted the PropertyAddress column into Address and City and the added two 
	 -- columns to the table populated with these two values


SELECT SUBSTRING (PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address,
       SUBSTRING (PropertyAddress, (CHARINDEX(',',PropertyAddress)+1),LEN(PropertyAddress)) AS Address
       FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
      ADD PropertySplitAddress NVARCHAR (255)

UPDATE NashvilleHousing
      SET PropertySplitAddress = SUBSTRING (PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE NashvilleHousing
      ADD PropertySplitCity NVARCHAR (255)

UPDATE NashvilleHousing
      SET PropertySplitCity = SUBSTRING (PropertyAddress, (CHARINDEX(',',PropertyAddress)+1),LEN(PropertyAddress))

--Checking if our newly columns created appears.

SELECT * 
       FROM PortfolioProject..NashvilleHousing

-- We can use PARSENAME and REPLACE function on the owner Address to perform the same task of splitting values in a column
-- PARSENAME function only looks for periods (.) that's why we new to replace the commas (,) in our Address with periods (.)
-- using the REPLACE function.It is also noticing that PARSENAME works backwards.We can then use the same process to add 
-- our splitted and newly created columns

SELECT 
       PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	   PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	   PARSENAME(REPLACE(OwnerAddress,',','.'),1)
       FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
      ADD OwnerSplitAddress NVARCHAR (255)

UPDATE NashvilleHousing
      SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE NashvilleHousing
      ADD OwnerSplitCity NVARCHAR (255)

UPDATE NashvilleHousing
      SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE NashvilleHousing
      ADD OwnerSplitState NVARCHAR (255)

UPDATE NashvilleHousing
      SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

-- Checking if our columns appears

SELECT * 
       FROM PortfolioProject..NashvilleHousing


-- 4- Updating inconsistent values : let's change Y and N in the SoldAsVacant column to  Yes or No
   -- using CASE WHEN function and the update our table

SELECT DISTINCT(SoldAsVacant),
       COUNT (SoldAsVacant)
	   FROM PortfolioProject..NashvilleHousing
	   GROUP BY SoldAsVacant
	   ORDER BY COUNT (SoldAsVacant)

SELECT SoldAsVacant,
       CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	        WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
			END
	        FROM PortfolioProject..NashvilleHousing

UPDATE NashvilleHousing
       SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	                           WHEN SoldAsVacant = 'N' THEN 'No'
			                   ELSE SoldAsVacant
			                   END


--5 Let's remove duplicates using CTE and WINDOWS functions
   -- The CTE function helps us identifies row that are duplicates 
   -- based on the fact that they are sharing the same values in the columns specified

WITH RowNumCTE AS (
SELECT *,
       ROW_NUMBER() 
	   OVER (  
	   PARTITION BY ParcelID,
	                PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
		ORDER BY UniqueID) ROW_NUM
		FROM PortfolioProject..NashvilleHousing
		)
DELETE
        FROM RowNumCTE
		WHERE ROW_NUM >1
		

-- Checking if we stil have duplicates rows.

WITH RowNumCTE AS (
SELECT *,
       ROW_NUMBER() 
	   OVER (  
	   PARTITION BY ParcelID,
	                PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
		ORDER BY UniqueID) ROW_NUM
		FROM PortfolioProject..NashvilleHousing
		)
SELECT *
        FROM RowNumCTE
		WHERE ROW_NUM >1
		ORDER BY PropertyAddress


-- 6- Deleting unused columns: we will get rid of columns that are nor useful for us.



ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict,PropertyAddress,Saledate

-- Checking the final state of our table

SELECT * 
       FROM PortfolioProject..NashvilleHousing

-- END