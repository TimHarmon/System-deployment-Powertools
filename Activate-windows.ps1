<#
	.SYNOPSIS
		Script Name: Activate Windows.

	.DESCRIPTION
		Script Template.

	.PARAMETER  

	.NOTES
		Revision History
		Version		Author			Description
		1.0			Tim Harmon		Initial Script
#>


#Region Set Parameters 
	param(
		[String] $CSVFilePath
		, [Switch] $Activate
		, [Switch] $ApplyKey
		, [Switch] $GetActivationID
		, $Credential = $Null
		)
#EndRegion
#region Set Script behaviour.
	#Export-ModuleMember
	Set-StrictMode -Version 2.0
#endregion
#Region Functions
	Function OutputValidationLine {
	param(
		[System.String] $Label,
		[System.String] $Result,
		[System.String] $Color,
		[system.Int16]  $ScreenWidth = (get-host).ui.rawui.windowsize.width - 10,
		[Switch] $Tab,
		[Switch] $Time
	)		

	try {
		$TimeStr = "[ " + ((Get-date -DisplayHint Time -UFormat %T ).toString()) + " ] "
		$ScreenDif = $ScreenWidth - ($Label.Length + $Result.Length + 2)
		$TabWidth = $TimeStr.Length
		IF ($Time -eq $true) {
			$ScreenDif = $ScreenDif - $TimeStr.Length
			Write-Host $TimeStr -NoNewline}
		IF ($Tab -eq $true) {
			$TabStr = "     "
			$ScreenDif = $ScreenDif - $TabSTR.Length		
			Write-Host $TabSTr -NoNewline
		}
			
		$Spacer =  write-output ("." * $ScreenDif)
		$New = $Label + " " + $Spacer + " "
		
		Write-Host $New -NoNewline
		IF (($Color -eq $null) -or ($color -eq "")) 
			{Write-Host $Result}
		Elseif (($Color -ne $null) -or ($color -ne ""))
			{Write-Host $Result -ForegroundColor  $Color}
	}
	catch {
		throw
	}
}
#endregion
#Region Script
#Clear Errors and screen
Clear-Host
$Error.Clear()

#Region Declare Constants
	#[System.String[]]$RequiredWindowsComponents =@("Web-FTP-Server","Web-Mgmt-Service")
	[system.Int16] $ScreenWidth = (Get-host).ui.rawui.windowsize.width - 5
#EndRegion

#Region Declare Variables
	# Template Variables
	[System.Int32] $WarningCount = 0
	[System.int32] $ErrorCount = 0
	[System.String] $ScriptName = "Activate-Windows Script"
	[System.String] $CompanyLine = "System-Deployment-Powertools (GNU GENERAL PUBLIC LICENSE V2)"
	[System.String] $ScriptLogName = "Activate-Windows"
	[System.String] $ScriptTitle = "Script Name: " + $ScriptName
	[System.DateTime] $ScriptStartDateTime = Get-date
	
	# Script Variables
	[System.String] $LogedinUser = [Environment]::UserName
	[System.String] $ComputerName = Get-WmiObject win32_computersystem | Select-Object -Property dnshostname -ExpandProperty dnshostname	

#EndRegion

# Start Loging
[system.string] $loggingFileName = '.\' + $ScriptLogName + '-' + ($ScriptStartDateTime).tostring("yyyyMMdd")  + '.log' 

IF (($host.name -eq "ConsoleHost") -eq $True) {Start-Transcript -Path $loggingFileName -Append | out-null}

#Region Create Script header
	Write-Host ""
	Write-output ("-" * $ScreenWidth )
	$Spacer = Write-Output (" " * ($ScreenWidth-$CompanyLine.Length - 5))
	Write-Host "|" $CompanyLine $Spacer "|"
	$Spacer = Write-Output (" " * ($ScreenWidth-$ScriptTitle.Length - 5))
	Write-Host "|" $ScriptTitle $Spacer "|"
	Write-output ("-" * $ScreenWidth)
	Write-Host ""
#EndRegion

#Region Script
Try {
		# Logging Start of Script
		Write-Host "["(Get-Date -DisplayHint Time -UFormat %T)"] Script Started"

		# Record Executing User & Computer Name
		OutputValidationLine  -Label "Computer where script executed: " -Result $ComputerName -Tab
		OutputValidationLine  -Label "User executing script: " -Result $LogedinUser -tab

		# Check for Administrator Access
		If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
		{
			OutputValidationLine -color Red -Label "Script running as administrator: "  -Tab -Result "Failed"
		}
		ElseIf (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
		{
			OutputValidationLine -color Green -Label "Script running as administrator: " -Tab -Result "Succcess"
		}
		Write-Host
		#Region ScriptWork
			$CSV = import-csv $CSVFilePath
			
			foreach ($Machine in $CSV) {
				OutputValidationLine -Label "     Connecting to Server: " -Tab -Result $Machine.HostName
				try {
					
					If ($Credential -ne $null) {
						$Credential | gm
						$Session = New-PSSession -ErrorAction Continue -Credential $Credential -ComputerName $Machine.Hostname}
					Elseif ($Credential -eq $null) {
						$Credential | gm
						$Session = New-PSSession -ErrorAction Continue -ComputerName $Machine.Hostname}
									
					if ($Session -ne $null) {
											if ($ApplyKey -eq $true) {
							OutputValidationLine -Label "          Applying Key on Server: " -Tab -Result $Machine.HostName
							Invoke-Command -Session $Session -ErrorAction Continue -ArgumentList $Machine.ActivationKey -ScriptBlock {
									Param($AK)
									cscript $Env:windir\System32\slmgr.vbs -ipk $AK
							}
						}
						if ($Activate -eq $true) {
							OutputValidationLine -Label "          Activating Server: " -Tab -Result $Machine.HostName
							Invoke-Command -Session $Session -ErrorAction Continue  -ScriptBlock {
									cscript $Env:windir\System32\slmgr.vbs -ato
							}
						}
						
						if ($GetActivationID -eq $true) {
							OutputValidationLine -Label "          Get Activation Key on Server: " -Tab -Result $Machine.HostName
							Invoke-Command -Session $Session -ErrorAction Continue -ArgumentList $Machine.ActivationKey -ScriptBlock {
									Param($AK)
									cscript $Env:windir\System32\slmgr.vbs -dti}
							}
						
						Invoke-Command -Session $Session -ErrorAction Continue  -ScriptBlock {
									cscript $Env:windir\System32\slmgr.vbs -dli
						}
					}
					Remove-PSSession -Session $Session
				} catch {
					throw
				}
			}
			
		#EndRegion
	}
Catch {}
Finally {
		Write-Host ""
		Write-Host "["(Get-Date -DisplayHint Time -UFormat %T)"] End of script"
		Write-Host ""

		IF (($host.name -eq "ConsoleHost") -eq $True) {Stop-Transcript -ErrorAction SilentlyContinue | out-null}
	}
#EndRegion

#EndRegion 

