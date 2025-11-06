function Write-SectionTitle {
    
    param(
        [Parameter(Mandatory =$true)]
        [string]$title,
        [Parameter(Mandatory =$false)]
        [string]$color = "cyan"
        )

    $line = "═" * ($Title.Length + 4)
    Write-Host ""
    Write-Host "╔$line╗" -ForegroundColor $color
    Write-Host "║  $title  ║" -ForegroundColor $color
    Write-Host "╚$line╝" -ForegroundColor $color
    Write-Host ""
}

function Set-ResultsFile {
  
     param(
        [Parameter(Mandatory =$true)]
        [string]$resultsFileDir,
        [Parameter(Mandatory =$true)]
        [string]$resultsFileName,
        [Parameter(Mandatory =$true)]
        [string]$resultsFileExt
        )

    # Get date (logging,timestamps, etc.)
    $today = Get-Date
    $launchTime = $today.ToString('ddMMyyyy-hhmm')

    # Set the results filename
    $resultsFile = $resultsFileDir+"\$($resultsFileName)_"+"$($tenantName)_"+$launchTime+"$($resultsFileExt)"

    return $resultsFile
}

function Import-SafeCreds {
    [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $true)] $encryptedSMTPCredsFile
        )  

        $credentials = Import-Clixml -Path $encryptedSMTPCredsFile
        return $credentials
    
}

function SendEmail-Mailkit
{ 
        
        # Check if NuGet is present; if not, install it
        if (!(Get-PackageProvider -Name Nuget -ListAvailable)) 
        { 
                Write-Host -ForegroundColor Yellow "NuGet package provider missing, installing..."
                Install-PackageProvider -Name "NuGet" -Force           
        }
        
        # Check if required module is present; if not, install it
        if (!(Get-Module -ListAvailable -Name "Send-MailKitMessage")) 
        { 
                Write-Host -ForegroundColor Yellow "Send-MailKitMessage module missing, installing..."
                Install-Module -Name "Send-MailKitMessage" -Scope CurrentUser -Force           
        }
		
		Import-Module -Name "Send-MailKitMessage"
        
        $UseSecureConnectionIfAvailable = $true

        if ($encryptedSMTPCreds)
            {
                $Credentials = Import-SafeCreds -encryptedSMTPCredsFile $encryptedSMTPCredsFile
            }

        else 
            {
                $credentials = `
                        [System.Management.Automation.PSCredential]::new($smtpServerUser, `
                                (ConvertTo-SecureString -String $smtpServerPwd -AsPlainText -Force))
            }

        # Sender
        $from = [MimeKit.MailboxAddress]$emailSender
        
        # Recipient To:
        $recipientList = [MimeKit.InternetAddressList]::new()
        $recipientList.Add([MimeKit.InternetAddress]$emailRecipient)
        
        # Recipient Cc:
        if ($ccrecipient)
        {
                $ccList = [MimeKit.InternetAddressList]::new();
                $ccList.Add([MimeKit.InternetAddress]$emailCcrecipient);      
        }

        # attachment list ([System.Collections.Generic.List[string]], optional)
        $AttachmentList = [System.Collections.Generic.List[string]]::new();
        $AttachmentList.Add($excelFileResults);

        $Parameters = @{
                "UseSecureConnectionIfAvailable" = $UseSecureConnectionIfAvailable    
                "Credential" = $credentials
                "SMTPServer" = $smtpServer
                "Port" = $smtpServerPort
                "From" = $from
                "RecipientList" = $recipientList
                "CCList" = $ccList
                "Subject" = $subject
                "TextBody" = $emailBody
                "HTMLBody" = $emailBody
                "AttachmentList" = $AttachmentList
                }    

        Send-MailKitMessage @Parameters                 
}

function Write-Credits 
{
    Write-Host ""
    Write-Host "Entra Auth Analyzer vers. $($scriptVer)" -ForegroundColor Cyan
    Write-Host "The script is available at https://github.com/tsmagnum/EntraAuthAnalyzer" -ForegroundColor Green
}