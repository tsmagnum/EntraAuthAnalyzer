<#
.SYNOPSIS
Securely prompts for SMTP credentials and stores them in an encrypted XML file for later use.

.DESCRIPTION
This PowerShell script, authored by Federico Lillacci, is designed to be run interactively to collect and securely store SMTP server credentials. It performs the following steps:

Credential File Check: Verifies if an encrypted credentials file (EncryptedCreds.xml) already exists in the current working directory.
User Confirmation: If the file exists, prompts the user to confirm whether they want to overwrite it.
Credential Input: Prompts the user to enter their SMTP username and password using the Get-Credential cmdlet.
Encryption and Export: Converts the secure password to an encrypted string and exports the credentials to an XML file using Export-Clixml. The credentials are encrypted using the current user's Windows Data Protection API (DPAPI), meaning only the same user on the same machine can decrypt them.
Validation and Feedback: Confirms successful storage by checking the presence of the username in the saved file and provides appropriate feedback.

This script is useful for securely storing credentials for later use in automated scripts or scheduled tasks that require SMTP authentication.
#>

#Region Credits
#Author: Federico Lillacci
#Github: https://github.com/tsmagnum
#endregion

#Run this script interactively to securely store SMTP server credentials
$credsFileName = "EncryptedCreds.xml"
$credsFile = "$(pwd)\$($credsFileName)"

#Checking if a creds file already exists
if (Test-Path -Path $credsFile)
    {   
        Write-Host -ForegroundColor Yellow "An encrypted XML file with creds already exists at this location"
        $userChoice = Read-Host `
            -Prompt "Do you want to overwrite it? Press Y and ENTER to continue, any other key to abort"

        if ($userChoice -ne "y")
    {
        exit
    }

    }

Write-Host "File not exists"

#Prompting for username and password
Write-Host -ForegroundColor Yellow "Enter the credentials you want to save"
$Credentials = Get-Credential
$Credentials.Password
$Credentials.Password | ConvertFrom-SecureString

#Exporting creds
#Please note: only the user encrypting the creds will be able to decrypt them!
Write-Host -ForegroundColor Yellow "Saving credentials to an encrypted XML file..."
Write-Host "Your cred will be stored in $credsFile"
try {
        $Credentials | Export-Clixml -Path $credsFile -Force
        if (Get-Content $credsFile | Select-String -Pattern $($Credentials.UserName))
        {
            Write-Host -ForegroundColor Green "Success - Credentials securely stored in $credsFile"
        }
        else 
        {
            throw "There was a problem saving your credentials: $_"
        }
        
}

catch 
{
    Write-Host -ForegroundColor Red "There was a problem saving your credentials: $_"
}