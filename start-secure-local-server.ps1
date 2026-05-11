$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$port = 8446
$certPath = Join-Path $root "certs\smartparking-local.p12"
$certPassword = "changeit"
$logPath = Join-Path $root "https-server.log"

if (-not (Test-Path $certPath -PathType Leaf)) {
  throw "HTTPS certificate not found at $certPath"
}

$certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
  $certPath,
  $certPassword,
  ([System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable -bor
   [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet -bor
   [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet)
)

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)
$listener.Start()

Write-Host "Smart Parking secure website running at https://localhost:$port"
Write-Host "LAN test link: https://10.14.29.30:$port"

function Write-Log($message) {
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Add-Content -LiteralPath $logPath -Value "[$timestamp] $message"
}

function Get-ContentType($filePath) {
  switch ([IO.Path]::GetExtension($filePath).ToLowerInvariant()) {
    ".html" { return "text/html; charset=utf-8" }
    ".css" { return "text/css; charset=utf-8" }
    ".js" { return "text/javascript; charset=utf-8" }
    ".json" { return "application/json; charset=utf-8" }
    ".png" { return "image/png" }
    ".jpg" { return "image/jpeg" }
    ".jpeg" { return "image/jpeg" }
    ".svg" { return "image/svg+xml" }
    ".ico" { return "image/x-icon" }
    default { return "application/octet-stream" }
  }
}

function Send-Response($sslStream, $statusCode, $statusText, $contentType, [byte[]]$body) {
  $header = "HTTP/1.1 $statusCode $statusText`r`nContent-Type: $contentType`r`nContent-Length: $($body.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"
  $headerBytes = [Text.Encoding]::ASCII.GetBytes($header)
  $sslStream.Write($headerBytes, 0, $headerBytes.Length)
  if ($body.Length -gt 0) {
    $sslStream.Write($body, 0, $body.Length)
  }
  $sslStream.Flush()
}

try {
  while ($true) {
    $client = $listener.AcceptTcpClient()

    try {
      $networkStream = $client.GetStream()
      $sslStream = New-Object System.Net.Security.SslStream($networkStream, $false)
      $sslStream.AuthenticateAsServer(
        $certificate,
        $false,
        ([System.Security.Authentication.SslProtocols]::Tls -bor
         [System.Security.Authentication.SslProtocols]::Tls11 -bor
         [System.Security.Authentication.SslProtocols]::Tls12),
        $false
      )

      $reader = New-Object System.IO.StreamReader($sslStream, [Text.Encoding]::ASCII, $false, 4096, $true)
      $requestLine = $reader.ReadLine()

      if ([string]::IsNullOrWhiteSpace($requestLine)) {
        Send-Response $sslStream 400 "Bad Request" "text/plain; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes("Bad Request"))
        continue
      }

      $parts = $requestLine.Split(" ")
      $method = $parts[0]
      $rawPath = if ($parts.Length -gt 1) { $parts[1] } else { "/" }

      while ($true) {
        $line = $reader.ReadLine()
        if ([string]::IsNullOrEmpty($line)) { break }
      }

      if ($method -ne "GET") {
        Send-Response $sslStream 405 "Method Not Allowed" "text/plain; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes("Method Not Allowed"))
        continue
      }

      $uri = [Uri]("https://localhost$rawPath")
      $relative = $uri.AbsolutePath.TrimStart("/")
      if ([string]::IsNullOrWhiteSpace($relative)) {
        $relative = "index.html"
      }

      $relative = $relative -replace "/", "\"
      $filePath = Join-Path $root $relative

      if (Test-Path $filePath -PathType Leaf) {
        $bytes = [IO.File]::ReadAllBytes($filePath)
        Send-Response $sslStream 200 "OK" (Get-ContentType $filePath) $bytes
      }
      else {
        Send-Response $sslStream 404 "Not Found" "text/plain; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes("Not found"))
      }
    }
    catch {
      Write-Log $_.Exception.ToString()
      try {
        $fallbackStream = $client.GetStream()
        $message = [Text.Encoding]::UTF8.GetBytes("Internal Server Error")
        $header = "HTTP/1.1 500 Internal Server Error`r`nContent-Type: text/plain; charset=utf-8`r`nContent-Length: $($message.Length)`r`nConnection: close`r`n`r`n"
        $headerBytes = [Text.Encoding]::ASCII.GetBytes($header)
        $fallbackStream.Write($headerBytes, 0, $headerBytes.Length)
        $fallbackStream.Write($message, 0, $message.Length)
        $fallbackStream.Flush()
      }
      catch {
      }
    }
    finally {
      $client.Close()
    }
  }
}
finally {
  $listener.Stop()
}
