$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$port = 8443

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("https://localhost:$port/")
$listener.Prefixes.Add("https://127.0.0.1:$port/")
$listener.Prefixes.Add("https://10.14.29.30:$port/")
$listener.Start()

Write-Host "Smart Parking website running at https://localhost:$port"
Write-Host "LAN test link: https://10.14.29.30:$port"

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()

    try {
      $relative = $context.Request.Url.AbsolutePath.TrimStart("/")
      if ([string]::IsNullOrWhiteSpace($relative)) {
        $relative = "index.html"
      }

      $relative = $relative -replace "/", "\"
      $file = Join-Path $root $relative

      if (Test-Path $file -PathType Leaf) {
        $extension = [IO.Path]::GetExtension($file).ToLowerInvariant()
        $contentType = switch ($extension) {
          ".html" { "text/html; charset=utf-8" }
          ".css"  { "text/css; charset=utf-8" }
          ".js"   { "text/javascript; charset=utf-8" }
          ".json" { "application/json; charset=utf-8" }
          ".png"  { "image/png" }
          ".jpg"  { "image/jpeg" }
          ".jpeg" { "image/jpeg" }
          ".svg"  { "image/svg+xml" }
          default { "application/octet-stream" }
        }

        $bytes = [IO.File]::ReadAllBytes($file)
        $context.Response.StatusCode = 200
        $context.Response.ContentType = $contentType
        $context.Response.ContentLength64 = $bytes.Length
        $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      }
      else {
        $body = [Text.Encoding]::UTF8.GetBytes("Not found")
        $context.Response.StatusCode = 404
        $context.Response.ContentType = "text/plain; charset=utf-8"
        $context.Response.ContentLength64 = $body.Length
        $context.Response.OutputStream.Write($body, 0, $body.Length)
      }
    }
    finally {
      $context.Response.OutputStream.Close()
    }
  }
}
finally {
  $listener.Stop()
  $listener.Close()
}
