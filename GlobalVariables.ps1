# Script version – do not modify
$scriptVer = "1.0"

#region App-Only Auth
# Please set these variables to run the script unattended
# You have to configure an application in Entra and a certificate, 
# please see the instructions.
$tenantId = "xxxx"
$clientId = "yyyy"
$certificateThumbprint = "xyxyxyxy"
# Set to true to run the script unattended (mandatory if you want to run the script)
# as a scheduled task.
$runUnattended = $false
#endregion

#region Report Info
# Entra Authentication Methods
$entraAuthMethodsReq = $true

# Entra Security Info Registrations
$entraSecInfoRegReq = $true

# Entra Conditional Access (CA) Policy Exclusions
$entraCaExclusionsReq = $true
# Set to true to expand groups in CA exclusions
$expandGroups = $true
# Display format for exclusions data - Set to "list" or "table"
$entraCaExclusionsData = "list" 

# Entra Conditional Access (CA) Policy Changes
$caPolicyChangesReq = $true

# Entra logins without a CA policy
$entraLoginsNoCaReq = $true
# Display only the first XXX logins in the console output to ensure proper rendering of previous sections.
# To display all logins, set this value to $null.
# Note: The Excel file will always include all logins, regardless of the value set here.
$entraLoginsNoCaConsoleLimit = 100 # Possible values $null, 100, 300, 400, etc.
#endregion

# Observation window for Entra activities (in days)
$loginsLookupPeriod = 30
# Observation window for Entra logins (in days)
# Note: Setting a high value here may generate a large volume of logs
# and consume significant resources, especially in large tenants
$loginsLogsLookupPeriod = 3

# Excel export section
# Set to true to export data to an Excel file
$exportToExcel = $true
# Name of your tenant (used only for the filename)
$tenantName = "MyTenant"
# Directory where the file will be saved
$resultsFileDir = "C:\Temp"
# Excel report filename
$resultsFileName = "Entra_Auth_Analyzer"
# Excel report file extension – do not modify
$resultsFileExt = ".xlsx"

# Email section
# Set to true to send an email containing the Excel file
$sendEmail = $false

$emailSender = "mySender@domain.com" # "mySender@domain.com" #Sender email address (use quotes)
$emailRecipient = "myrecipient@domain.com" # "myrecipient@domain.com" #Recipient email address (use quotes)
$emailCcrecipient = $null # CC email address (use quotes); leave as $null if not used
$subject = "Entra Id Auth Report - $($tenantName)" # Email subject line
$smtpServer = "mySmtp.server.com" # "mySmtp.server.com"
$smtpServerPort = 587
$smtpAuthRequired = $true
# It is recommended to use an encrypted XML file for SMTP credentials.
# Run the Save-SafeCreds.ps1 script to store your credentials in an encrypted XML file.
# Save the encrypted XML file in the script directory.
# Set the following variable to $true and enter the path to the XML file. 
# Please note: only the user encrypting the creds will be able to decrypt them!
$encryptedSMTPCreds = $true #set to true to use the encrypted XML file for the creds.
$encryptedSMTPCredsFileName = "EncryptedCreds.xml" #name of the encrypted creds file.
# If you prefer to store the credentials in plain text, set the username and password below.
# and set $encryptedSMTPCreds to $false
#
# DO NOT USE A SENSITIVE OR PRIVILEGED ACCOUNT HERE!!!
# This poses a security risk — use these credentials only for testing purposes.
$smtpServerUser = "smtpserver.user"
$smtpServerPwd = "mySecretPwd"
