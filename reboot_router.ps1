# Experimental. Not tested on real hardware by the author. Reports welcome.
#
# Reboot a Prolink PRN3002-C router through its web interface.
# Tested model: Prolink PRN3002-C only.
#
# Usage:
#   .\reboot_router.ps1 [-RouterIp <address>] [-NoWait]
#
# Configuration:
#   ROUTER_IP is read from router-reboot.env next to this script, or from
#   the -RouterIp parameter. The file uses KEY=VALUE lines.
#   Credentials are read from a DPAPI-protected file created with:
#     Get-Credential | Export-Clixml .\router-cred.xml
#   Set ROUTER_CRED_FILE to use a different path.
#
# Exit codes:
#   0  Success
#   1  Router unreachable before reboot
#   2  Router did not come back in time
#   3  Configuration error

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RouterIp,

    [Parameter()]
    [switch]$NoWait
)

$ErrorActionPreference = 'Stop'

function Write-RouterLog {
    param([string]$Message)
    Write-Output ("{0} {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message)
}

function Exit-ConfigurationError {
    param([string]$Message)
    [Console]::Error.WriteLine($Message)
    exit 3
}

$envFile = Join-Path $PSScriptRoot 'router-reboot.env'

if ([string]::IsNullOrWhiteSpace($RouterIp) -and
    (Test-Path -LiteralPath $envFile -PathType Leaf)) {
    foreach ($line in Get-Content -LiteralPath $envFile) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith('#')) {
            continue
        }
        if ($trimmed -match '^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
            $key = $Matches[1]
            $value = $Matches[2].Trim()
            if ($value.Length -ge 2) {
                if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
                    ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                    $value = $value.Substring(1, $value.Length - 2)
                }
            }
            if ($key -eq 'ROUTER_IP') {
                $RouterIp = $value
            }
        }
    }
}

if ([string]::IsNullOrWhiteSpace($RouterIp)) {
    Exit-ConfigurationError "ROUTER_IP is not set. Add ROUTER_IP=<router address> to $envFile, or pass -RouterIp."
}

$RouterIp = $RouterIp.Trim()
if ($RouterIp -match '://' -or $RouterIp -match '/') {
    Exit-ConfigurationError "ROUTER_IP must be an address or hostname only, without http:// or a path."
}

$credFile = $env:ROUTER_CRED_FILE
if ([string]::IsNullOrWhiteSpace($credFile)) {
    $credFile = Join-Path $PSScriptRoot 'router-cred.xml'
}

if (-not (Test-Path -LiteralPath $credFile -PathType Leaf)) {
    [Console]::Error.WriteLine("Credential file not found: $credFile")
    [Console]::Error.WriteLine("Create it with: Get-Credential | Export-Clixml '$credFile'")
    exit 3
}

try {
    $credential = Import-Clixml -LiteralPath $credFile
}
catch {
    Exit-ConfigurationError "Could not read the credential file: $credFile"
}

if ($null -eq $credential -or [string]::IsNullOrWhiteSpace($credential.UserName)) {
    Exit-ConfigurationError "The credential file does not contain a username and password: $credFile"
}

$password = $credential.GetNetworkCredential().Password

function Test-RouterOnline {
    Test-Connection -ComputerName $RouterIp -Count 1 -Quiet -ErrorAction SilentlyContinue
}

if (-not (Test-Connection -ComputerName $RouterIp -Count 2 -Quiet -ErrorAction SilentlyContinue)) {
    Write-RouterLog "Router $RouterIp not reachable, aborting."
    exit 1
}

$loginUrl = "http://$RouterIp/login.cgi"
$loginBody = @{
    'username' = $credential.UserName
    'password' = $password
    'submit.htm?login.htm' = 'Send'
}
$loginHeaders = @{
    'Referer' = "http://$RouterIp/login.htm"
}

Write-RouterLog "Logging in..."
try {
    Invoke-WebRequest -Uri $loginUrl -Method Post -Body $loginBody `
        -Headers $loginHeaders -UseBasicParsing -TimeoutSec 15 | Out-Null
}
catch {
    Write-RouterLog "Login request failed: $($_.Exception.Message)"
    exit 1
}

$rebootUrl = "http://$RouterIp/form2Reboot.cgi"
$rebootBody = @{
    'reboot' = 'Reboot'
    'submit.htm?reboot.htm' = 'Send'
}
$rebootHeaders = @{
    'Referer' = "http://$RouterIp/reboot.htm"
}

Write-RouterLog "Sending reboot request..."
try {
    Invoke-WebRequest -Uri $rebootUrl -Method Post -Body $rebootBody `
        -Headers $rebootHeaders -UseBasicParsing -TimeoutSec 15 | Out-Null
}
catch {
    # The router may drop the connection while it reboots.
    Write-Verbose "Reboot request ended: $($_.Exception.Message)"
}

if ($NoWait) {
    Write-RouterLog "Reboot request sent. Not waiting for the router."
    exit 0
}

Start-Sleep -Seconds 10
for ($attempt = 0; $attempt -lt 40; $attempt++) {
    if (Test-RouterOnline) {
        Write-RouterLog "Router is back online."
        exit 0
    }
    Start-Sleep -Seconds 2
}

Write-RouterLog "Router did not come back within the expected time."
exit 2
