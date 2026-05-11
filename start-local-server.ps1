$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$port = 8090
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)

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

function Send-Response($stream, $statusCode, $statusText, $contentType, [byte[]]$body) {
  $header = "HTTP/1.1 $statusCode $statusText`r`nContent-Type: $contentType`r`nContent-Length: $($body.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"
  $headerBytes = [Text.Encoding]::ASCII.GetBytes($header)
  $stream.Write($headerBytes, 0, $headerBytes.Length)
  if ($body.Length -gt 0) {
    $stream.Write($body, 0, $body.Length)
  }
  $stream.Flush()
}

$listener.Start()
Write-Host "Smart Parking website running at http://127.0.0.1:$port"

try {
  while ($true) {
    $client = $listener.AcceptTcpClient()

    try {
      $stream = $client.GetStream()
      $reader = New-Object System.IO.StreamReader($stream, [Text.Encoding]::ASCII, $false, 4096, $true)
      $requestLine = $reader.ReadLine()

      if ([string]::IsNullOrWhiteSpace($requestLine)) {
        Send-Response $stream 400 "Bad Request" "text/plain; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes("Bad Request"))
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
        Send-Response $stream 405 "Method Not Allowed" "text/plain; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes("Method Not Allowed"))
        continue
      }

      $uri = [Uri]("http://localhost$rawPath")
      $relative = $uri.AbsolutePath.TrimStart("/")
      if ([string]::IsNullOrWhiteSpace($relative)) {
        $relative = "index.html"
      }

      $relative = $relative -replace "/", "\"
      $filePath = Join-Path $root $relative

      if (Test-Path $filePath -PathType Leaf) {
        $bytes = [IO.File]::ReadAllBytes($filePath)
        Send-Response $stream 200 "OK" (Get-ContentType $filePath) $bytes
      } else {
        Send-Response $stream 404 "Not Found" "text/plain; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes("Not found"))
      }
    } catch {
      try {
        $message = [Text.Encoding]::UTF8.GetBytes("Internal Server Error")
        Send-Response $stream 500 "Internal Server Error" "text/plain; charset=utf-8" $message
      } catch {
      }
    } finally {
      $client.Close()
    }
  }
} finally {
  $listener.Stop()
}
