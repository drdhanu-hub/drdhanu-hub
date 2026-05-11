$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$port = 8091
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)
$listener.Start()

Write-Host "Smart Parking LAN server running on port $port"

function Get-ContentType([string]$path) {
  switch ([IO.Path]::GetExtension($path).ToLowerInvariant()) {
    ".html" { return "text/html; charset=utf-8" }
    ".css" { return "text/css; charset=utf-8" }
    ".js" { return "text/javascript; charset=utf-8" }
    ".json" { return "application/json; charset=utf-8" }
    ".png" { return "image/png" }
    ".jpg" { return "image/jpeg" }
    ".jpeg" { return "image/jpeg" }
    ".svg" { return "image/svg+xml" }
    default { return "application/octet-stream" }
  }
}

try {
  while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
      $stream = $client.GetStream()
      $reader = [System.IO.StreamReader]::new($stream)
      $requestLine = $reader.ReadLine()
      if ([string]::IsNullOrWhiteSpace($requestLine)) { continue }

      while ($true) {
        $headerLine = $reader.ReadLine()
        if ([string]::IsNullOrEmpty($headerLine)) { break }
      }

      $parts = $requestLine.Split(" ")
      $relative = if ($parts.Length -ge 2) { $parts[1].TrimStart("/") } else { "" }
      if ([string]::IsNullOrWhiteSpace($relative)) { $relative = "index.html" }
      $relative = ($relative -split "\?")[0] -replace "/", "\"
      $file = Join-Path $root $relative

      if (Test-Path $file -PathType Leaf) {
        $bytes = [IO.File]::ReadAllBytes($file)
        $headers = @(
          "HTTP/1.1 200 OK",
          "Content-Type: $(Get-ContentType $file)",
          "Content-Length: $($bytes.Length)",
          "Connection: close",
          "",
          ""
        ) -join "`r`n"
        $headerBytes = [Text.Encoding]::ASCII.GetBytes($headers)
        $stream.Write($headerBytes, 0, $headerBytes.Length)
        $stream.Write($bytes, 0, $bytes.Length)
      }
      else {
        $body = [Text.Encoding]::UTF8.GetBytes("Not found")
        $headers = @(
          "HTTP/1.1 404 Not Found",
          "Content-Type: text/plain; charset=utf-8",
          "Content-Length: $($body.Length)",
          "Connection: close",
          "",
          ""
        ) -join "`r`n"
        $headerBytes = [Text.Encoding]::ASCII.GetBytes($headers)
        $stream.Write($headerBytes, 0, $headerBytes.Length)
        $stream.Write($body, 0, $body.Length)
      }

      $stream.Flush()
    }
    finally {
      $client.Close()
    }
  }
}
finally {
  $listener.Stop()
}
