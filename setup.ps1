$citadelo_path = "C:\Program Files\citadelo"
$bundle_path = "$citadelo_path\burp-bundle"
$burp_path = "C:\Users\USR\AppData\Roaming\BurpSuite"
$ErrorActionPreference = "Stop"

echo "Asking for domain credentials"
$cred = Get-Credential -UserName "domain\user" -Message "Enter your VDI credentials to continue in the domain\user format."
$user=$cred.username.split("\")[1]

if (!(Test-Path $citadelo_path)) {
    echo "Setting up citadelo dir..."
    mkdir $citadelo_path | Out-Null
}
cd $citadelo_path
echo "Extracting..."
Expand-Archive "C:\Users\$user\Downloads\burp-bundle.zip" -DestinationPath .\ -Force

echo "Starting BurpSuite installer..."
Start-Process "$citadelo_path.\burpsuite_pro.exe" -NoNewWindow -Wait
$burp_support = $burp_path.replace("USR", "support")
$burp_regular = $burp_path.replace("USR", $user)
if (!(Test-Path $burp_support)) {
    mkdir $burp_support | Out-Null
}
if (!(Test-Path $burp_regular)) {
    mkdir $burp_regular | Out-Null
}
rm $bundle_path\burpsuite_pro.exe
cd $bundle_path

echo "Copy config file..."
cp .\UserConfigPro.json $burp_regular\ -Force
cp .\UserConfigPro.json $burp_support\ -Force
rm .\UserConfigPro.json

echo "Copy Jython..."
Move-Item -Path .\jython-standalone.jar -Destination $citadelo_path\

echo "Copy BAPPs..."
mkdir $burp_regular\bapps\ | Out-Null
cp .\* $burp_regular\bapps\ -Recurse -Force
mkdir $burp_support\bapps\ | Out-Null
cp .\* $burp_support\bapps\ -Recurse -Force

echo "Set permissions..."
icacls $citadelo_path /inheritancelevel:e /q /c /t /grant Users:F
echo "All done!"