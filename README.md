
# EntraAuthAnalyzer

**EntraAuthAnalyzer** is a PowerShell-based tool designed to audit and analyze authentication methods, Conditional Access (CA) policies, and login behaviors in Microsoft Entra ID (formerly Azure AD). It generates detailed reports and optionally exports them to Excel or sends them via email.

## Features
- Authentication Methods Audit
- Security Info Registrations
- CA Policy Exclusions
- CA Policy Changes
- Login Analysis
- Excel Export
- Email Report

## Configuration
Edit the `GlobalVariables.ps1` file to configure the script for your environment.

### Authentication
If you want to run the script unattended (e.g. using task scheduler), please
see `AppOnly-Auth.txt` and set the following values:

```powershell
$tenantId = "your-tenant-id"
$clientId = "your-client-id"
$certificateThumbprint = "your-cert-thumbprint"
$runUnattended = $true
```

### Report Options
Infos to include in the report: 

```powershell
$entraAuthMethodsReq = $true
$entraSecInfoRegReq = $true
$entraCaExclusionsReq = $true
$expandGroups = $true
$entraCaExclusionsData = "list"
$caPolicyChangesReq = $true
$entraLoginsNoCaReq = $true
$entraLoginsNoCaConsoleLimit = 100
```

### Observation Windows
```powershell
$loginsLookupPeriod = 30
$loginsLogsLookupPeriod = 3
```

### Excel Export
```powershell
$exportToExcel = $true
$tenantName = "MyTenant"
$resultsFileDir = "C:\Temp"
$resultsFileName = "Entra_Auth_Analyzer"
$resultsFileExt = ".xlsx"
```

### Email Delivery
```powershell
$sendEmail = $false
$emailSender = "mySender@domain.com"
$emailRecipient = "myrecipient@domain.com"
$emailCcrecipient = $null
$subject = "Entra Id Auth Report - $($tenantName)"
$smtpServer = "mySmtp.server.com"
$smtpServerPort = 587
$smtpAuthRequired = $true
```

Use encrypted SMTP credentials:
```powershell
$encryptedSMTPCreds = $true
$encryptedSMTPCredsFileName = "EncryptedCreds.xml"
```

Or use plain text credentials (not recommended):
```powershell
$smtpServerUser = "smtpserver.user"
$smtpServerPwd = "mySecretPwd"
```

## Usage
```powershell
git clone https://github.com/tsmagnum/EntraAuthAnalyzer.git
cd EntraAuthAnalyzer
.\EntraAuthAnalyzer.ps1
```

## Output
- Excel Workbook with multiple sheets:
  - AuthMethods
  - SecInfoReg
  - CaExclusions
  - CaPolCh
  - Logins_NoCA
- Email Report (if enabled)

## Notes
- The Excel file always contains all login records, regardless of console display limits.
- Use encrypted XML for SMTP credentials to enhance security.
- Ensure proper permissions and compliance with your organization's policies.


## 🔧 Variable Explanations
The following variables are defined in `GlobalVariables.ps1` and control script behavior:

- **$tenantId**: Azure AD tenant ID used for app-only authentication.
- **$clientId**: Client ID of the registered application in Entra ID.
- **$certificateThumbprint**: Thumbprint of the certificate used for authentication.
- **$runUnattended**: If set to $true, runs the script without user interaction.
- **$entraAuthMethodsReq**: Include authentication methods section in the report.
- **$entraSecInfoRegReq**: Include security info registration status in the report.
- **$entraCaExclusionsReq**: Include users excluded from Conditional Access policies.
- **$caPolicyChangesReq**: Include recent changes to Conditional Access policies.
- **$entraLoginsNoCaReq**: Include successful logins not covered by Conditional Access.
- **$exportToExcel**: Enable export of results to an Excel file.
- **$resultsFileDir**: Directory path where the Excel report will be saved.
- **$resultsFileName**: Base name of the Excel report file.
- **$resultsFileExt**: File extension for the report (usually .xlsx).
- **$sendEmail**: Enable sending the report via email.
- **$emailSender**: Email address used as sender.
- **$emailRecipient**: Recipient email address.
- **$smtpServer**: SMTP server used to send the email.
- **$smtpServerPort**: Port number for the SMTP server.
- **$encryptedSMTPCreds**: If true, uses encrypted credentials for SMTP.
- **$encryptedSMTPCredsFileName**: Filename of the encrypted SMTP credentials XML file.

---

## Support Script: Save-SafeCreds.ps1

To securely store SMTP credentials for email delivery, use the `Save-SafeCreds.ps1` script:

### Usage

```powershell
'powershell.exe -ExecutionPolicy Bypass -File .\Save-SafeCreds.ps1'
```

This script:
- Prompts for SMTP username and password
- Encrypts the credentials using the current user's context
- Saves them to an XML file (e.g., `EncryptedCreds.xml`)
- Ensures only the user who created the file can decrypt it

Make sure the filename matches the value of `$encryptedSMTPCredsFileName` in `GlobalVariables.ps1`.

---
