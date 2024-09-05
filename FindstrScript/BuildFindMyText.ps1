########################################
# BuildFindMyText.ps1
#
# Given a list of folders to search in a text file, this script will build a text file containing 
# Findstrs for each of the subfolders
#
########################################
#Variables to Edit

# $InputFile is a text file containing list of folders to investigate
$InputFile = "C:\FindstrScript\MyFolders.txt"

# $OutputFile is the text file that will contain the Findstr cmds to the folders from the $InputFile
$OutputFile = "C:\FindstrScript\FoldersToSearch.txt"

# $OutputLocation is the folder that will contain all the Findstr results
$OutputLocation = "C:\FindstrScript\results\"
If (!(test-path $OutputLocation)) {
    New-Item -ItemType Directory -Force -Path $OutputLocation
}

# $IgnoreFolders is a text file that contains any direct subfolders of the the folders specified in the $InputFile to ignore
$MyIgnoreFolders = "C:\FindstrScript\ignorefolders.txt"

# $Searchtermsis a text file that contains the search terms you are looking for
# ***WARNING***:  if the file contains regex searches, the first term must be a regex
$Searchterms = "C:\FindstrScript\findme.txt"

##################### - Code - ####################
#Blank out file
Out-File $OutputFile -Encoding ascii

# Get list of ignore folders into array
$IgnoreFolders = Get-Content $MyIgnoreFolders
$arrIgnore = New-Object System.Collections.ArrayList
foreach ($ignore in $IgnoreFolders) {
    #add \
    if ($ignore.Substring($ignore.ToString.Length, 1) -ne "\") {
        $ignore = $ignore + "\"
    }
    #add to array
    $arrIgnore.Add($ignore) > $null
}

#Open file with folder listing
$ListFolders = Get-Content $InputFile

#Open file with regexes
$regexes = Get-Content "C:\FindstrScript\findme.txt"

$x = 1
$y = 1


#For each entry
foreach ($MyFolders in $ListFolders) {

    foreach ($regex in $regexes) {
       
        #Make sure ends with \
        if ($MyFolders.Substring($MyFolders.Length - 1) -ne "\") {
            $MyFolders = $MyFolders + "\"
        }
        
        #if folder is not in the ignore list
        if ($arrIgnore.Contains($MyFolders) -eq $false) {
            $ParsedMyfolders = $Myfolders -Replace '[^a-zA-Z0-9]', '_'
            
            #Do 1st output - Findstr the root of the specified folder
            # "Findstr /PIN /G:${Searchterms} `"${Myfolders}*`" >> ${OutputLocation}${ParsedMyFolders}.txt" | Out-File ${OutputFile} -Encoding ascii -Append
            "sls -Path `"${MyFolders}*`" -Pattern `"${regex}`" >> ${OutputLocation}${ParsedMyFolders}_${x}.txt" | Out-File ${OutputFile} -Encoding ascii -Append
            $x++

            #Do 2nd output - Findstr for direct subfolders of the specified folder, including hidden
            $SecondLevels = Get-ChildItem -Path $MyFolders -Recurse -Attributes d, d+h
            $Anysubfolders = $SecondLevels | Measure-Object
            
            #ignore if subfolder is empty
            if ($Anysubfolders.Count -gt 0) {
                foreach ($SecondLevel in $SecondLevels) {
                    if ($arrIgnore.Contains("$($secondlevel.FullName)\") -eq $false) {
                        $ParsedName = $SecondLevel.FullName -Replace '[^a-zA-Z0-9]', '_'
                        # "Findstr /PIN /G:${Searchterms} `"$($secondlevel.FullName)\*`" >> ${OutputLocation}${ParsedName}.txt" | Out-File ${OutputFile} -Encoding ascii -Append
                        "sls -Path `"$($secondlevel.FullName)\*`" -Pattern `"${regex}`" >> ${OutputLocation}${ParsedName}_${y}.txt" | Out-File ${OutputFile} -Encoding ascii -Append
                        $y++
                    }
                }
            }
        }
    }
}