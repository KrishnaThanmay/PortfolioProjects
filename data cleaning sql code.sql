SELECT  
    *
FROM portfolioprojects.dbo.NashvilleHousing


--- standardizing SaleDate format which is in date time data type.
--- so for our better understanding, convenience and neatness we are converting the data type of the column to date to make it concise.
SELECT SaleDate, CONVERT(date, SaleDate)
FROM portfolioprojects.dbo.NashvilleHousing


--- adding new column saleDateConverted to standardize saledate datetime column to SaleDateconverted date column;
ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;


UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)

SELECT SaleDateConverted, SaleDate
FROM portfolioprojects.dbo.NashvilleHousing;
 
 
 ---populating null  values in property address column
SELECT *
FROM portfolioprojects.dbo.NashvilleHousing
---WHERE ParcelID='026 01 0 069.00'
---WHERE propertyaddress is NULL;
---Here we have figured out that parcel id and propertyaddresss columns are linked in a way that we can use parcel ID to fill out property address null values


SELECT 
    a.UniqueID, a.ParcelID, a.PropertyAddress, b.UniqueID, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM 
    portfolioprojects.dbo.NashvilleHousing a
JOIN 
    portfolioprojects.dbo.NashvilleHousing b 
ON 
    a.ParcelID = b.ParcelID 
AND a.UniqueID <> b.UniqueID 
WHERE a.PropertyAddress is null ;

UPDATE a
set propertyaddress =ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM
     portfolioprojects.dbo.NashvilleHousing a
JOIN 
    portfolioprojects.dbo.NashvilleHousing b 
ON 
    a.ParcelID = b.ParcelID 
AND a.UniqueID <> b.UniqueID 
WHERE a.PropertyAddress is null ;


--- property address has lot on plate  
---so i decided to break down for easier understanding
select propertyaddress
from portfolioprojects..NashvilleHousing

SELECT
    SUBSTRING(propertyaddress, 1, CHARINDEX(',', propertyaddress)-1) as address,
    SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as cityaddress
from portfolioprojects..NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD propertyAddresssplit NVARCHAR(255);

UPDATE NashvilleHousing
SET propertyAddresssplit = SUBSTRING(propertyaddress, 1, CHARINDEX(',', propertyaddress)-1);

ALTER TABLE NashvilleHousing
ADD propertycitysplit NVARCHAR(255);

UPDATE NashvilleHousing
SET propertycitysplit = SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));


---Now take a look at owner address
--- we see this column little hard as all the address, city and state are included in it 
--- we are gonna split these to amke them easy for us to read
---Here i am gonna use different technoque top split this time.
--- we are gonna use parsename function to split owneraddress column
--- but parsename only works when there are fullstops not when there are commas
---here in this owneraddress column we ahve comma as delimiter 
---easy way to do is we need to change commas in this column to periods.
---we are using parsename cause it is easy where using substring process seams lenghty and time taking process.
--- pase name does things from backwards when you type 1 it gives the value seperated from last period
SELECT  
    PARSENAME(REPLACE(OwnerAddress, ',', '.'),3),
    PARSENAME(REPLACE(OwnerAddress, ',', '.'),2),
    PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)
FROM portfolioprojects..NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD ownersplitaddress NVARCHAR(255);

UPDATE NashvilleHousing
SET ownersplitaddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3);

ALTER TABLE NashvilleHousing
ADD ownersplitcity NVARCHAR(255);

UPDATE NashvilleHousing
SET ownersplitcity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2);

ALTER TABLE NashvilleHousing
ADD ownersplitstate NVARCHAR(255);

UPDATE NashvilleHousing
SET ownersplitstate = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1);
SELECT * from portfolioprojects..NashvilleHousing

 --- lets take a look at solid as vacant 
SELECT
    distinct(SoldAsVacant), count(SoldAsVacant) as count
FROM 
    portfolioprojects..NashvilleHousing
GROUP BY
    SoldAsVacant
ORDER BY
    count
---I decided to change them into same format
---as we can see we need to format Y and N to yes or no as they are less in number
SELECT
    soldasvacant, 
CASE WHEN soldasvacant= 'Y' THEN 'Yes'
    WHEN soldasvacant ='N' THEN 'No'
    ELSE SoldAsVacant
    END
From portfolioprojects..NashvilleHousing


--- updating the table column soldasvacnt values of Y and N to Yes and No

UPDATE NashvilleHousing
SET SoldAsVacant =CASE WHEN soldasvacant= 'Y' THEN 'Yes'
    WHEN soldasvacant ='N' THEN 'No'
    ELSE SoldAsVacant
    END
SELECT distinct(SoldAsVacant)
FROM portfolioprojects..NashvilleHousing


---Removing duplicates that are present in our dataset
with RowNumCTE as(SELECT *,  
    ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) row_num
FROM portfolioprojects..NashvilleHousing
)
select * from RowNumCTE
WHERE row_num > 1
---order by propertyaddress
---ORDER BY ParcelID
---now we can see there are no duplicate values after we have deleted the repeated rows

---DELETING unused columns
---we have split columns from combined single column so we are gonna remove those unwanted columns
SELECT * FROM portfolioprojects..NashvilleHousing;
ALTER TABLE portfolioprojects..NashvilleHousing
DROP COLUMN owneraddress, saledate, propertyaddress
ALTER TABLE portfolioprojects..NashvilleHousing
DROP COLUMN TaxDistrict