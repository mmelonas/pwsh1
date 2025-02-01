echo "1"
$arrPEMFiles = Gci -Path .\ -Include *.pem -Recurse

$openSSL = "C:\Program Files\Git\usr\bin\openssl.exe"

echo "2"
ForEach($file in $arrPEMFiles) {
    $fileFullPath = $file.FullName
    $fileName = $file.Name -replace ".pem",""

    #& $openSSL rsa -in $fileFullPath -out "$($fileName).key"
    & $openSSL x509 -in $fileFullPath -outform DER -out "$($fileName).crt"
}
echo "3"


#openssl rsa -in foo.pem -out your-key.key
#openssl x509 -in foo.pem -outform DER -out first-cert.crt