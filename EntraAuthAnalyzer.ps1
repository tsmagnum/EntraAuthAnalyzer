# Setup all paths required for script to run
$ScriptPath = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path)


# Import required assets
. ("$($ScriptPath)\GlobalVariables.ps1")
. ("$($ScriptPath)\Functions.ps1")
. ("$($ScriptPath)\SupportFunctions.ps1")

# Get date (logging,timestamps, etc.)
$today = Get-Date
$launchTime = $today.ToString('ddMMyyyy-hhmm')

# Export to Excel section
if ($exportToExcel)
{
    # Check if required module is present; if not, install it
    if (!(Get-Module -ListAvailable -Name "ImportExcel")) 
    { 
                Write-Host -ForegroundColor Yellow "ImportExcel module missing, installing..."
                Install-Module -Name ImportExcel -Scope CurrentUser -Force         
    }

    # Set the Excel file for results
    $excelFileResults = Set-ResultsFile `
        -resultsFileDir $resultsFileDir -resultsFileName $resultsFileName -resultsFileExt $resultsFileExt
}

# Set the encrypted creds file path
if ($sendEmail)
{
    $encryptedSMTPCredsFile = "$($ScriptPath)\$encryptedSMTPCredsFileName"
}

# Title section
$sectionTitle = "#### Entra Auth Analyzer - version $($scriptVer) ####"
Write-SectionTitle -color white  -title $sectionTitle

# Entra Id: Authentication methods in use and MFA status
if ($entraAuthMethodsReq)
{
    $sectionTitle = "#Entra Id: Authentication methods in use and MFA status"
    Write-SectionTitle -color blue -title $sectionTitle
    $usersAuthMethodList = Get-EntraAuthMethods
    Show-Results -results $usersAuthMethodList -sortProperty Name -sectionTitle $sectionTitle
    if ($exportToExcel)
    {   Export-Excel -path $excelFileResults `
        -InputObject $usersAuthMethodList -WorksheetName "AuthMethods" `
        -BoldTopRow -TableStyle Medium19 -AutoSize
    }
}

# Entra Id: Scurity info registrations of users
if ($entraSecInfoRegReq)
{
    $sectionTitle = "#Entra Id: Scurity info registrations of users"
    Write-SectionTitle -color red -title $sectionTitle
    $secInfoRegList = Get-SecInfoRegistrations
    Show-Results -results $secInfoRegList -sortProperty Date -sectionTitle $sectionTitle
    if ($exportToExcel)
    {
        Export-Excel -path $excelFileResults `
        -InputObject $secInfoRegList -WorksheetName "SecInfoReg" `
        -BoldTopRow -TableStyle Medium19 -NoNumberConversion "IP_Addr" -AutoSize
    }
}

# Entra Id: Users excluded from CA policies
if ($entraCaExclusionsReq)
{
    $sectionTitle = "#Entra Id: Users excluded from CA policies"
    Write-SectionTitle -color cyan -title $sectionTitle
    $policiesInfoTable = Get-CaExcludedUsers
    switch ($entraCaExclusionsData) {
            list { Show-Results -results $policiesInfoTable -sortProperty CA_Policy -sectionTitle $sectionTitle -showList }
            table { Show-Results -results $policiesInfoTable -sortProperty CA_Policy -sectionTitle $sectionTitle}
            Default { Show-Results -results $policiesInfoTable -sortProperty CA_Policy -sectionTitle $sectionTitle }
    }
    if ($exportToExcel)
    {   Export-Excel -path $excelFileResults `
        -InputObject $policiesInfoTable -WorksheetName "CaExclusions" `
        -BoldTopRow -TableStyle Medium19 -AutoSize
    }
}

# Entra Id: CA Policies changes
if ($caPolicyChangesReq)
{
    Write-SectionTitle -color green -title "#Entra Id: CA Policies changes"
    $caPolicyChanges = Get-caPolicyChanges
    Show-Results -results $caPolicyChanges -sortProperty Date -sectionTitle $sectionTitle
    if ($exportToExcel)
    {
        Export-Excel -path $excelFileResults `
        -InputObject $caPolicyChanges -WorksheetName "CaPolCh" `
        -BoldTopRow -TableStyle Medium19 -NoNumberConversion "IP_Addr" -AutoSize
    }
}

# Entra Id: Successful logins not covered by a CA policy
if ($entraLoginsNoCaReq) 
{
    Write-SectionTitle -color magenta -title "#Entra Id: Successful logins not covered by a CA policy"
    $logs = Get-LoginsNoCa

        if ($entraLoginsNoCaConsoleLimit)
        {
            Write-Host -ForegroundColor Red `
                "WARNING: You have chosen to display here only the first $($entraLoginsNoCaConsoleLimit) logins!"

            Show-Results -results ($logs | Select-Object -First $entraLoginsNoCaConsoleLimit) `
                -sortProperty Date -sectionTitle $sectionTitle
        }

        else
        {
            Show-Results -results $logs -sortProperty Date -sectionTitle $sectionTitle
        }

        if ($exportToExcel)
        {   
        Export-Excel -path $excelFileResults `
        -InputObject $logs -WorksheetName "Logins_NoCA" `
        -BoldTopRow -TableStyle Medium19 -NoNumberConversion "IP_Addr" -AutoSize
        }

        if((($logs).GetType().FullName) -ne "System.String")
        {
        Write-SectionTitle -color magenta -title "#Entra Id: Logins stats"
        Analyze-LoginLogs -logs $logs
        }

}

# Send the report via e-mail if desired
if ($exportToExcel -and $sendEmail)
{
    $emailBody = `
        "Entra Id Auth Report for tenant $($tenantName) generated on $($launchTime)."
    
    try {
        Write-Host "INFO: sending your report via E-Mail to $($emailRecipient)..." -ForegroundColor Yellow
        SendEmail-Mailkit
    }
    catch {
        Write-Host "ERROR: There was a problem sending your email: $_" `
         -ForegroundColor Red
    }
}

# Disconnect Graph
if(Get-Mgcontext)
{
    Write-Host "INFO: Closing connection to MS Graph." -ForegroundColor Cyan
    Disconnect-MgGraph | Out-Null
}

# Recap region
if ($exportToExcel -and (Test-Path $excelFileResults))
{
    Write-Host `
        "INFO: An Excel file with the results has been saved in $($excelFileResults)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "INFO: Audit logs observation window: last $($loginsLookupPeriod) days." -ForegroundColor Cyan
Write-Host "INFO: Login logs observation window: last $($loginsLogsLookupPeriod) days." -ForegroundColor Cyan
Write-Host ""
Write-Host -ForegroundColor green "Script execution ended."
Write-Credits