[cmdletbinding()]
param(
    [Parameter(mandatory=$true)]
    [string]$srvname
    ) 
Start-Transcript -Path ./Log$(get-date -U %H:%M-%D).txt 
$cred=Get-Credential -Message "SQL Credentials"
$cred2=Get-Credential -Message "Win Credentials"
$sess=New-CimSession -ComputerName $srvname -Credential $cred2
$dbsize_start=Invoke-Sqlcmd -ServerInstance $srvname -Query "USE PCDRIVE;  
GO  
EXEC sp_spaceused N'dbo.PhysDisk';  
GO  "  -Credential $cred  -OutputAs DataTables
$pagenum_start= Invoke-Sqlcmd -ServerInstance $srvname -Query "select
object_name(object_id) as 'tablename',
count(*) as 'totalpages',
sum(Case when is_allocated=0 then 1 else 0 end) as 'unusedPages',
sum(Case when is_allocated=1 then 1 else 0 end) as 'usedPages'
from sys.dm_db_database_page_allocations(db_id(),null,null,null,'DETAILED')
where object_name(object_id) = 'PhysDisk'
group by
object_name(object_id)"  -Credential $cred  -OutputAs DataTables
$phys=Get-PhysicalDisk -CimSession $sess |
    select -Property FriendlyName,BusType,HealthStatus,Size,MediaType
sqlcmd -S $srvname -U sa -Q "USE master ;  
GO  
CREATE DATABASE PCDRIVE
ON   
( NAME = PCDRIVE,  
    FILENAME = 'E:\Data\PCDRIVE.mdf',  
    SIZE = 50MB,  
    MAXSIZE = Unlimited,  
    FILEGROWTH = 5MB )  
LOG ON  
( NAME = PCDRIVE_log,  
    FILENAME = 'E:\Logs\PCDRIVE_log.ldf',  
    SIZE = 5MB,  
    MAXSIZE = Unlimited,  
    FILEGROWTH = 1MB ) ;  
GO  " -PPa$$w0rd
sqlcmd -S $srvname -U sa  -Q " 
CREATE TABLE PCDRIVE.dbo.PhysDisk (
    FriendlyName varchar(255),
    BusType varchar(255),
    HealthStatus varchar(255),
    Size varchar(255),
    Mediatype varchar(255) 
);" -PPa$$w0rd
Write-Host "Getting a number of pages before adding data"
"A number of total/used pages " + $pagenum_start.totalpages +" | " + $pagenum_start.usedpages
"DB size " + $DBsize_start.data

foreach($physic in $phys)
    {$FriendlyName=$physic.Friendlyname
    $BusType=$physic.BusType
    $HealthStatus=$physic.HealthStatus
    $Size=$physic.Size
    $MediaType=$physic.Mediatype
$insertquery=" 
INSERT INTO [PCDRIVE].[dbo].[PhysDisk] 
           ([FriendlyName] 
           ,[BusType] 
           ,[HealthStatus]
           ,[Size]
           ,[MediaType]) 
     VALUES 
           ('$FriendlyName' 
           ,'$BusType' 
           ,'$HealthStatus'
           ,'$Size'
           ,'$MediaType') 
GO 
" 
sqlcmd -S $srvname -U sa -Q $insertquery -PPa$$w0rd}  

Write-Host "Getting a number of pages after adding data"
$dbsize=Invoke-Sqlcmd -ServerInstance $srvname -Query "USE PCDRIVE;  
GO  
EXEC sp_spaceused N'dbo.PhysDisk';  
GO  "  -Credential $cred  -OutputAs DataTables
$pagenum= Invoke-Sqlcmd -ServerInstance $srvname -Query "select
object_name(object_id) as 'tablename',
count(*) as 'totalpages',
sum(Case when is_allocated=0 then 1 else 0 end) as 'unusedPages',
sum(Case when is_allocated=1 then 1 else 0 end) as 'usedPages'
from sys.dm_db_database_page_allocations(db_id(),null,null,null,'DETAILED')
where object_name(object_id) = 'PhysDisk'
group by
object_name(object_id)"  -Credential $cred  -OutputAs DataTables
"A number of total/used pages " + $pagenum.totalpages +" | " + $pagenum.usedpages
"DB size " + $DBsize.data
 Stop-Transcript   
