Param(
    [string]$buildMode = "PRJ1" #prj1, prj2, dev, int, tst, val, sup
)
Write-Host "Build Mode: $buildMode"


Get-DisplayResolution
Add-Type -AssemblyName System.Windows.Forms
Add-Type -assembly "system.io.compression.filesystem"
[System.Windows.Forms.Screen]::AllScreens

Write-Host "Path: " + $PSScriptRoot
#timestamp for reports
$timestamp = Get-Date -Format o | foreach {$_ -replace ":", "."}


$repoRoot = split-path $PSScriptRoot


$autoTestingPath = "$repoRoot\Katalon"

Write-Host "Starting Run of Tests"

#Name of the test project being ran
$testName = "Kilimanjaro"

#path to katalon project
$projectPath="$autoTestingPath\Kilimanjaro.prj"
Write-Host "Project Path - $projectPath"
$testSuiteDirectory="$autoTestingPath\Test Suites\Test Suite Collections"
Write-Host "Test Suite Path - $testSuiteDirectory"

#path to katalon reports
$baseReportPath="$autoTestingPath\Reports"
#clear out reports folder
Remove-Item -Force -Path "$baseReportPath\*" -Recurse


#browsers to test against
$browsersToTestOn = @(,
"Chrome(headless)"
);

Foreach ($browser in $browsersToTestOn) {
#getting browser name for path
$browserName = $browser -replace '\s',''

Write-Host "Running test on Browser - $browserName"

Write-Host  "begin testing here: $testSuiteDirectory"

   #loop through each file in the testsuitedirectory
    foreach($file in Get-ChildItem -Recurse $testSuiteDirectory -Filter *.ts)
    {
     Write-Host "Path: " + $MyInvocation.MyCommand.Path
     $testSuiteCollectionPath = $file.DirectoryName + "\"  + $file.BaseName
     $fullFileName = $testSuiteCollectionPath + ".ts"
     (Get-Content $fullFileName).replace("<profileName>PRJ1</profileName>", "<profileName>$buildMode</profileName>") | Set-Content $fullFileName

     $startPosition = $testSuiteCollectionPath.IndexOf("Test");

     $word = $testSuiteCollectionPath.Substring($startPosition, ($testSuiteCollectionPath.Trim().Length - $startPosition));
     Write-Host "word" $word

     $testSuiteCollectionPath = $word
     write-host "full test path: " $testSuiteCollectionPath
     $test = ([io.fileinfo]"$file").basename
     Write-Host "test suite collection file name: $test"

    #name of the report to be generated
    $reportName = "$test$browserName"
    Write-Host "Report file name: $reportName"

    #path to where the report will be saved.
    $reportPath="$baseReportPath\$reportName"
    Write-Host "Report Path: $reportPath\$reportName"


    if(!(Test-Path -Path $reportPath)){
        Write-Host "Cannot Find $reportPath"
        #If it doesn't then create it.
        New-Item -Path "$reportPath" -Type Directory
    }

     # to enable consolelog and keep open add the following flags -consoleLog -noExit
       & D:\Katalon_Studio_Windows\katalon.exe -noSplash  -runMode=console -reportFolder="$reportPath" -reportFileName="$reportName"  -consoleLog -projectPath="$projectPath" -retry=0 -testSuiteCollectionPath="$testSuiteCollectionPath" -executionProfile="$buildMode" -browserType="$browser" | Out-Null
        #katalon -noSplash -summaryReport -runMode=console -consoleLog  -noExit -reportFolder="$reportPath" -reportFileName="$reportName" -projectPath="$projectPath" -retry=0 -testSuitePath="$testPath" -executionProfile="PRJ1" -browserType="$browser"
          if ($LastExitCode -ne 0) {
            Write-Host "Tests Failed"
            Write-Host "Exit Code:  $LastExitCode."
            Exit -1;
         } else{
            Write-Host "Tests Passed"
            #need to wait for chrome to exit each time
            Start-Sleep -s 10
         }
    }
}



exit 0;
