
# requires powershell-beautifier, PSGit                       
function Invoke-BeautifyAndGitPushCommit () {
	if (!(Test-GitAuth -nobreak)) {
		Connect-github
	}
	else {
		#get File Path
		$filepath = $psISE.CurrentPowerShellTab.Files.SelectedFile.FullPath
		#Save current File
		$psISE.CurrentFile.Save()
		#close File
		$psISE.CurrentPowerShellTab.Files.Remove($psISE.CurrentPowerShellTab.Files.SelectedFile)

		#get file
		$File = Get-ChildItem "$FilePath"
		$Folder = $File.Directory.FullName

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
		Add-GitAutoCommitPush -ProjectPath $Folder

		#reopen file
		psEdit $filepath
	}
}


$menu = $psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Custom",$null,$null)
$menu.Submenus.Add("Save-BeautifyGitPush",{ Invoke-BeautifyAndGitPushCommit },"CTRL+Shift+S")
#$menu.Submenus.Remove($menu.Submenus[1])

























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



#initialize-gitBeautifier

#CLose Tab, Reopen
