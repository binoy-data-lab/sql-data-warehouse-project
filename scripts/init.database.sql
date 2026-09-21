/* 
--------------------------------------------------------------------
Create Database and Schemas
--------------------------------------------------------------------

Script Purpose: 
    This script creates a new database named 'DataWarehouse' after checking is it already exists.
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas within the database:
    Bronze, Silver and Gold. 

Warning: 
    Running this script will drop the entire 'DataWarehouse' database if it exists.
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script. 
*/

use master;

Create database DataWarehouse;

use DataWarehouse;

Create Schema Bronze;
Go
  
Create Schema Silver;
Go
  
Create Schema Gold;
Go
