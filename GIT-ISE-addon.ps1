# requires powershell-beautifier, PSGit                       
function Invoke-BeautifyAndGitPushCommit () {
	param(
		[switch]$fixes,
		$filepath = $psISE.CurrentPowerShellTab.Files.SelectedFile.FullPath,
		[switch]$close
	)
	if (!(Test-GitAuth -nobreak)) {
		Connect-github
	}
	else {
		#Save current File
		($psise.CurrentPowerShellTab.Files | Where-Object { $_.FullPath -eq "$filepath" }).Save()
		#close File
		$psISE.CurrentPowerShellTab.Files.Remove(($psise.CurrentPowerShellTab.Files | Where-Object { $_.FullPath -eq "$filepath" }))
		#get file
		$File = Get-ChildItem "$FilePath"
		$Folder = $File.Directory.FullName
		if ($fixes) {
			$repodata = Get-GitRepo $Folder
			$fixeslist = get-gitfixesUI $repodata.full_name
		}
		#MAKE COPY local for beautifying
		$TMPFolderPath = "$($env:APPDATA)\PSBeautifier-TMP\"
		if (!(Test-Path $TMPFolderPath)) {
			New-Item -ItemType directory -Path $TMPFolderPath
		}
		$TMPFilePath = "$($TMPFolderPath)$($File.Name)"
		Copy-Item -Path $FilePath -Destination $TMPFilePath -Force

		#beautify Script
		Write-Host "Beautifying $($File.name)"
		Edit-DTWBeautifyScript $TMPFilePath -IndentType Tabs

		#copy back to destination
		Copy-Item -Path $TMPFilePath -Destination $FilePath -Force

		#Push Git
		Write-Host "Git-ing $Folder"
		if ($fixeslist) {
			Add-GitAutoCommitPush -ProjectPath $Folder -fixes $fixes
		} else {
			Add-GitAutoCommitPush -ProjectPath $Folder
		}

		#reopen file
		if (!($close)) { psEdit $filepath }

	}
}

<#
$menu = $psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("GIT",$null,$null)
$menu.Submenus.Add("Save-BeautifyGitPush",{ Invoke-BeautifyAndGitPushCommit },"CTRL+Shift+S")
$menu.Submenus.Add("Save-BeautifyGitPushFIXES",{ Invoke-BeautifyAndGitPushCommit -fixes},"CTRL+ALT+S")
$menu.Submenus.Add("END DAY PUSH",{ $psISE.CurrentPowerShellTab.files.fullpath |foreach{Invoke-BeautifyAndGitPushCommit -filepath "$($_)" -close}},"CTRL+Shift+ALT+S")
$menu.Submenus.Remove($menu.Submenus[1])
#>


function install-SaveBeautifyGitPush () {

	$IBAGPC = Get-ChildItem function:\ | Where-Object { $_.Name -eq "Invoke-BeautifyAndGitPushCommit" }
	$ScriptString = ""
	$psProfilePath = "$($env:USERPROFILE)\MY Documents\windowspowershell\Microsoft.PowerShellISE_profile.ps1"
	if (Test-Path $psProfilePath) {
		$ScriptString = Get-Content $psProfilePath
	}
	if (!($ScriptString -match "This marker is to add the SaveBeautifyGitPush"))
	{
		$ScriptString += "# This marker is to add the SaveBeautifyGitPush `n"
		$ScriptString += "Import-module PSTools `n"
		$ScriptString += "Import-module PSGit `n"
		$ScriptString += "function Invoke-BeautifyAndGitPushCommit () { `n"
		$ScriptString += $IBAGPC.Definition
		$ScriptString += "`n}`n `$menu = `$psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(`"GIT`",$null,$null) `n `$menu.Submenus.Add(`"Save-BeautifyGitPush`",{ Invoke-BeautifyAndGitPushCommit },`"CTRL+Shift+S`")"
		$ScriptString | Out-File $psProfilePath
	}


}





















#obsolete
function initialize-gitBeautifier () {
	if (!(Test-GitAuth -nobreak)) {
		Connect-github
	}
	if (Test-GitAuth) {
		Get-EventSubscriber -Force | Unregister-Event -Force
		Register-ObjectEvent -InputObject $psISE.CurrentPowerShellTab.Files CollectionChanged -Action {
			$global:evargs = $eventArgs
			if ($eventArgs.Action -eq "Add")
			{
				$file = $eventArgs.newitems[0]
				Write-Host "add watch for $($file.Displayname)"
				add-filewatcher $file
			}

		}
	}
}


#obsolete
function add-filewatcher () {
	param($file)

	Register-ObjectEvent -InputObject $file -Verbose -EventName PropertyChanged -MaxTriggerCount 1 -Action {
		if ($Event.SourceArgs.IsSaved)
		{
			Invoke-BeautifyAndGitPushCommit -FilePath ($Event.SourceArgs.FullPath)
			add-filewatcher $Event.SourceArgs[0]
		}
		else {
			Write-Host $Event.SourceArgs.IsSaved
			add-filewatcher $Event.SourceArgs[0]
		}
	}

}
