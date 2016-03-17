# Get the latest code from Git Hub and rebuilds
# Assume that we are wiping the environment and starting again
$BuildConfiguration="Debug"

$repoBasefolder = "c:\repo"
$storeFeederBaseFolder = (join-path $repoBasefolder "/storefeeder")
$sfliteFolder = (join-path $repoBasefolder "/storefeeder/sflite")

$migrationExePath = "X:\NuGet\FluentMigrator.Tools.1.6.0\tools\AnyCPU\40\Migrate.exe"

$sflDbDllRelativePath= "Data\SFLite.Data.Migrations\bin\$BuildConfiguration\SFLite.Data.Migrations.dll"
$rootDbDllRelativePath= "Data\SFLite.Data.Migrations.RootDB\bin\$BuildConfiguration\SFLite.Data.Migrations.RootDB.dll"
$middlewareDbDllRelativePath= "Data\SFLite.Data.Migrations.MiddlewareDB\bin\$BuildConfiguration\SFLite.Data.Migrations.MiddlewareDB.dll"

$dataMigrationsPath = (join-path $sfliteFolder $sflDbDllRelativePath)
$rootDataMigrationsPath = (join-path $sfliteFolder $rootDbDllRelativePath)
$middlewareDataMigrationsPath = (join-path $sfliteFolder $middlewareDbDllRelativePath)

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

$oldWD = Get-Location

performMigrations($sfliteFolder)
runGulpTasks($sfliteFolder)

Set-Location -Path $oldWD
waitForKeypress