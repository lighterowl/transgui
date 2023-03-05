$repodir = Get-Location;
$ErrorActionPreference = "Stop";

mkdir C:\FPC
cd C:\FPC

Invoke-WebRequest -Uri "https://sourceforge.net/projects/freepascal/files/Win32/3.2.2/fpc-3.2.2.i386-win32.exe/download" -UserAgent Wget -MaximumRedirection 10 -OutFile fpc-install.exe
Start-Process -FilePath fpc-install.exe -Wait -ArgumentList "/sp-","/verysilent","/suppressmsgboxes","/norestart"

$env:Path = "C:\FPC\3.2.2\bin\i386-win32;" + $env:Path;

# top of fixes_3_2 at the time of writing
Invoke-WebRequest -Uri "https://gitlab.com/freepascal.org/fpc/source/-/archive/0c5256300a323c78caa0b1a9cb772ac137f5aa8e/source-0c5256300a323c78caa0b1a9cb772ac137f5aa8e.zip" -OutFile fpc-fixes.zip
# Expand-Archive takes an eternity and then some
7z x fpc-fixes.zip

cd "C:\FPC\source-0c5256300a323c78caa0b1a9cb772ac137f5aa8e"
make all
mkdir C:\FPC\3.2.3
make PREFIX=C:\FPC\3.2.3 install

$env:Path = "C:\FPC\3.2.3\bin\i386-win32;" + $env:Path;
fpcmkcfg -d basepath=C:\FPC\3.2.3 -o C:\FPC\3.2.3\bin\i386-win32\fpc.cfg

cd C:\FPC
Invoke-WebRequest -Uri "https://sourceforge.net/projects/lazarus/files/Lazarus%20Zip%20_%20GZip/Lazarus%202.2.4/lazarus-2.2.4-0.zip/download" -UserAgent Wget -MaximumRedirection 10 -OutFile lazarus-src.zip
7z x lazarus-src.zip

cd lazarus
make bigide
$env:Path = "C:\FPC\lazarus;" + $env:Path;

cd $repodir
lazbuild --lazarusdir=C:\FPC\lazarus transgui.lpi
