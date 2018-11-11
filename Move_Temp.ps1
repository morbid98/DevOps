[cmdletbinding()]
param(
    [Parameter(mandatory=$true)]
    [string]$srvname,
    [Parameter(mandatory=$true)]
    [string]$MovePath,
    [string]$letter="E"
    )
$cred=Get-Credential -Message "SQL Credentials"
$cred2=Get-Credential -Message "Win Credentials"
$ErrorActionPreference = "Stop" 
if($connect_err){
    Write-Warning -message "Check your credentials or connection to the server"
}
Invoke-Sqlcmd -Credential $cred -ServerInstance $srvname -Query "
SELECT name as Name, physical_name AS OldLocation  
FROM sys.master_files  
WHERE database_id = DB_ID(N'tempdb');  
GO " -ErrorVariable connect_err |Format-Table
Invoke-Command -ComputerName $srvname `
-Credential $cred2 ` -ErrorVariable connect_err `
    -ScriptBlock {get-childitem $MovePath|
        foreach {
            if ($_.FullName -like "*temp*"){
                Write-Error -Message "TempDB files already exist,use another location or delete the files"  -ErrorAction Stop
                Exit-PSSession;
                }
            }
        }
                                                                        
Invoke-Sqlcmd -Credential $cred -ServerInstance $srvname -Query "
USE master;  
GO  
ALTER DATABASE tempdb   
MODIFY FILE (NAME = tempdev, FILENAME = '$MovePath\tempdb.mdf',size=10MB,filegrowth=5MB,maxsize='unlimited');  
GO  
ALTER DATABASE tempdb   
MODIFY FILE (NAME = templog, FILENAME = '$MovePath\templog.ldf',size=10MB,filegrowth=1MB,maxsize='unlimited');  
GO" -ErrorVariable connect_err
Write-Host "Operation Successful"
Invoke-Command -ComputerName $srvname -Credential $cred2 -ScriptBlock {Restart-Service -Name *mssql*}
Invoke-Sqlcmd -Credential $cred -ServerInstance $srvname -Query "
SELECT name as Name, physical_name AS CurrentLocation  
FROM sys.master_files  
WHERE database_id = DB_ID(N'tempdb');  
GO " -ErrorVariable connect_err |format-table
Get-WmiObject Win32_LogicalDisk -ComputerName $srvname -Credential $cred2 -Filter "DeviceID='${letter}:'" |
Select-Object @{name='FreeSpaceOnDisk(GB)';expression={$_.FreeSpace/1GB}}
