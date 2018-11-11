[cmdletbinding()]
param(
    [Parameter(mandatory=$true)]
    [string]$srvname,
    [string]$letter="E:\"
    )
$deleteswitch1=$false
$deleteswitch2=$false
$DBName1="HumanResources"
$DBName2="InternetSales"
$filegroup="SalesData"
$pass=Read-Host -Prompt "Your DB Password" -AsSecureString #Решить проблему с конкатенацией!
$cred=Get-Credential -Message "SQL Credentials"
Get-SqlDatabase -ServerInstance $srvname -Credential $cred | #Human Resources Check
    foreach{
        if ($_.name -eq $DBName1) {
            write-host "DB with the same name($DBName) has been detected...";
            $deleteswitch1=$true
        }
    }
if ($deleteswitch1 -eq $true){
    Write-Host "Deleting $DBName1...";
    sqlcmd -S $srvname -U sa -Q "DROP DATABASE $DBName1" -PPa$$w0rd
    Write-Host "Successful Delete"}

Get-SqlDatabase -ServerInstance $srvname -Credential $cred | #InternetSales check
    foreach{
        if ($_.name -eq $DBName2) {
            write-host "DB with the same name($DBName2) has been detected...";
            $deleteswitch2=$true
        }
    }
if ($deleteswitch2 -eq $true){
    Write-Host "Deleting $DBName2...";
    sqlcmd -S $srvname -U sa -Q "DROP DATABASE $DBName2" -PPa$$w0rd
    Write-Host "Successful Delete"}

Write-Host "Creating $DBName1" #Human Resources
sqlcmd -S $srvname -U sa -Q "USE master ;  
GO  
CREATE DATABASE $DBName1
ON   
( NAME = $DBName1,  
    FILENAME = '$letter\Data\$DBName1.mdf',  
    SIZE = 50MB,  
    MAXSIZE = Unlimited,  
    FILEGROWTH = 5MB )  
LOG ON  
( NAME = ${DBName1}_log,  
    FILENAME = '$letter\Logs\${DBName1}_log.ldf',  
    SIZE = 5MB,  
    MAXSIZE = Unlimited,  
    FILEGROWTH = 1MB ) ;  
GO  " -PPa$$w0rd
Write-Host {"DB $DBName has been sucessfully created"}
Write-Host "Creating $DBName2" #InternetSales
sqlcmd -S $srvname -U sa -Q "USE master ;  
GO
CREATE DATABASE $DBName2  

ON PRIMARY 
( NAME = $DBName2,  
    FILENAME = '$letter\Data\$DBName2.mdf',  
    SIZE = 5MB,  
    MAXSIZE = Unlimited,  
    FILEGROWTH = 1MB 
)  
LOG ON  
( NAME = ${DBName2}_log,  
    FILENAME = '$letter\Logs\${DBName2}_log.ldf',  
    SIZE = 2MB,  
    MAXSIZE = Unlimited,  
    FILEGROWTH = 10 
) ;  
GO" -PPa$$w0rd
Write-Host {"DB $DBName2 has been sucessfully created"}
sqlcmd -S $srvname -U sa -Q "
ALTER DATABASE $DBName2
ADD FILEGROUP $filegroup;
" -PPa$$w0rd
sqlcmd -S $srvname -U sa -Q "
ALTER DATABASE $DBName2
ADD FILE 
(
    NAME = ${DBName2}_data1,
    FILENAME = '$letter\Data\${DBName2}_data1.ndf',
    SIZE = 100MB,
    MAXSIZE = Unlimited,
    FILEGROWTH = 10MB
),
(
    NAME = ${DBName2}_data2,
    FILENAME = '$letter\AdditionalData\${DBName2}_data2.ndf',
    SIZE = 100MB,
    MAXSIZE = Unlimited,
    FILEGROWTH = 10MB
)
TO FILEGROUP $filegroup; " -PPa$$w0rd
sqlcmd -S $srvname -U sa -Q "
ALTER DATABASE $DBName2
MODIFY

FILEGROUP $filegroup DEFAULT;
GO" -PPa$$w0rd
Write-Host {"DB $DBName2 filegroup $filegroup has been sucessfully created"}
