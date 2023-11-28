function Main
{
    Clear-Host
    
    Write-Host "vBoxManage VD Converter by DeAndre Queary - v0.1.0" -ForegroundColor Green
    Write-Host "Current Location: $PWD"
    Write-Host "-----------------------------------------------------------------------------------"

    if ($null -eq (Get-Command "vBoxManage.exe" -ErrorAction SilentlyContinue)) {    
        Write-Host "vBoxManage wasn't found or is not executable." -ForegroundColor Red
        Write-Host "Please add virtualbox installation folder to your system path." -ForegroundColor DarkRed
        EXIT
    }

    $NewUUID = $null

    # ------------------------------------------------ #

    # Get user input.
    Write-Host "Enter virtual disk file you wish to convert." -ForegroundColor Cyan
    Write-Host "You can put file path or VirtualBox virtual machine name for OVF/OVA."
    do {
        $InputFile = Read-Host "[Enter path or name]"
    } while ($InputFile -eq "")

    Write-Host "Convert File - "$InputFile -ForegroundColor Yellow

    Write-Host "---------------------"

    Write-Host "Select which type of disk you want to convert to." -ForegroundColor Cyan
    Write-Host "1 - VDI"
    Write-Host "2 - VMDK"
    Write-Host "3 - VHD"
    Write-Host "4 - OVF"
    Write-Host "5 - OVA"
    do {
        $OutputFormat = Read-Host "[Enter number]"
    } while ($OutputFormat -lt 1 -or $OutputFormat -gt 5)

    if ($OutputFormat -eq 1) { $OutputFormat = "vdi" }
    if ($OutputFormat -eq 2) { $OutputFormat = "vmdk" }
    if ($OutputFormat -eq 3) { $OutputFormat = "vhd" }
    if ($OutputFormat -eq 4) { $OutputFormat = "ovf" }
    if ($OutputFormat -eq 5) { $OutputFormat = "ova" }
    
    Write-Host "Convert To - "$OutputFormat -ForegroundColor Yellow

    Write-Host "---------------------"

    Write-Host "Enter output filename without extension." -ForegroundColor Cyan
    do {
        $OutputFilename = Read-Host "[Enter filename]"
    } while ($OutputFilename -eq "")

    Write-Host "Output Filename - $OutputFilename.$OutputFormat" -ForegroundColor Yellow

    Write-Host "---------------------"

    if ($OutputFormat -ne "ovf" -and $OutputFormat -ne "ova") {
        Write-Host "Generate new UUID?" -ForegroundColor Cyan
        do {
            $NewUUID = Read-Host "[yes* (y) / no (n)]"
        } while ($NewUUID -ne "" -and $NewUUID -ne "y" -and $NewUUID -ne "yes" -and $NewUUID -ne "y" -and $NewUUID -ne "yes")

        if ($NewUUID -eq "") {
            $NewUUID = "yes"
        }

        Write-Host "Generate New UUID - $NewUUID" -ForegroundColor Yellow

        Write-Host "---------------------"        
    }

    Write-Host "Add additional arguments?" -ForegroundColor Cyan
    $Arguments = Read-Host "[Enter arguments]"

    Write-Host "Arguments - "$Arguments -ForegroundColor Yellow

    Write-Host "---------------------"

    Write-Host "Confirm conversion." -ForegroundColor Cyan
    Write-Host "Convert: $InputFile"
    Write-Host "To: "$OutputFilename".$OutputFormat"
    Write-Host
    do {
        $Confirm = Read-Host "[no (n) / yes (y)]"
    } while ($Confirm -ne "n" -and $Confirm -ne "no" -and $Confirm -ne "y" -and $Confirm -ne "yes")

    # ------------------------------------------------ #

    if ($Confirm -eq "n" -or $Confirm -eq "no") {
        Write-Host
        Write-Host "Canceled..." -ForegroundColor DarkRed
        Pause
    } else {
        Invoke-Conversion -InputFile $InputFile -OutputFilename $OutputFilename -OutputFormat $OutputFormat -Arguments $Arguments -NewUUID $NewUUID
    }

    Main
}

function Invoke-Conversion
{
    param (
        $InputFile,
        $OutputFilename,
        $OutputFormat,
        $Arguments,
        $NewUUID
    )

    $InputFile = Trim-String $InputFile
    $OutputFilename = Trim-String "$OutputFilename.$OutputFormat"

    if ($OutputFormat -eq "ovf" -or $OutputFormat -eq "ova") {
        $Run = "vboxmanage export $InputFile --output $OutputFilename $Arguments"
    } else {
        $Run = "vboxmanage clonehd $InputFile $OutputFilename --format $OutputFormat $Arguments"
    }

    Write-Host
    Write-Host "Converting virtual disk..." -ForegroundColor Cyan
    Start-Sleep 2

    Invoke-Expression $Run

    if ($LASTEXITCODE -ne 0) {
        Pause
    }

    if(($NewUUID -eq "" -or $NewUUID -eq "y" -or $NewUUID -eq "yes") -and $OutputFormat -ne "ovf" -and $OutputFormat -ne "ova") {
        Write-Host
        Write-Host "Changing UUID..." -ForegroundColor Cyan
        Start-Sleep 2

        $Run = "vboxmanage internalcommands sethduuid $OutputFilename"
        Invoke-Expression $Run
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Host
        Write-Host "There was an error changing UUID. See above output for details." -ForegroundColor Red
        Pause
    }

    Write-Host
    Write-Host "DONE" -ForegroundColor Green
    Pause
}

function Trim-String
{
    param (
        $String
    )

    $String = $String.Trim("'")
    $String = $String.Trim('"')
    $String = "'$String'".Split(" ")

    Return $String
}

Main