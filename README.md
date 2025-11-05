# EntraAuthAnalyzer

**EntraAuthAnalyzer** is a PowerShell-based reporting tool designed to audit and analyze authentication methods, MFA status, Conditional Access (CA) policies, and login behaviors within Microsoft Entra ID (formerly Azure AD). It provides detailed insights and optionally exports results to Excel for further analysis or reporting.

## 📌 Features

- 🔐 **Authentication Methods Audit**: Lists users' authentication methods and MFA status.
- 📋 **Security Info Registrations**: Reports on users' registered security information.
- 🚫 **CA Policy Exclusions**: Identifies users excluded from Conditional Access policies.
- 🔄 **CA Policy Changes**: Tracks recent changes to CA policies.
- 📈 **Login Analysis**: Highlights successful logins not covered by CA policies and provides login statistics.
- 📤 **Excel Export**: Outputs all results to a structured Excel file using the `ImportExcel` module.
- 📧 **Email Report**: Optionally sends the report via email using encrypted SMTP credentials.

## ⚙️ Requirements

- PowerShell 5.1 or later
- `ImportExcel` module (auto-installed if missing)
- Access to Microsoft Graph or Entra ID APIs (depending on implementation of imported functions)
- SMTP credentials (if email functionality is enabled)

## 📁 File Structure

```
EntraAuthAnalyzer/
├── EntraAuthAnalyzer.ps1         # Main script
├── GlobalVariables.ps1           # Configuration and global variables
├── Functions.ps1                 # Core functions
├── SupportFunctions.ps1          # Utility functions
└── README.md                     # This file
```

## 🚀 Usage

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/EntraAuthAnalyzer.git
   cd EntraAuthAnalyzer
   ```

2. Configure `GlobalVariables.ps1` with your tenant-specific settings.

3. Run the script:
   ```powershell
   .\EntraAuthAnalyzer.ps1
   ```

4. (Optional) Enable Excel export and email sending by setting:
   ```powershell
   $exportToExcel = $true
   $sendEmail = $true
   ```

## 📊 Output

- Excel file with multiple worksheets:
  - `AuthMethods`
  - `SecInfoReg`
  - `CaExclusions`
  - `CaPolCh`
  - `Logins_NoCA`

## 📬 Email Report

If enabled, the script sends a summary email with the Excel report attached. SMTP credentials must be stored in an encrypted file as defined in your configuration.

## 🛡️ Disclaimer

This tool is provided as-is. Ensure you have appropriate permissions and comply with your organization's security policies before running it.
