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

$sdk_dir = "${HOME}\transgui_sdk"
$fpc322 = "${sdk_dir}\fpc-3.2.2"
$fpc324 = "${sdk_dir}\fpc-3.2.4-rc1"
$lazarus = "${sdk_dir}\lazarus"
$openssl = "${sdk_dir}\OpenSSL"

function FPC-Lazarus-Build-Install {
    mkdir "$sdk_dir"
    cd "$sdk_dir"

    My-Download -Uri "https://sourceforge.net/projects/freepascal/files/Win32/3.2.2/fpc-3.2.2.i386-win32.exe/download" -OutFile fpc-install.exe
    Start-Process -FilePath fpc-install.exe -Wait -ArgumentList "/sp-","/verysilent","/suppressmsgboxes","/norestart","/dir=${fpc322}"

    $env:Path = "${fpc322}\bin\i386-win32;" + $env:Path

    $fpc324_commit = 'd78e2897014a69f56a1cfb53c75335c4cc37ba0e'
    My-Download -Uri "https://gitlab.com/freepascal.org/fpc/source/-/archive/${fpc324_commit}/source-${fpc324_commit}.zip" -OutFile fpc-324-rc1.zip

    # we could use Expand-Archive but it takes an eternity and then some
    7z x fpc-324-rc1.zip

    cd "source-${fpc324_commit}"
    make all
    mkdir "$fpc324"
    make PREFIX=${fpc324} install

    $env:Path = "${fpc324}\bin\i386-win32;" + $env:Path
    fpcmkcfg -d basepath=${fpc324} -o "${fpc324}\bin\i386-win32\fpc.cfg"

    cd "$sdk_dir"
    $lazarus_commit = '4e69368d79e3801ad26a7bc7c1eda0ad3cf7dcc4'
    My-Download -Uri "https://gitlab.com/dkk089/lazarus/-/archive/${lazarus_commit}/lazarus-${lazarus_commit}.zip" -OutFile lazarus-src.zip
    7z x lazarus-src.zip

    mv lazarus-${lazarus_commit} lazarus
    cd lazarus
    make bigide
    $env:Path = "${lazarus};" + $env:Path

    My-Download -Uri "https://slproweb.com/download/Win32OpenSSL_Light-3_1_6.exe" -OutFile openssl-install.exe
    Start-Process -FilePath openssl-install.exe -Wait -ArgumentList "/sp-","/verysilent","/suppressmsgboxes","/norestart","/dir=${openssl}"
}

$repodir = Get-Location
$ErrorActionPreference = "Stop"

if (Test-Path -Path "$sdk_dir")
{
    $env:Path = "${lazarus};${fpc324}\bin\i386-win32;" + $env:Path
}
else
{
    FPC-Lazarus-Build-Install
}

cd $repodir

cd test
lazbuild --lazarusdir=${sdk_dir}\lazarus transguitest.lpi
units\transguitest.exe -a
if(!$?) { Exit $LASTEXITCODE }
cd ..

$build = git rev-list --abbrev-commit --max-count=1 HEAD
((Get-Content -path buildinfo.pas -Raw) -replace '@GIT_COMMIT@',${build}) | Set-Content -Path buildinfo.pas
lazbuild --build-mode=Release --lazarusdir=${sdk_dir}\lazarus transgui.lpi

mkdir Release
Copy-Item "units\transgui.exe" -Destination Release
Copy-Item lang Release -Recurse -Exclude '*.template'
Copy-Item "${openssl}\bin\lib*-3.dll" Release

cd Release
7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on -sse transgui.7z *
certutil -hashfile transgui.7z SHA256
