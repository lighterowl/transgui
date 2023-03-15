function My-Download {
    param ([string]$Uri, [string]$OutFile)
    $webRequestParams = @{
        Uri = $Uri
        UserAgent = "Wget"
        MaximumRedirection = 10
        OutFile = $OutFile
    }
    if ( $PSVersionTable.PSVersion.Major -ge 7 )
    {
        $webRequestParams['MaximumRetryCount'] = 5;
    }
    Invoke-WebRequest @webRequestParams
}

function FPC-Lazarus-Build-Install {
    mkdir C:\FPC
    cd C:\FPC

    My-Download -Uri "https://sourceforge.net/projects/freepascal/files/Win32/3.2.2/fpc-3.2.2.i386-win32.exe/download" -OutFile fpc-install.exe
    Start-Process -FilePath fpc-install.exe -Wait -ArgumentList "/sp-","/verysilent","/suppressmsgboxes","/norestart"

    $env:Path = "C:\FPC\3.2.2\bin\i386-win32;" + $env:Path

    # top of fixes_3_2 at the time of writing
    $fpc323_commit = '0c5256300a323c78caa0b1a9cb772ac137f5aa8e'
    My-Download -Uri "https://gitlab.com/freepascal.org/fpc/source/-/archive/${fpc323_commit}/source-${fpc323_commit}.zip" -OutFile fpc-fixes.zip

    # we could use Expand-Archive but it takes an eternity and then some
    7z x fpc-fixes.zip

    cd "C:\FPC\source-${fpc323_commit}"
    make all
    mkdir C:\FPC\3.2.3
    make PREFIX=C:\FPC\3.2.3 install

    $env:Path = "C:\FPC\3.2.3\bin\i386-win32;" + $env:Path
    fpcmkcfg -d basepath=C:\FPC\3.2.3 -o C:\FPC\3.2.3\bin\i386-win32\fpc.cfg

    cd C:\FPC
    My-Download -Uri "https://sourceforge.net/projects/lazarus/files/Lazarus%20Zip%20_%20GZip/Lazarus%202.2.6/lazarus-2.2.6-0.zip/download" -OutFile lazarus-src.zip
    7z x lazarus-src.zip

    cd lazarus
    make bigide
    $env:Path = "C:\FPC\lazarus;" + $env:Path

    My-Download -Uri "https://slproweb.com/download/Win32OpenSSL_Light-3_1_0.exe" -OutFile openssl-install.exe
    Start-Process -FilePath openssl-install.exe -Wait -ArgumentList "/sp-","/verysilent","/suppressmsgboxes","/norestart","/dir=C:\OpenSSL"
}

$repodir = Get-Location
$ErrorActionPreference = "Stop"

if ((Test-Path -Path "C:\FPC\3.2.3") -and (Test-Path -Path "C:\FPC\lazarus") -and (Test-Path -Path "C:\OpenSSL"))
{
    $env:Path = "C:\FPC\lazarus;C:\FPC\3.2.3\bin\i386-win32;" + $env:Path
}
else
{
    FPC-Lazarus-Build-Install
}

cd $repodir
lazbuild --build-mode=Release --lazarusdir=C:\FPC\lazarus transgui.lpi

mkdir Release
Copy-Item "units\transgui.exe" -Destination Release
Copy-Item lang Release -Recurse -Exclude '*.template'
Copy-Item "C:\OpenSSL\bin\lib*-3.dll" Release

cd Release
7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on -sse transgui.7z *
certutil -hashfile transgui.7z SHA256
