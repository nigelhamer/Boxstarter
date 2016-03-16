# Get the latest code from Git Hub and rebuilds
# Assume that we are wiping the environment and starting again

$BuildConfiguration="Debug"

$repoBasefolder = "c:\repo"
$storeFeederBaseFolder = (join-path $repoBasefolder "/storefeeder")
$sfliteFolder = (join-path $repoBasefolder "/storefeeder/sflite")
$gitHubReporUrl = "https://github.com/StoreFeeder/sflite"
$sfliteIISBindingUrl = "sflite.localtest.me" 
$sfliteSupportIISBindingUrl = "sflitesupport.localtest.me"

$dbHost = "(localdb)\MSSQLLocalDB"

$migrationExePath = "X:\NuGet\FluentMigrator.Tools.1.6.0\tools\AnyCPU\40\Migrate.exe"

$sflDbDllRelativePath= "Data\SFLite.Data.Migrations\bin\$BuildConfiguration\SFLite.Data.Migrations.dll"
$rootDbDllRelativePath= "Data\SFLite.Data.Migrations.RootDB\bin\$BuildConfiguration\SFLite.Data.Migrations.RootDB.dll"
$middlewareDbDllRelativePath= "Data\SFLite.Data.Migrations.MiddlewareDB\bin\$BuildConfiguration\SFLite.Data.Migrations.MiddlewareDB.dll"

$dataMigrationsPath = (join-path $sfliteFolder $sflDbDllRelativePath)
$rootDataMigrationsPath = (join-path $sfliteFolder $rootDbDllRelativePath)
$middlewareDataMigrationsPath = (join-path $sfliteFolder $middlewareDbDllRelativePath)

$sfliteAppPoolName = "IIS APPPOOL\sflite.localtest.me"
$supportAppPoolName = "IIS APPPOOL\sflitesupport.localtest.me"

function prepareSFliteRepoFolder($folder) {    

    Write-Host "Preparing SFLite Lite Repo..." -foregroundcolor "yellow"

    if ((Test-Path -Path $folder)) {
           #Remove-Item -recurse -force $folder
           # Our file path are too long

           Write-Host "Deleting Repo from local disk... This can take some time!" 
           $command = "cmd /C rmdir /S /Q " + $folder
           Invoke-Expression $command  
    }    
     New-Item -ItemType directory -Path $folder       
}


function installFontsForLabelGeneration() {
	if ($installFontsForLabelGeneration -eq $true) {

        $tempFolderPath = $env:temp + "\SFLiteFonts"

        Write-Host "Downloading and installing fonts..." -foregroundcolor "yellow"
        Write-Host "Using temp path " $tempFolderPath
        
        $font1Url = "http://storefeedersystem.blob.core.windows.net/startup/Fonts/ARIALUNI.TTF"
        $font2Url = "http://storefeedersystem.blob.core.windows.net/startup/Fonts/chevin-bold.ttf"
        $font3Url = "http://storefeedersystem.blob.core.windows.net/startup/Fonts/ChevinLight.ttf"
        $font1Path = $tempFolderPath + "\ARIALUNI.TTF"
        $font2Path = $tempFolderPath + "\chevin-bold.ttf"
        $font3Path = $tempFolderPath + "\ChevinLight.ttf"
        
        if (!(Test-Path -Path $tempFolderPath)) {
            New-Item -ItemType directory -Path $tempFolderPath
        }
        
        Write-Host "Downloading..."
        
        $object = New-Object Net.WebClient
        $object.DownloadFile($font1Url, $font1Path)
        $object.DownloadFile($font2Url, $font2Path)
        $object.DownloadFile($font3Url, $font3Path)
        
        Write-Host "Installing..."
        
        $args = @() + ("-path", $tempFolderPath)
        $cmd = ".\SetupScripts\InstallFont.ps1"
        
        Invoke-Expression "$cmd $args"

        Write-Host "Deleting temporary files..."

        Remove-Item $font1Path
        Remove-Item $font2Path
        Remove-Item $font3Path
    }
}


function CloneRepo($folder, $repoUrl) { 
    Write-Host "Cloning Repo from GitHub..." -foregroundcolor "yellow"
    Write-Host "Enter credential when prompted..." 

    set-location $folder
    & git clone $repoUrl
}


function createIISSites($siteUrl, $baseDirectory){

	if ($null -eq (get-webbinding | where-object {$_.bindinginformation -eq "*:80:$siteUrl"}))
	{ 
        Write-Host "There is no binding for $siteUrl and it will be created."  -foregroundcolor "yellow" 
		if ((Test-Path IIS:\AppPools\$siteUrl) -eq $false ){
		  	$appPool = New-Item ("IIS:\AppPools\" + $siteUrl)
			Set-ItemProperty -Path IIS:\AppPools\$siteUrl -Name processmodel.identityType -Value 4
		} 

		$iisApp = New-Item iis:\Sites\$siteUrl -bindings @{protocol="http";bindingInformation="*:80:$siteUrl"} -physicalPath $baseDirectory 
		$iisApp | Set-ItemProperty -Name "applicationPool" -Value $siteUrl
        Write-Host "Binding for $siteUrl and is created."  -foregroundcolor "green" 
    }
}


function createDbIfNeeded($dbName, $folder) {

    Set-Location $folder

	#sflite.localtest.me
	Write-Host "Creating DB if necessary $dbName"  -foregroundcolor "yellow"

	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
	$srv = new-Object Microsoft.SqlServer.Management.Smo.Server("(localdb)\MSSQLLocalDB")
	$db = $srv.Databases["$dbName"]
	
	$createDbSqlPath = (join-path $folder "SetupScripts\CreateDatabase.sql")
	#.\MSSQLLocalDB
	If($db -eq $null) {
		Write-Host "Db $dbName will be created" -foregroundcolor "yellow" 
	
		& sqlcmd -E -S $dbHost -dmaster -i"$createDbSqlPath" -cGO -v db="$dbName" -v sfliteAppPoolName= "$sfliteAppPoolName"  -v supportAppPoolName= "$supportAppPoolName" 
		
		Write-Host "Created Db $dbName" -foregroundcolor "yellow"
	}
	else{
		Write-Host "Db $dbName already exists" -foregroundcolor "yellow"
	}
}

function buildDotNetSolution($folder) {

    $buildSucceeded = $false
    Write-Host "Building the solution" -foregroundcolor "yellow"

    set-location $folder

    $buildSucceeded = Invoke-MsBuild -Path "SFLite.sln"  -MsBuildParameters  "/p:Configuration=Debug /target:Build" -ShowBuildWindow

}


function importCustomModules($folder) {

    Import-Module -Name (join-path $folder 'SetupScripts\Invoke-MsBuild.psm1')
}


function InstallDependencies($folder){
	
	Set-Location -Path (join-path $folder "Web\SFLite.Web.Site")
	
	Write-Host "Running npm install" -foregroundcolor "yellow"
	& npm install --no-optional
	
	Write-Host "Running jspm install" -foregroundcolor "yellow"
	& jspm install	 
}


function createXDrive($folder){

    $command = (join-path $folder ".NuGet\CreateAndMapXDrive.cmd")
    Invoke-Expression $command
}

function performMigrations($dbName) {	
	
	Write-Host "Running Sflite1 db migration" -foregroundcolor "yellow" 
	& $migrationExePath --provider="Sqlserver2014" --a="$dataMigrationsPath" --c="SFLiteMain001"  
		
	Write-Host "Running Sflite2 db migration"  -foregroundcolor "yellow" 
	& $migrationExePath --provider="Sqlserver2014" --a="$dataMigrationsPath" --c="SFLiteMain002" 
	
	Write-Host "Running Root db migration" -foregroundcolor "yellow" 
	& $migrationExePath --provider="Sqlserver2014" --a="$rootDataMigrationsPath" --c="SFLiteRoot"  
	
	Write-Host "Running Middleware db migration" -foregroundcolor "yellow" 
	& $migrationExePath --provider="Sqlserver2014" --a="$middlewareDataMigrationsPath" --c="SFLiteMiddleware"  
	
}


function checkDevConnectionStringFile($folder){
	
	$devConnectionStringPath = (join-path $folder "Web\SFLite.Web.Site\Configuration\connectionstrings.LOCAL.config")
	$devConnectionStringSamplePath = (join-path $folder "Web\SFLite.Web.Site\Configuration\connectionstrings.LOCAL-EXAMPLE.config")
	$supportDevConnectionStringPath = (join-path $folder "SupportSite\SFLite.Web.SupportSite\Configuration\connectionstrings.LOCAL.config")
	
	If ( (Test-Path $devConnectionStringPath) -eq $false){  
		Write-Host "Development connection string does not exist. copying the sample file"
		Copy-Item $devConnectionStringSamplePath $devConnectionStringPath
		Write-Host "The sample file is copied to $devConnectionStringPath" -foregroundcolor "yellow"
		Write-Host "Please check the contents" -foregroundcolor "yellow" 
	}
	#$supportConnectionStringsFile 
	If ( (Test-Path $supportDevConnectionStringPath) -eq $false){  
		Write-Host "Development connection string does not exist. copying the sample file"
		Copy-Item $devConnectionStringSamplePath $supportDevConnectionStringPath
		Write-Host "The sample file is copied to $supportDevConnectionStringPath" -foregroundcolor "yellow"
		Write-Host "Please check the contents" -foregroundcolor "yellow" 
	}
}


function verifyDevConnectionStrings($folder){

    $missingConnectionStringNames = @()
    $sampleConnectionStringPath = (join-path $folder "Web\SFLite.Web.Site\Configuration\connectionstrings.LOCAL-EXAMPLE.config")
    $devConnectionStringPath = (join-path $folder "Web\SFLite.Web.Site\Configuration\connectionstrings.LOCAL.config")

	$sampleConnectionStrings = getSampleConnectionStrings $sampleConnectionStringPath
	$devConnectionStrings = getSampleConnectionStrings $devConnectionStringPath

    #ensure each sample connection string name exists in dev connection strings file
	foreach ($name in $sampleConnectionStrings) {
			 $idx = $devConnectionStrings.IndexOf($name)
			 if($idx -lt 0){
			    $missingConnectionStringNames += ,  "$name"
			 }
	}

	if($missingConnectionStringNames.Length -gt 0 ){
	      Write-Host "The following connection strings are missing in your dev connection strings file:" -foregroundcolor "yellow"
	      Write-Host "    $devConnectionStringPath" -foregroundcolor "yellow"
	      Write-Host "Please verify the sample config file located at:" -foregroundcolor "yellow"
	      Write-Host "    $sampleConnectionStringPath" -foregroundcolor "yellow"
	      Write-Host "Missing Keys:" -foregroundcolor "red"

        foreach ($name in $missingConnectionStringNames) {
            Write-Host "    $name" -foregroundcolor "red"
        }

	    Write-Host "The script execution is rerminated" -foregroundcolor "red"
        exit 1
    }
}


function getSampleConnectionStrings($path){

    $xlinq = [Reflection.Assembly]::Load("System.Xml.Linq, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")

	$connectionStringNames = @()

    # load the config file as an xml object
    $appConfig =[System.Xml.Linq.XDocument]::Load($path)

	foreach ($connString in $appConfig.Descendants("add")) {
		$connectionStringNames += , $connString.Attribute("name").Value
	}

	return $connectionStringNames
}	


function unlockWebConfigIPSecuritySection() {
	$command = 'C:\Windows\system32\inetsrv\AppCmd.exe unlock config /section:system.webServer/security/ipSecurity'

	Invoke-Expression -Command:$command
}


function runGulpTasks($folder){

    Write-Host "Calling gulp sass"  -foregroundcolor "yellow" 
	 Set-Location -Path (join-path $folder "web\SFLite.Web.Site")
	 & gulp sass 
	 & gulp bundleTemplates
}



function waitForKeypress() {

    # Flush any existing keypresses:
    while ($host.UI.RawUI.KeyAvailable) {
        $host.UI.RawUI.ReadKey() | Out-Null
    }

	Write-Host "Press any key to continue..."

	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}



cls

prepareSFliteRepoFolder($sfliteFolder)
CloneRepo -folder $storeFeederBaseFolder -repoUrl $gitHubReporUrl

checkDevConnectionStringFile($sfliteFolder)
#if connection strings are missing on dev, output an error and exit
verifyDevConnectionStrings($sfliteFolder)

#Need to be part of the environment setup as it requires a reboot
#createXDrive($sfliteFolder)
importCustomModules($sfliteFolder)

createIISSites -siteUrl $sfliteIISBindingUrl -baseDirectory (join-path $sfliteFolder 'web\SFLite.Web.Site\')
createIISSites -siteUrl $sfliteSupportIISBindingUrl -baseDirectory (join-path $sfliteFolder 'SupportSite\SFLite.Web.SupportSite\')

createDbIfNeeded -dbName "DevSFLiteMain001" -folder $sfliteFolder
createDbIfNeeded -dbName "DevSFLiteMain002" -folder $sfliteFolder
createDbIfNeeded -dbName "DevSFLiteRoot" -folder $sfliteFolder 
createDbIfNeeded -dbName "DevSFLiteMiddleware" -folder $sfliteFolder

InstallDependencies($sfliteFolder)
buildDotNetSolution($sfliteFolder)
performMigrations($sfliteFolder)

runGulpTasks($sfliteFolder)

waitForKeypress