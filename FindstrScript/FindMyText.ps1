########################################
# FindMyText.ps1
#
# Given a text file with numerous Findstr searches, this script will run them
# in a multi-threaded fashion based on the number of concurrent
# threads specified.

########################################

# Verify User #



$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

#  $MyFindstrs is the file containing the Findstrs to be run.
$MyFindstrs = "C:\FindstrScript\FoldersToSearch.txt"

# $numConcurrent is the number of Findstr threads that should be run at once.
[int]$numConcurrent = 4

########################################  Main Code ########################
$pool = [RunspaceFactory]::CreateRunspacePool(1, $numConcurrent)
$pool.ApartmentState = "MTA"
$pool.Open()
$runspaces = $results = @()

#Scriptblock where the Findstr is executed
$scriptblock = {
    Param (
    [string]$Runstring
    )
    #Parse $Runstring to get Exe, arguments and stdout
    # $ParseRun = $runString.Substring(0,7)
    # $ParseArg = $Runstring.Substring(8).split(">")
    # $MyStdout = $ParseArg[2].substring(1)
    # Start-Process -Wait -FilePath $ParseRun -ArgumentList $ParseArg[0] -RedirectStandardOutput $MyStdout -RedirectStandardError "NUL"
    # return $error[0]
    # $Runstring
    
    # $ParseRun = $runString.Substring(0,7)
    $ParseArg = $Runstring.split(">")
    $MyStdout = $ParseArg[2].substring(1)
    Start-Process -Wait -FilePath powershell -ArgumentList $ParseArg[0] -RedirectStandardOutput $MyStdout -RedirectStandardError "NUL" -NoNewWindow
    return $error[0]
    $Runstring
}

#Get all the Findstr strings
$FindStrings = Get-Content $MyFindstrs 
$searchcount = $FindStrings | Measure-Object
#Add Findstrs to Runspace
$RunspaceCount = 0
foreach ($Findstring in $FindStrings) {
    $RunspaceCount = $RunspaceCount +1
    $runspace = [PowerShell]::Create()
    $null = $runspace.AddScript($scriptblock)
    $null = $runspace.AddArgument($Findstring)
    $runspace.RunspacePool = $pool
    $runspaces += [PSCustomObject]@{ Pipe = $runspace; Status = $runspace.BeginInvoke() }
}

# Wait to finish
while ($runspaces.Status) {
    $countdone = 0
    Start-Sleep -Seconds 2
    $completed = $runspaces | Where-Object {$_.Status.IsCompleted -eq $true}
    $m = $completed | Measure-Object
    $countdone = $countdone + $m.Count
    $percentdone = ($countdone / $searchcount.count).tostring("P")
    $countdone.tostring() + " folders finished searching out of " + $searchcount.count + " - " + $percentdone
    if ($countdone -eq $searchcount.Count){
        break
    }
}

# Clean up
foreach ($runspace in $runspaces) {
    # EndInvoke method retrieves the results of the asynchronous call
    $results += $runspace.Pipe.EndInvoke($runspace.Status)
    $runspace.Status = $null
    $runspace.Pipe.Dispose()
}
$pool.Close() 
$pool.Dispose()
[System.GC]::Collect()


$results = Get-ChildItem C:\FindstrScript\results\*
Write-Host "Cleaning up results..."
foreach ($result in $results.FullName) {
    (gc $result) | ? {$_.trim() -ne "" } | set-content $result
}

Get-Content C:\FindstrScript\results\* | Out-File -Append C:\FindstrScript\results\all.txt

$stopwatch.Stop()
$time = $stopwatch.Elapsed
"Time Taken: $time" | Out-File -Append C:\FindstrScript\results\_time_to_complete.txt