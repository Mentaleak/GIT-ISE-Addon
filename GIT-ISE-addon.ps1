
function initiate-gitBeautifier () {
    if(!(Test-GitAuth -nobreak)){	
        connect-github
    }
    if(Test-GitAuth){
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


function add-filewatcher () {
	param($file)

	Register-ObjectEvent -InputObject $file -Verbose -EventName PropertyChanged -MaxTriggerCount 1 -Action {
		if ($Event.SourceArgs.IsSaved)
		{
			Invoke-BeautifyAndGitPushCommit -FilePath ($Event.SourceArgs.FullPath)
		}
		else {
			Write-Host $Event.SourceArgs.IsSaved
			add-filewatcher $Event.SourceArgs[0]
		}
	}

}














# requires powershell-beautifier, PSGit                       
function Invoke-BeautifyAndGitPushCommit () {
	param(
		[Parameter(mandatory = $true)] [string]$FilePath
	)
	$File = Get-ChildItem "$FilePath"
	$Folder = $File.Directory.FullName
	$TMPFolderPath = "$($env:APPDATA)\PSBeautifier-TMP\"
	if (!(Test-Path $TMPFolderPath)) {
		New-Item -ItemType directory -Path $TMPFolderPath
	}
	$TMPFilePath = "$($TMPFolderPath)$($File.Name)"
	Copy-Item -Path $FilePath -Destination $TMPFilePath -Force
	Write-Host "Beautifying $($File.name)"
	Edit-DTWBeautifyScript $TMPFilePath -IndentType Tabs
	Copy-Item -Path $TMPFilePath -Destination $FilePath -Force
	Write-Host "Git-ing $Folder"
	Add-GitAutoCommitPush




}
