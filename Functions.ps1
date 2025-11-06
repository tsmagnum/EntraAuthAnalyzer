# Connect to Microsoft Graph using a certificate
function Connect-GraphCertificate
{
    Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateThumbprint $certificateThumbprint -NoWelcome
}

# Retrieve users' authentication methods from Entra ID
function Get-EntraAuthMethods
{

    # Connect to Graph
    if(!(Get-Mgcontext))
    {
        if ($runUnattended)
        {
            Connect-GraphCertificate
        }

        else 
        {
            Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All" -NoWelcome
        }
    }

    Write-Host "INFO: Retrieving the Entra Id Users and their Authentication Methods..." -ForegroundColor Cyan

    $rawAuthInfo = Get-MgReportAuthenticationMethodUserRegistrationDetail -All | `
        Select-Object userPrincipalName, IsAdmin, isMfaRegistered,`
        isPasswordlessCapable, SystemPreferredAuthenticationMethods, methodsRegistered, IsSsprRegistered 

    # Initialize list to store results
    $usersAuthMethodList = [System.Collections.ArrayList]@()

    # Iterate through each Entra ID user
    $rawAuthInfo | ForEach-Object {
    
    $authInfo = [PSCustomObject]@{
        User = $_.UserPrincipalName
        Admin = $_.IsAdmin
        MFA_On = $_.IsMfaRegistered
        PwdLess_Cap = $_.IsPasswordlessCapable
        Pref_MFA = $_.SystemPreferredAuthenticationMethods | Out-String
        MFA_Methods = $_.MethodsRegistered -join ", "
        SSPR_On = $_.IsSsprRegistered
    }

        # Add the custom object to the results list
        [void]$usersAuthMethodList.Add($authInfo)
        Write-Debug $$authInfo
    }
    return $usersAuthMethodList
}

# Retrieve security info registration events from Entra ID
function Get-SecInfoRegistrations
{

    #Connect to Graph
    if(!(Get-Mgcontext))
    {
        if ($runUnattended)
        {
            Connect-GraphCertificate
        }

        else 
        {
            Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All" -NoWelcome
        }
    }

    Write-Host "INFO: Retrieving the security info registrations of users in Entra in the last $($loginsLookupPeriod) days..." `
        -ForegroundColor Cyan

    $secInfoRegList = [System.Collections.ArrayList]@()

    $startDate = Get-Date (Get-Date).AddDays(-($loginsLookupPeriod)) -format 'yyyy-MM-dd'
    $endDate = (Get-Date -format 'yyyy-MM-dd')

    $queryFilter = "activityDisplayName eq 'User registered security info' and result eq 'success' and activityDateTime gt $StartDate and activityDateTime lt $EndDate"


    $rawSecInfoReg = Get-MgAuditLogDirectoryAudit `
        -Filter $queryFilter -All `
        | Select-Object ActivityDateTime, ActivityDisplayName, InitiatedBy, TargetResources, ResultReason 

    $rawSecInfoReg | ForEach-Object {
        $secInfoRef = [PSCustomObject]@{
            Date = $_.ActivityDateTime
            User = $_.InitiatedBy.User.UserPrincipalName
            App = $_.InitiatedBy.App.DisplayName
            IP_Addr = $_.InitiatedBy.User.IPAddress
            Info = $_.ResultReason
        }

    [void]$secInfoRegList.Add($secInfoRef)
}
    return $secInfoRegList
}

# Retrieve users excluded from Conditional Access policies
function Get-CaExcludedUsers
{

    # Connect to Graph
    if(!(Get-Mgcontext))
    {
        if ($runUnattended)
        {
            Connect-GraphCertificate
        }

        else 
        {
            Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All" -NoWelcome
        }
    }


Write-Host "INFO: Retrieving the Entra Id CA Policies data..." -ForegroundColor Cyan
   
    # Retrieve Conditional Access policies
    $caPolicies = Get-MgIdentityConditionalAccessPolicy | `
        Select-Object DisplayName,Conditions,State

    # List to store the results    
    $policiesInfoTable = [System.Collections.ArrayList]@()

    # Create a custom object to store policy details
    foreach ($policy in $caPolicies)
    {   
        $ExclUsersList = [System.Collections.ArrayList]@()
        $ExclGroupsList = [System.Collections.ArrayList]@()
        
        $objPolicy = [PSCustomObject]@{
            CA_Policy = $policy.Displayname
            State = $policy.State
            Tot_ExclUsers = 0
            Excluded_Groups = [string]$null
            Excluded_Users = [string]$null
        }
        
        # for each policy, get the excluded users and groups
        $excludedUsers = $policy.Conditions.Users.ExcludeUsers
        $excludedGroups = $policy.Conditions.Users.ExcludeGroups 

        # Expand groups if required
        if ($expandGroups)
        {
            foreach ($excludedGroup in $excludedGroups) 
            {
                $groupMembers = Get-MgGroupMember -GroupId $excludedGroup | Select-Object Id
                $excludedUsers += $groupMembers.Id
            }
        }
        
        # Match user IDs to usernames
        foreach ($userId in $excludedUsers) 
        {
        $userName = (Get-MgUser -UserId $userId).UserPrincipalName
        Write-Debug $userName
        # add user to the list of excluded users for each policy
        [void]$ExclUsersList.Add($userName)
        }

        #### Match group/Id
        foreach ($groupId in $excludedGroups) 
        {
        $groupName = (Get-MgGroup -GroupId $groupId).DisplayName
        Write-Debug $groupName
        # add group to the list of excluded group for each policy
        [void]$ExclGroupsList.Add($groupName)
        }

        # Convert excluded users and groups to string format
        $objPolicy.Excluded_Users = $ExclUsersList -join ","
        $objPolicy.Excluded_Groups = $ExclGroupsList -join ","

        # Calculate the total number of excluded users
        $objPolicy.Tot_ExclUsers = ($excludedUsers).Count

        [void]$policiesInfoTable.Add($objPolicy)
    }
    
    if ($policiesInfoTable.Count -gt 0)
    {
        return $policiesInfoTable
    }

    else
    {
        $noResMessage = "Sorry, no exclusions detected"
        return $noResMessage
    }

}

# Retrieve changes to Conditional Access policies
function Get-caPolicyChanges
{
    if(!(Get-Mgcontext))
    {
        if ($runUnattended)
        {
            Connect-GraphCertificate
        }

        else 
        {
            Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All" -NoWelcome
        }
    }

    Write-Host "INFO: Looking for CA Policies changes in the last $($loginsLookupPeriod) days..." -ForegroundColor Cyan

    $caPolicyChanges = [System.Collections.ArrayList]@()

    $rawCaPolicyChanges = Get-MgAuditLogDirectoryAudit -Filter "category eq 'Policy'" -All |
    Where-Object { $_.ActivityDisplayName -match "Conditional Access" } |
    Select-Object ActivityDateTime, ActivityDisplayName, InitiatedBy, TargetResources

    $rawCaPolicyChanges | ForEach-Object {
        $caPolicyChange = [PSCustomObject]@{
            Time = $_.ActivityDateTime
            User = $_.InitiatedBy.User.UserPrincipalName
            IP_Addr = $_.InitiatedBy.User.IPAddress
            Name = $_.TargetResources.DisplayName
            Activity = $_.ActivityDisplayName
        }

        [void]$caPolicyChanges.Add($caPolicyChange)
    }

    if ($caPolicyChanges.Count -gt 0)
    {   
        return $caPolicyChanges
    }

    else
    {
        $noResMessage = "Sorry, no policy changes detected"
        return $noResMessage
    }
}

# Retrieve sign-ins where Conditional Access was not applied
function Get-LoginsNoCa {
    
    if(!(Get-Mgcontext))
    {
        if ($runUnattended)
        {
            Connect-GraphCertificate
        }

        else 
        {
            Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All" -NoWelcome
        }
    }

    $startDate = Get-Date (Get-Date).AddDays(-($loginsLogsLookupPeriod)) -format 'yyyy-MM-dd'
    $endDate = (Get-Date -format 'yyyy-MM-dd')
    $queryFilter = "status/errorCode eq 0 and conditionalAccessStatus eq 'notApplied' and AppDisplayName ne 'Windows Sign In' `
    and createdDateTime gt $StartDate and createdDateTime lt $EndDate"

    Write-Host "INFO: Retrieving the Entra Id sign-in logs for the last $($loginsLogsLookupPeriod) days.
        `nPlease wait, this process might take a while..." -ForegroundColor Cyan

    $logs = Get-MgAuditLogSignIn -Filter $queryFilter -PageSize 999 | `
        Select-Object @{Label = "Date" ; Expression = {$($_.CreatedDateTime)}}, `
            @{Label = "Username" ; Expression = {$($_.UserPrincipalName)}}, `
            @{Label = "Application" ; Expression = {$($_.AppDisplayName)}}, `
            @{Label = "Client_App" ; Expression = {$($_.ClientAppUsed)}}, `
            @{Label = "Ip_Addr" ; Expression = {$($_.IPAddress)}}, `
            @{Label = "City" ; Expression = {"$($_.Location.City)"}}, `
            @{Label = "Country" ; Expression = {$($_.Location.CountryOrRegion)}}, `
            @{Label = "CA_Status" ; Expression = {$($_.ConditionalAccessStatus)}}

    if (($logs).Count -gt 0)
    {        
        Write-SectionTitle "Logins data from the last $($loginsLookupPeriod) days"

        return $logs
    }

    else 
    {
        $noResMessage = "No results found. There have been no logins matching the criteria in the last $($loginsLookupPeriod) days."
        return $noResMessage
    }
    
}

# Analyze login logs for statistics
function Analyze-LoginLogs {

     param(
        [Parameter(Mandatory=$true)]
        $logs
    )

    Write-SectionTitle "Logins by Username"
    $logsByUser = $logs | Group-Object Username -NoElement | Sort-Object Count -Descending
    $logsByUser | Format-Table Count,@{Label = "Username" ; Expression = {$_.Name}}

    Write-SectionTitle "Logins by Application"
    $logsByApp = $logs | Group-Object Application -NoElement | Sort-Object Count -Descending 
    $logsByApp | Format-Table Count,@{Label = "Application" ; Expression = {$_.Name}}

    Write-SectionTitle "Logins by Country"
    $logsByCountry = $logs | Group-Object Country -NoElement | Sort-Object Count -Descending 
    $logsByCountry | Format-Table Count,@{Label = "Country" ; Expression = {$_.Name}} 
}

function Show-Results {
    
    param(
        [Parameter(Mandatory=$true)]
        $results,
        [Parameter(Mandatory=$true)]
        [string]$sortProperty,
        [Parameter(Mandatory=$false)]
        [switch]$showOGV = $false,
        [Parameter(Mandatory=$false)]
        [switch]$showList = $false,
        [Parameter(Mandatory=$true)]
        [string]$sectionTitle
    )

    if ($showOGV)
    {
        $results | Sort-Object $sortProperty -Descending | Out-GridView -Title $sectionTitle
    }

    if ($showList)
    {
        $results | Sort-Object $sortProperty -Descending | Format-List
    }
    else 
    {
        $results | Sort-Object $sortProperty -Descending | Format-Table -AutoSize
    }
}