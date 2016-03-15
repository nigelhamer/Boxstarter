#
# Assumes that this is running on an preconfigured VS 2015 Enterprise Azure SDK 2.7 VM
#

# Boxstarter options
$Boxstarter.RebootOk=$true # Allow reboots?
$Boxstarter.NoPassword=$false # Is this a machine with no login password?
$Boxstarter.AutoLogin=$true # Save my password securely and auto-login after a reboot

# Basic setup
Update-ExecutionPolicy Unrestricted
Set-ExplorerOptions -showHidenFilesFoldersDrives -showProtectedOSFiles -showFileExtensions

if (Test-PendingReboot) { Invoke-Reboot }

# Update Windows and reboot if necessary
#Install-WindowsUpdate -AcceptEula
#if (Test-PendingReboot) { Invoke-Reboot }

# Install IIS
cinst IIS-WebServerRole -source WindowsFeatures

cinst IIS-ApplicationDevelopment -source WindowsFeatures
cinst IIS-NetFxExtensibility45 -source WindowsFeatures
cinst NetFx4Extended-ASPNET45 -source WindowsFeatures
cinst IIS-ASPNet45 -source WindowsFeatures
cinst IIS-ApplicationInit -source WindowsFeatures
cinst IIS-CGI -source WindowsFeatures
cinst IIS-ISAPIExtensions -source WindowsFeatures
cinst IIS-ISAPIFilter -source WindowsFeatures
cinst IIS-ServerSideIncludes -source WindowsFeatures
cinst IIS-WebSockets -source WindowsFeatures

cinst IIS-CommonHttpFeatures -source WindowsFeatures
cinst IIS-HttpRedirect -source WindowsFeatures

cinst IIS-HealthAndDiagnostics -source WindowsFeatures
cinst IIS-CustomLogging -source WindowsFeatures
cinst IIS-LoggingLibraries -source WindowsFeatures
cinst IIS-RequestMonitor -source WindowsFeatures
cinst IIS-HttpTracing -source WindowsFeatures

cinst IIS-Performance -source WindowsFeatures
cinst IIS-HttpCompressionDynamic -source WindowsFeatures

cinst IIS-Security -source WindowsFeatures
cinst IIS-BasicAuthentication -source WindowsFeatures
cinst IIS-CertProvider -source WindowsFeatures
cinst IIS-ClientCertificateMappingAuthentication -source WindowsFeatures
cinst IIS-DigestAuthentication -source WindowsFeatures
cinst IIS-IISCertificateMappingAuthentication -source WindowsFeatures
cinst IIS-IPSecurity -source WindowsFeatures
cinst IIS-URLAuthorization -source WindowsFeatures
cinst IIS-WindowsAuthentication -source WindowsFeatures

cinst IIS-ManagementScriptingTools -source WindowsFeatures
if (Test-PendingReboot) { Invoke-Reboot }

# Install SQL Express
cinst mssqlserver2014express
if (Test-PendingReboot) { Invoke-Reboot }

# Install From platform installer
cinst webpi 
cinst urlrewrite

# VS extensions
Install-ChocolateyVsixPackage SlowCheetah2015 https://visualstudiogallery.msdn.microsoft.com/05bb50e3-c971-4613-9379-acae2cfe6f9e/file/171400/1/SlowCheetah.vsix
Install-ChocolateyVsixPackage EditorConfigPlugin https://visualstudiogallery.msdn.microsoft.com/c8bccfe2-650c-4b42-bc5c-845e21f96328/file/75539/12/EditorConfigPlugin.vsix

# Other Dev Tools and Libraries
cinst git.install
cinst python2
cinst nodejs.install

#Browsers
cinst googlechrome
#cinst firefox

#Other essential tools
cinst 7zip
cinst fiddler4
