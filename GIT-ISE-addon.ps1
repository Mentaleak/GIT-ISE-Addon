# requires powershell-beautifier, PSGit                       
function Invoke-BeautifyAndGitPushCommit () {
	param(
		[switch]$fixes,
		$filepath = $psISE.CurrentPowerShellTab.Files.SelectedFile.FullPath,
		[switch]$close
	)
	Write-Host "test-gitAuth"
	if (!(Test-GitAuth -nobreak)) {
		Connect-github
	}
	if (Test-GitAuth) {
		#Save current File
		Write-Host "Save File"
		($psise.CurrentPowerShellTab.Files | Where-Object { $_.FullPath -eq "$filepath" }).Save()

		Write-Host "Get File and folder path"
		#get file and folder
		$File = Get-ChildItem "$FilePath"
		if ($File.Directory.Name -eq "src") {
			$Folder = $File.Directory.Parent.FullName }
		else { $Folder = $File.Directory.FullName }
		Write-Host "Check for .git presence on $folder"
		if (test-GitLocal -ProjectPath $Folder)
		{
			#close File
			$psISE.CurrentPowerShellTab.Files.Remove(($psise.CurrentPowerShellTab.Files | Where-Object { $_.FullPath -eq "$filepath" }))
			#get file
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
			$temp = Get-Content $TMPFilePath
			$temp = $temp.Replace(". `"",".`"")
			$temp | Out-File $FilePath -Force
			#Copy-Item -Path $TMPFilePath -Destination $FilePath -Force

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
}


<#
$menu = $psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("GIT",$null,$null)
$menu.Submenus.Add("Save-BeautifyGitPush",{ Invoke-BeautifyAndGitPushCommit },"CTRL+Shift+S")
$menu.Submenus.Add("Save-BeautifyGitPushFIXES",{ Invoke-BeautifyAndGitPushCommit -fixes},"CTRL+ALT+S")
$menu.Submenus.Add("END DAY PUSH",{ $psISE.CurrentPowerShellTab.files.fullpath |foreach{Invoke-BeautifyAndGitPushCommit -filepath "$($_)" -close}},"CTRL+Shift+ALT+S")

$menu.Submenus.Remove($menu.Submenus[0])

$menu = $psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Debug+",$null,$null)
$menu.Submenus.Add("debug",{ $wshell = New-Object -ComObject wscript.shell; $wshell.AppActivate('Windows PowerShell ISE'); $wshell.SendKeys('{F8}'); sleep -Milliseconds 200; $wshell.SendKeys('^b')},"CTRL+Shift+B")

#>


function install-SaveBeautifyGitPush () {

	$IBAGPC = Get-ChildItem function:\ | Where-Object { $_.Name -eq "Invoke-BeautifyAndGitPushCommit" }
	$ScriptString = ""
	$psProfilePath = "$($env:USERPROFILE)\MY Documents\windowspowershell\Microsoft.PowerShellISE_profile.ps1"
	if (Test-Path $psProfilePath) {
		$ScriptString = (Get-Content $psProfilePath).Trim()
	}
	if (!($ScriptString -match "#region git-ISE-addon"))
	{
		Write-Host "Installing git-ise-addon"
		$ScriptString += "`n #region git-ISE-addon `n"
		$ScriptString += "Import-module PSTools `n"
		$ScriptString += "Import-module PSGit `n"
		$ScriptString += "Import-module PSGit `n"
		$ScriptString += "function Invoke-BeautifyAndGitPushCommit () { `n"
		$ScriptString += $IBAGPC.Definition
		$ScriptString += "`n}`n `$menu = `$psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(`"GIT`",$null,$null) `n"
		$ScriptString += "`$menu.Submenus.Add(`"Save-BeautifyGitPush`",{ Invoke-BeautifyAndGitPushCommit },`"CTRL+Shift+S`") |out-null `n"
		$ScriptString += "`$menu.Submenus.Add(`"Save-BeautifyGitPushFIXES`",{ Invoke-BeautifyAndGitPushCommit -fixes },`"CTRL+ALT+S`") |out-null `n"
		$ScriptString += "`$menu.Submenus.Add(`"END DAY PUSH`",{ `$psISE.CurrentPowerShellTab.files.fullpath |foreach{Invoke-BeautifyAndGitPushCommit -filepath `"`$(`$_)`" -close}},`"CTRL+Shift+ALT+S`") |out-null `n"
		$ScriptString += "#endregion git-ISE-addon"
		$ScriptString | Out-File $psProfilePath
	}
	else {
		Write-Host "Updating git-ise-addon"
		$StartRegion = ($ScriptString.split("`n") | Select-String "#region git-ISE-addon" -AllMatches).linenumber
		$EndRegion = ($ScriptString.split("`n") | Select-String "#endregion git-ISE-addon" -AllMatches).linenumber
		$Oscript = ""
		#write-host $StartRegion
		for ($i = 0; $i -lt ($StartRegion - 1); $i++) {
			$Oscript += "$($ScriptString.split("`n")[$i]) `n"
		}
		for ($i = $EndRegion; $i -lt ($ScriptString.split("`n").count); $i++) {
			$Oscript += "$($ScriptString.split("`n")[$i]) `n"
		}
		#write-host $Oscript
		$scriptString = $OScript
		$ScriptString += "`n #region git-ISE-addon `n"
		$ScriptString += "Import-module PSTools `n"
		$ScriptString += "Import-module PSGit `n"
		$ScriptString += "Import-module show-psgui  `n"

		$ScriptString += "function Invoke-BeautifyAndGitPushCommit () { `n"
		$ScriptString += $IBAGPC.Definition
		$ScriptString += "`n}`n `$menu = `$psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(`"GIT`",`$null,`$null) `n"
		$ScriptString += "`$menu.Submenus.Add(`"Save-BeautifyGitPush`",{ Invoke-BeautifyAndGitPushCommit },`"CTRL+Shift+S`") |out-null`n"
		$ScriptString += "`$menu.Submenus.Add(`"Save-BeautifyGitPushFIXES`",{ Invoke-BeautifyAndGitPushCommit -fixes },`"CTRL+ALT+S`") |out-null`n"
		$ScriptString += "`$menu.Submenus.Add(`"END DAY PUSH`",{ `$psISE.CurrentPowerShellTab.files.fullpath |foreach{Invoke-BeautifyAndGitPushCommit -filepath `"`$(`$_)`" -close}},`"CTRL+Shift+ALT+S`") |out-null`n"
		$ScriptString += "#endregion git-ISE-addon"
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
