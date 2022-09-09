-- Add a user, specifying the name in AD. When a user is added, it gets login access.
CREATE USER logicproductcatalog FROM external provider
-- grant access to that user to execute stored proc
 grant execute on object::GetProducts to logicproductcatalog 
 
 CREATE USER apps_productsread FROM external provider
 grant execute on object::GetProducts to apps_productsread 
ALTER ROLE db_datareader remove MEMBER apps_productsread;