$Curdate = Get-Date
Write-host "Start: $CurDate"

$ServerList = "ServerList.txt"
$ServerListBad = "ServerListBad.csv"
$outputfile = "output.csv" 

Out-File -encoding ascii -FilePath $outputfile -Force
Out-File -encoding ascii -FilePath $serverlistBad -Force

$Curdate = Get-Date
Write-host "Getting shares and permission: $CurDate"

$ServersInScope = Get-Content -Path $ServerList
$ServerCount = $ServersInScope | measure
$ServerCount.count.ToString() + ' servers found in the list.'

foreach ($Server in $ServersInScope){"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> .\out.log;Write-Host "Current Server: $Server";$tempshares = "";$shares = "";$Server >> .\out.log;$tempshares = net view /all "\\$Server" 2>> .\out.log;if ($tempshares -ne $null){try{$tempshares = net view /all "\\$Server" 2>> .\out.log;if ($tempshares -ne $null){if ($tempshares.trim() -ne "There are no entries in the list."){$shares = $tempshares | select -Skip 1 |?{$_ -match 'Disk*'} | %{$_ -match '^(.+?)\s+Disk*' |out-null;$matches[1]};foreach ($sharename in $shares){Write-Host "Current Share: $sharename";$ShareACL = get-acl "\\$Server\$sharename" 2>> .\out.log;foreach($acc in $ShareACL.access){$acc | Select @{n='Server_Name';e={$server}},@{n='Share_Name';e={"\\$Server\$sharename"}},@{n='Share_Owner';e={$ShareACL.owner}},@{n='Identity';e={$acc.IdentityReference}},@{n='AccessControlType';e={$acc.AccessControlType}},@{n='FileSystemRights';e={$acc.FilesystemRights}},@{n='InheritanceFlags';e={$acc.InheritanceFlags}} |export-csv -Path $OutputFile -Append -Encoding ASCII -NoTypeInformation}}}}else{"$Server,No Shares" | Out-File -Encoding ascii -Append -FilePath $ServerListBad}}catch{$e = $_.Exception;$line = $_.InvocationInfo.ScriptLineNumber;$msg = $e.Message;Write-host "Caught exception: $e at $line";$ErrorActionPreference = "Continue"}}else{"$Server,Error - possibly timeout" | Out-File -Encoding ascii -Append -FilePath $ServerListBad}}