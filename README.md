# Boxstarter
This repo is a demonstration of using Boxstarter and Chocolatey to set up an environment.

This PoC assumes that it will run on a base machine that has the following installed
* MS Visual Studio 2015 Enterprise
* Azure SDK for VS.NET 2015 2.7.1

I have a tested this using a prebuilt Azure VM. Search for Visual Studio Enterprise 2015 with Universal Windows Tools and Azure SDK 2.7.

First Time startup
Start up your base machine
Copy Start.CMD 
Run it as an Adminstrator

This will start a click once deployment of Boxstarter. You may find that SmartScreen stops the execution. Ignore the warnings and continue. 

Boxstarter will handle any reboots required by installed components. It runs the whole script each time ignoring anything that is already installed. It keeps trying until all components are installed. On the first reboot you'll be asked for the machine credentials. These are cached and you won't be asked again. 

The boxstarter script does the following
* Download and installs boxstarter
* Runs the script in SF-DEV\BuildEnv.txt (Boxstarter connects to GitHub to get this file)
* BuildEnv.txt uses Chocolatey to install of the prerequisite software
* BuildEnv.txt then triggers BuildSolution.ps1 (Boxstarter connects to GitHub to get this file)
* BuildSolution.ps1 clones the relevant code repo from GitHub, run all configuration steps and then builds the solution. You should be prompted for your github credentials if the repo is private
* BuildEnv.txt then triggers PostBuildSolution.ps1
* PostBuildSolution.ps1 performs any post build steps (The process is split because the MSBuild step does not alway exit cleanly)

Repeat Runs
It is unlikely that you need to repeatedly rerun the install step but you can use BuildSolution.ps1 and PostBuildSolution.ps1 to create a clean development environment. They are designed to clean out an pre existing dev environment and recreate the latest one from scratch. Trying to update an existing environment is too unreliable.

Outstanding issues
* MSBuild step doesn't exit properly
* The X drive mapping is set up yet. This need to be part of the boxtstarter script BuildEnv.txt inorder to handle the reboot properly
* During the JSPM install against the web site the number of calls to GitHUb breaches their rate limit. The process needs to be authenticated for to avoid this. I had added Git-Credential-Manager to the installation which should solve this but I have not got this reliably working on a clean machine
* Fine tune the machine setting such as showing system files or not
* Pinned key application to the taskbar
* Move the python install to Program Files
* Drop the database if they are found so ensure that there are always created on repeat runs




