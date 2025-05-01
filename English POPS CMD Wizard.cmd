@echo off

setlocal enabledelayedexpansion
set "hora_actual=%time:~0,5%"
set "hora_actual=%hora_actual::=.%"
set "ruta_inicial=%cd%"
set "fecha=!date!"
set "fecha=!fecha:/=-!"
set "carpeta_backup_cmd=Backup !fecha! !hora_actual!\"
set "cmd_ruta=!ruta_inicial:~0,2!"

echo "________          ________      _________              ";
echo "___  __ )____  __ ___  __ \___________  /____________ _";
echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
echo "        /____/                                         ";

echo " ___  ____  ___  ___    __ ";
echo "/ __)(_  _)(  _)(  ,\  (  )";
echo "\__ \  )(   ) _) ) _/   )( ";
echo "(___/ (__) (___)(_)    (__)";

echo.
echo Step 1 Detection of necessary files to run POPS or PS1
REM Detect USB devices with assigned drive letters and their labels
echo Detecting USB devices with assigned drive letters...
set index=0
for /f "tokens=1,2 delims=," %%A in ('powershell -Command "Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 } | Select-Object DeviceID, VolumeName | ForEach-Object { $_.DeviceID + ',' + $_.VolumeName }"') do (
    set /a index+=1
    set "device[!index!]=%%A"
    echo !index!. %%A - %%B
)

REM Ask the user which device to select
echo.
set /p choice=Select the number of the USB device: 

REM Validate the user's selection
if "!device[%choice%]!"=="" (
    echo Invalid option. Exiting...
    pause
    exit /b
)

REM Selected path
set ruta=!device[%choice%]!
echo.
echo Selected path: %ruta%\

REM Initialize variables to check for files
set faltaPOPS_IOX=0
set faltaPOPSTARTER=0
set faltaTROJAN=0
set archivosValidos=1
set archivosPendriveValidos=1
set reemplazarTROJAN=0

REM Check if the /POPS/ folder exists
if exist "%ruta%\POPS\" (
    echo The /POPS/ folder exists in the selected path.
    echo Verifying files...

    REM Check if POPS_IOX.PAK exists
    if exist "%ruta%\POPS/POPS_IOX.PAK" (
        echo Verifying MD5 of POPS_IOX.PAK...
        for /f "tokens=*" %%A in ('CertUtil -hashfile "%ruta%\POPS/POPS_IOX.PAK" MD5 ^| find /i /v "hash"') do set hashCalculado1=%%A
        set "hashCalculado1=!hashCalculado1: =!"
        if /i "!hashCalculado1!"=="a625d0b3036823cdbf04a3c0e1648901" (
            echo POPS_IOX.PAK is valid.
        ) else (
            echo POPS_IOX.PAK is corrupt or not the correct one.
            set faltaPOPS_IOX=1
            set archivosPendriveValidos=0
        )
    ) else (
        echo POPS_IOX.PAK is missing from the USB drive.
        set faltaPOPS_IOX=1
        set archivosPendriveValidos=0
    )

    REM Check if POPSTARTER.ELF exists
    if exist "%ruta%\POPS\POPSTARTER.ELF" (
        echo Verifying MD5 of POPSTARTER.ELF...
        for /f "tokens=*" %%A in ('CertUtil -hashfile "%ruta%\POPS/POPSTARTER.ELF" MD5 ^| find /i /v "hash"') do set hashCalculado2=%%A
        set "hashCalculado2=!hashCalculado2: =!"
        if /i "!hashCalculado2!"=="4a39d44dfb477ea747f5ca5e39ee011e" (
            echo POPSTARTER.ELF is valid.
        ) else (
            echo POPSTARTER.ELF is corrupt or not the latest version.
            set faltaPOPSTARTER=1
            set archivosPendriveValidos=0
        )
        if not exist "!ruta_inicial!\POPSTARTER.ELF" (
                    echo Saving POPSTARTER.ELF to the CMD folder for future changes...
                    copy "%ruta%\POPS\POPSTARTER.ELF" "%ruta_inicial%\POPSTARTER.ELF"
                )
    ) else (
        echo POPSTARTER.ELF is missing from the USB drive.
        set faltaPOPSTARTER=1
        set archivosPendriveValidos=0
    )

    REM Check if TROJAN_7.BIN exists
    if exist "%ruta%\POPS/TROJAN_7.BIN" (
        echo TROJAN_7.BIN found on the USB drive.
        echo Verifying MD5 of TROJAN_7.BIN...
        for /f "tokens=*" %%A in ('CertUtil -hashfile "%ruta%\POPS/TROJAN_7.BIN" MD5 ^| find /i /v "hash"') do set hashCalculadoTrojan=%%A
        set "hashCalculadoTrojan=!hashCalculadoTrojan: =!"
        if /i "!hashCalculadoTrojan!"=="25f6bd59559b25b60881a92353bf0e9f" (
            echo TROJAN_7.BIN is the latest R7 modified by hugopocked.
        ) else if /i "!hashCalculadoTrojan!"=="7bbcb73e5f2e068d735573e62c80bd08" (
            echo TROJAN_7.BIN is the R7 taken from elotrolado.
        ) else if /i "!hashCalculadoTrojan!"=="ca48a3e90d10866361faf008656c25b2" (
            echo TROJAN_7.BIN is the R6 version taken from ps2-home.
        ) else (
            echo TROJAN_7.BIN has an unknown MD5. The recommended versions are the ones mentioned above.
        )

        echo.
        echo I clarify that I don't know which version is correct or better, but these are the 3 versions I found:
        echo - MD5: 25f6bd59559b25b60881a92353bf0e9f - Latest R7 modified by hugopocked -Year-2024-
        echo - MD5: 7bbcb73e5f2e068d735573e62c80bd08 - R7 taken from elotrolado -Year-2021-
        echo - MD5: ca48a3e90d10866361faf008656c25b2 - R6 Taken from ps2-home -Year-2020-
        echo.

        set hashPendriveTrojan=!hashCalculadoTrojan!
    ) else (
        echo The file TROJAN_7.BIN is missing. It is optional, although recommended as it solves problems in several games.
        echo.
        echo I clarify that I don't know which version is correct or better, but these are the 3 versions I found:
        echo - MD5: 25f6bd59559b25b60881a92353bf0e9f - Latest R7 modified by hugopocked -Year-2024-
        echo - MD5: 7bbcb73e5f2e068d735573e62c80bd08 - R7 taken from elotrolado -Year-2021-
        echo - MD5: ca48a3e90d10866361faf008656c25b2 - R6 Taken from ps2-home -Year-2020-
        echo.
        set faltaTROJAN=1
    )
) else (
    echo The /POPS/ folder does not exist in the selected path.
    set faltaPOPS_IOX=1
    set faltaPOPSTARTER=1
    set faltaTROJAN=1
    set archivosPendriveValidos=0
)

echo Verification of files on the USB drive completed.
pause
cls

echo "________          ________      _________              ";
echo "___  __ )____  __ ___  __ \___________  /____________ _";
echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
echo "        /____/                                         ";

echo " ___  ____  ___  ___    ___ ";
echo "/ __)(_  _)(  _)(  ,\  (__ \";
echo "\__ \  )(   ) _) ) _/  / __/";
echo "(___/ (__) (___)(_)    \___)";

echo Step 2 Copying necessary files to run POPS or PS1
echo Verifying files in the CMD folder...

@echo off
setlocal enabledelayedexpansion

:: Check if POPSTARTER.ELF exists
if exist "%ruta_inicial%\POPSTARTER.ELF" (
    echo POPSTARTER.ELF is present in the CMD path.
) else if exist "%ruta%/POPS/POPSTARTER.ELF" (
    echo POPSTARTER.ELF is located on the USB drive.
) else (
    set "hash_objetivo=4a39d44dfb477ea747f5ca5e39ee011e"
    set "archivo_encontrado="
    set "ultimo_archivo="
    echo Searching for POPSTARTER files in %ruta_pendrive% and its subdirectories...
    for /r "%ruta%\" %%F in (XX.*.ELF) do (
        echo Verifying file: %%F
        set "ultimo_archivo=%%F"
        for /f "tokens=*" %%H in ('CertUtil -hashfile "%%F" MD5 ^| find /i /v "hash"') do set "hash_actual=%%H"
            set "!hash_actual=!hash_actual: =!"
            if /i "!hash_actual!"=="!hash_objetivo%!" (
                echo File with target hash found: %%F
                set "archivo_encontrado=%%F"
                if defined archivo_encontrado (
                    echo Copying !archivo_encontrado! to %ruta_inicial%\POPSTARTER.ELF...
                    copy "!archivo_encontrado!" "%ruta_inicial%\POPSTARTER.ELF" >nul
                    if %errorlevel%==0 (
                        echo File copied successfully.
                    ) else (
                        echo Error copying the file.
                    )
                    goto :FINISH_POPSI_SEARCH
                ) else (
                    echo No file found to copy.
                )
            )
    )

    :: If no file with the target hash was found, use the last found file
    if defined ultimo_archivo (
        echo No file with the target hash found. Using the last found file: !ultimo_archivo!
        set "archivo_encontrado=!ultimo_archivo!"
            if defined archivo_encontrado (
            echo Copying !archivo_encontrado! to %ruta_inicial%\POPSTARTER.ELF...
            copy "!archivo_encontrado!" "%ruta_inicial%\POPSTARTER.ELF" >nul
            if %errorlevel%==0 (
                    echo File copied successfully.
                ) else (
                    echo Error copying the file.
                )
            ) else (
                echo No file found to copy.
            )
            goto :FINISH_POPSI_SEARCH
    ) else (
        echo No XX.*.ELF files found in %ruta%\.
        pause
        exit /b
    )
)

:FINISH_POPSI_SEARCH

:: Check if POPS_IOX.PAK exists
if exist "%ruta_inicial%\POPS_IOX.PAK" (
    echo POPS_IOX.PAK is present in the CMD path.
) else (
    echo POPS_IOX.PAK is not found in the CMD path.
)

pause

REM Final messages and copying of mandatory files
if "!archivosPendriveValidos!"=="1" (
    echo All necessary files are correct on the USB drive. No need to copy them.
) else if "!archivosPendriveValidos!"=="0" (
    echo To run POPS correctly, some files located in the CMD folder are needed.
    set /p copiar=Do you want to copy them to the USB drive? Y/N: 
    if /i "!copiar!"=="Y" (
        REM Create the /POPS/ folder only if it doesn't exist
        if not exist "%ruta%\POPS\" (
            echo Creating /POPS/ folder on the USB drive...
            mkdir "%ruta%\POPS"
        )
        if "!faltaPOPS_IOX!"=="1" (
            echo Copying POPS_IOX.PAK...
            copy "POPS_IOX.PAK" "%ruta%\POPS"
        )
        if "!faltaPOPSTARTER!"=="1" (
            echo Copying POPSTARTER.ELF...
            copy "POPSTARTER.ELF" "%ruta%\POPS"
        )
        echo Files copied successfully.
    )
) else (
    echo Necessary files to run POPS or PS1 are missing in the CMD path.
    echo Download and extract them into the executable's folder.
    echo The program will install them where necessary.
    echo.
    if not exist "POPSTARTER.ELF" (
        echo POPSTARTER.ELF does not exist in the executable's folder
        echo To download POPSTARTER.ELF
        echo Go to this link
        echo https://www.ps2-home.com/forum/viewtopic.php?f=19&t=1819
        echo.
    )
    if not exist "POPS_IOX.PAK" (
        echo To download POPS_IOX.PAK
        echo Search the internet, it's illegal to put it here in the launcher
        echo Its MD5 is a625d0b3036823cdbf04a3c0e1648901
        echo Anyway, the program will verify it once it's
        echo in the same folder as the executable.
        echo.
    )
)

REM Check if TROJAN_7.BIN is in the CMD folder
if exist "TROJAN_7.BIN" (
    echo Verifying MD5 of TROJAN_7.BIN in the CMD folder...
    echo.
    for /f "tokens=*" %%A in ('CertUtil -hashfile "TROJAN_7.BIN" MD5 ^| find /i /v "hash"') do set hashCmdTrojan=%%A
    set "!hashCmdTrojan=!hashCmdTrojan: =!"
    if defined hashPendriveTrojan (
        if /i "!hashPendriveTrojan!" NEQ "!hashCmdTrojan!" (
            echo TROJAN_7.BIN has different versions:
            echo.
            echo - On the POPS USB drive: !hashPendriveTrojan!

            if /i "!hashPendriveTrojan!"=="25f6bd59559b25b60881a92353bf0e9f" (
            echo is the latest R7 modified by hugopocked.
            ) else if /i "!hashPendriveTrojan!"=="7bbcb73e5f2e068d735573e62c80bd08" (
            echo is the R7 taken from elotrolado.
            ) else if /i "!hashPendriveTrojan!"=="ca48a3e90d10866361faf008656c25b2" (
            echo is the R6 version taken from ps2-home.
            ) else (
            echo has an unknown MD5.
            )

            echo.

            echo - In the CMD folder: !hashCmdTrojan!
            if /i "!hashCmdTrojan!"=="25f6bd59559b25b60881a92353bf0e9f" (
            echo is the latest R7 modified by hugopocked.

            ) else if /i "!hashCmdTrojan!"=="7bbcb73e5f2e068d735573e62c80bd08" (
            echo is the R7 taken from elotrolado.
            ) else if /i "!hashCmdTrojan!"=="ca48a3e90d10866361faf008656c25b2" (
            echo is the R6 version taken from ps2-home.
            ) else (
            echo has an unknown MD5.
            )
            echo.
            echo I clarify that I don't know which version is correct or better, but these are the 3 versions I found:
            echo - MD5: 25f6bd59559b25b60881a92353bf0e9f - Latest R7 modified by hugopocked -Year-2024-
            echo - MD5: 7bbcb73e5f2e068d735573e62c80bd08 - R7 taken from elotrolado -Year-2021-
            echo - MD5: ca48a3e90d10866361faf008656c25b2 - R6 taken from ps2-home -Year-2020-
            echo.
            set /p reemplazar=Do you want to replace the TROJAN_7.BIN on the USB drive with the one in the CMD folder? Y/N: 
            if /i "!reemplazar!"=="Y" (
                echo Replacing TROJAN_7.BIN on the USB drive...
                copy /y "TROJAN_7.BIN" "%ruta%\POPS"
            ) else (
                echo TROJAN_7.BIN was not replaced on the USB drive.
            )
        ) else if "!faltaTROJAN!"=="1" (
            echo Copying TROJAN_7.BIN to the USB drive...
            copy "TROJAN_7.BIN" "%ruta%\POPS"
        ) else (
            echo A TROJAN_7.BIN file already exists and it's the same in both the CMD folder and the USB drive.
        )

    )
)else (
    echo TROJAN_7.BIN not found in the CMD folder.
    echo This is optional although I recommend it
    echo To download TROJAN_7.BIN
    echo There are several links
    echo For the latest version modified by hugopocked
    echo https://www.mediafire.com/file/c6eqcx81yn3n8yu/Cumulative_r7_Disabled_something_XD.rar/file
    echo For the elotrolado version
    echo https://mega.nz/file/YpBTkAyR#BX9IzbfQy7mxNYzPkvvfYyimoP7vhgkfTMwULwK94z0
    echo For the ps2-home version
    echo https://www.ps2-home.com/forum/download/file.php?id=15747
)


pause
cls

echo "________          ________      _________              ";
echo "___  __ )____  __ ___  __ \___________  /____________ _";
echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
echo "        /____/                                         ";

echo " ___  ____  ___  ___    ___ ";
echo "/ __)(_  _)(  _)(  ,\  (__ )";
echo "\__ \  )(   ) _) ) _/   (_ \";
echo "(___/ (__) (___)(_)    (___/";

echo Step 3 conf_apps.cfg Review
:: Change to drive %ruta%
%ruta%

if not exist "!ruta_inicial!\!carpeta_backup_cmd!" (
    mkdir "!ruta_inicial!\!carpeta_backup_cmd!"
)
:: Configuration file
set "archivo_cfg=%ruta%conf_apps.cfg"

:: Variables to store errors
set "incorrectos_cfg="
set "incorrectos_msj="
set "incorrecto_nivel="
set "incorrecto_nivel_temp="
set "contador=0"
set "contadorlimpio=0"
set "variable_nombre="
set "variable_ruta_nombre="

:: Read the file line by line

for /f "tokens=1,* delims==" %%A in ('type "%archivo_cfg%"') do (

    if "%%B"=="" (
        set /a contadorlimpio+=1
        set "nombre_cfg=%%A"
        set "ruta_cfg1=%ruta%\POPS\XX.%%A.ELF"
        set "ruta_cfg2=%ruta%\POPS\%%A.VCD"
        if not exist "!ruta_cfg2!" (
            set "variable_ruta_nombre[!contadorlimpio!]=!nombre_cfg!"
            set "incorrectos_msj[!contadorlimpio!]=Line !contadorlimpio!: !nombre_cfg! ROM not found!"
            set "incorrectos_sol[!contadorlimpio!]=Solution: Delete the line, neither the ROM nor its nominal name exists in the POPS folder"
            set "incorrecto_nivel[!contadorlimpio!]=7"
            if not exist "!ruta_cfg1!" (
                set "variable_ruta_nombre[!contadorlimpio!]=!nombre_cfg!"
                set "incorrectos_msj[!contadorlimpio!]=Line !contadorlimpio!: Nothing found with !nombre_cfg!, not even with its nominal name"
                set "incorrectos_sol[!contadorlimpio!]=Solution: Delete the line, neither the ROM nor the ELF exists, not even with its nominal name in the POPS folder"
                set "incorrecto_nivel[!contadorlimpio!]=8"
            )
        ) else (
            set "variable_ruta_nombre[!contadorlimpio!]=!nombre_cfg!"
            set "incorrectos_msj[!contadorlimpio!]=Line !contadorlimpio!: It seems the !nombre_cfg! ROM exists to add to conf_apps.cfg"
            set "incorrectos_sol[!contadorlimpio!]=Solution: Repair launcher path"
            set "incorrecto_nivel[!contadorlimpio!]=4"
            if not exist "!ruta_cfg1!" (
                set "variable_ruta_nombre[!contadorlimpio!]=!nombre_cfg!"
                set "incorrectos_msj[!contadorlimpio!]=Line !contadorlimpio!: It seems the !nombre_cfg! ROM exists but not its ELF to add to conf_apps.cfg"
                set "incorrectos_sol[!contadorlimpio!]=Solution: Repair launcher path"
                set "incorrecto_nivel[!contadorlimpio!]=5"
            )
        )
    ) else (
        set "nombre_cfg=%%A"
        set "ruta_cfg=%%B"
        set /a contadorlimpio+=1
        set "variable_nombre[!contadorlimpio!]=!nombre_cfg!"
        set "variable_ruta_nombre[!contadorlimpio!]=!ruta_cfg:~14,-4!"

        set "incorrecto_nivel_temp=0"
        set "incorrectos_msj[!contadorlimpio!]=Line !contadorlimpio!: !nombre_cfg! Seems to be working perfectly"
        set "incorrectos_sol[!contadorlimpio!]=Solution: No need, everything is correct"
        set "incorrecto_nivel[!contadorlimpio!]=0"

        :: Verify launcher existence
        set "temp_ruta_launcher=!ruta_cfg:mass:/=%ruta%!"
        if not exist "!temp_ruta_launcher!" (
            set "incorrectos_msj[!contadorlimpio!]=Line !contadorlimpio!: !nombre_cfg! launcher does not exist"
            set "incorrectos_sol[!contadorlimpio!]=Solution: Create launcher for the .VCD game"
            set "incorrecto_nivel[!contadorlimpio!]=1"
            set "incorrecto_nivel_temp=1"
        )

        :: Verify ROM existence
        set "temp_ruta_vcd=%ruta%POPS/!ruta_cfg:~14,-4!.VCD"
        if not exist "!temp_ruta_vcd!" (
            set "incorrectos_msj[!contadorlimpio!]=Line !contadorlimpio!: !nombre_cfg! ROM not found!"
            set "incorrectos_sol[!contadorlimpio!]=Solution: Delete the line, the ROM does not exist in the POPS folder"
            set "incorrecto_nivel[!contadorlimpio!]=6"
            set "incorrecto_nivel_temp=6"
        )

        if !incorrecto_nivel_temp!==6 (
            set "testear_ruta=%ruta%/POPS/!nombre_cfg!.VCD"
            set "testear_ruta2=%ruta%/POPS/XX.!nombre_cfg!.ELF"
            if not exist "!testear_ruta!" (
                echo "!testear_ruta!"
                set "incorrectos_msj[!contadorlimpio!]=Line !contadorlimpio!: !nombre_cfg! ROM not found even with its nominal name"
                set "incorrectos_sol[!contadorlimpio!]=Solution: Delete the line, neither the ROM nor its nominal name exists in the POPS folder"
                set "incorrecto_nivel[!contadorlimpio!]=7"
            ) else (
                set "incorrecto_nivel[!contadorlimpio!]=2"
                set "incorrectos_msj[!contadorlimpio!]=Line !contadorlimpio!: !nombre_cfg! ROM found using nominal format"
                set "incorrectos_sol[!contadorlimpio!]=Solution: Repair the ROM path in conf_apps.cfg"
                if not exist "!testear_ruta2!" (
                    set "incorrecto_nivel[!contadorlimpio!]=3"
                    set "incorrectos_msj[!contadorlimpio!]=Line !contadorlimpio!: !nombre_cfg! ROM found using nominal format but not its ELF"
                    set "incorrectos_sol[!contadorlimpio!]=Solution: Repair the ROM path and add launcher in the POPS folder"
                )
            )
        )
    )
)

:: Show errors
echo conf_apps.cfg Correction:
echo.
copy /y "%archivo_cfg%" "%ruta_inicial%\!carpeta_backup_cmd!\conf_apps.cfg" >nul
(for /l %%I in (1,1,!contadorlimpio!) do (

    if !incorrecto_nivel[%%I]! LSS 6 (
    call echo !incorrectos_msj[%%I]!
    call echo Error Level: !incorrecto_nivel[%%I]!
    call echo !incorrectos_sol[%%I]!
    call echo.
    )
)) > Dianostico_Reparables-conf_apps.cfg.txt
move /y "Dianostico_Reparables-conf_apps.cfg.txt" "%ruta_inicial%\!carpeta_backup_cmd!\Dianostico_Reparables-conf_apps.cfg.txt" >nul

(for /l %%I in (1,1,!contadorlimpio!) do (

    if !incorrecto_nivel[%%I]! GTR 5 (
    call echo !incorrectos_msj[%%I]!
    call echo Error Level: !incorrecto_nivel[%%I]!
    call echo !incorrectos_sol[%%I]!
    call echo.
    )
))> Dianostico_Irreparables-conf_apps.cfg.txt
move /y "Dianostico_Irreparables-conf_apps.cfg.txt" "%ruta_inicial%\!carpeta_backup_cmd!\Dianostico_Irreparables-conf_apps.cfg.txt" >nul
echo conf_apps.cfg will be automatically fixed when you press the next key
echo.
echo A backup of conf_apps.cfg will be saved in the folder
echo %ruta_inicial%\!carpeta_backup_cmd!
echo Diagnostic data will also be saved in the same folder
echo.
pause
set "contara=0"
    echo Applying corrections...
    (for /f "usebackq delims=" %%L in ("%archivo_cfg%") do (
    set "linea=%%L"
    set /a contara+=1
    setlocal enabledelayedexpansion
    set "guardar=1"
    :: Check if the line should be deleted
    for /l %%I in (1,1,!contara!) do (
        if !contara!==%%I if !incorrecto_nivel[%%I]! GTR 5 (
            set "guardar=0"
        ) else if !contara!==%%I if "!incorrecto_nivel[%%I]!"=="5" (
            set "guardar=3"
            if exist "%ruta_inicial%\POPSTARTER.ELF" (
                copy "%ruta_inicial%\POPSTARTER.ELF" "%ruta%\POPS\XX.!variable_ruta_nombre[%%I]!.ELF" >nul
                mkdir "%ruta%\POPS\!variable_ruta_nombre[%%I]!" >nul
            )
        ) else if !contara!==%%I if "!incorrecto_nivel[%%I]!"=="4" (
            set "guardar=3"
        ) else if !contara!==%%I if "!incorrecto_nivel[%%I]!"=="3" (
            set "guardar=2"
            if exist "%ruta_inicial%\POPSTARTER.ELF" (
                copy "%ruta_inicial%\POPSTARTER.ELF" "%ruta%\POPS\XX.!variable_ruta_nombre[%%I]!.ELF" >nul
                mkdir "%ruta%\POPS\!variable_ruta_nombre[%%I]!" >nul
            )
        ) else if !contara!==%%I if "!incorrecto_nivel[%%I]!"=="2" (
            set "guardar=2"
        ) else if !contara!==%%I if "!incorrecto_nivel[%%I]!"=="1" (
            set "guardar=1"
            if exist "%ruta_inicial%\POPSTARTER.ELF" (
                copy "%ruta_inicial%\POPSTARTER.ELF" "%ruta%\POPS\XX.!variable_ruta_nombre[%%I]!.ELF" >nul
                mkdir "%ruta%\POPS\!variable_ruta_nombre[%%I]!" >nul
            )
        )
    )

    if "!guardar!"=="1" (
        echo !linea!
        )
    if "!guardar!"=="2" (
        for /f "delims==" %%a in ("!linea!") do set "naim=%%a"
        echo !naim!=mass:/POPS/XX.!naim!.ELF
    )
    if "!guardar!"=="3" (
        echo !linea!=mass:/POPS/XX.!linea!.ELF
    )
    endlocal
)) > "%archivo_cfg%.tmp"

move /y "%archivo_cfg%.tmp" "%archivo_cfg%" >nul

echo.
echo Verifying duplicate entries in conf_apps.cfg...
echo.

set contara=0
set contares=0
set entradas_duplicadas=0
(for /f "usebackq delims=" %%L in ("%archivo_cfg%") do (
    set guardar=1
    set /a contara+=1
    for /f "usebackq delims=" %%M in ("%archivo_cfg%") do (
        set /a contares+=1
        if !contares! GTR !contara! (
                    if %%L == %%M (
                        set guardar=0
                    )
        )

    )
    set contares=0
    if "!guardar!"=="1" (
        echo %%L
    ) else (
        set /a entradas_duplicadas+=1
    )
)) > "%archivo_cfg%.tmp"

move /y "%archivo_cfg%.tmp" "%archivo_cfg%" >nul

echo Deleted !entradas_duplicadas! duplicate entries.

pause
cls

!cmd_ruta!
cd %ruta_inicial%

echo "________          ________      _________              ";
echo "___  __ )____  __ ___  __ \___________  /____________ _";
echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
echo "        /____/                                         ";

echo " ___  ____  ___  ___     __  ";
echo "/ __)(_  _)(  _)(  ,\   / ,) ";
echo "\__ \  )(   ) _) ) _/  (_  _)";
echo "(___/ (__) (___)(_)      (_) ";

echo Step 4 Verification, Repair, and Installation of local .VCD files

:: Scan all .VCD files in F:\ and its subdirectories, except \POPS\
echo Scanning misplaced .VCD files in !ruta!\ and subdirectories (except \POPS\)...
set "archivos_mal_ubicados=0"
for /r "%ruta%" %%F in (*.VCD) do (
    set "archivo_vcd=%%~nxF"
    set "ruta_vcd=%%~dpF"
    if /i not "%%~dpF"=="%ruta%\POPS\" (
        echo Misplaced file: %%F
        set /a archivos_mal_ubicados+=1
        set "archivo_mal_ubicado[!archivos_mal_ubicados!]=%%~fF"
    )
)

:: Show misplaced files
if !archivos_mal_ubicados! GTR 0 (
    echo The following misplaced .VCD files were found:
    for /l %%I in (1,1,!archivos_mal_ubicados!) do (
        echo [%%I] !archivo_mal_ubicado[%%I]!
    )
    echo.
    set /p "mover_archivos=Do you want to move them to the \POPS\ folder? (Y/N): "
    if /i "!mover_archivos!"=="Y" (
        echo Moving .VCD files to the \POPS\ folder...
        for /l %%I in (1,1,!archivos_mal_ubicados!) do (
            move "!archivo_mal_ubicado[%%I]!" "%ruta%\POPS\" >nul
            echo Moved file: !archivo_mal_ubicado[%%I]!
        )
        echo All misplaced files were moved to \POPS\.
    ) else (
        echo Misplaced files were not moved.
    )
) else (
    echo No misplaced .VCD files were found.
)
echo.
pause
:: Deleting orphaned .ELF files
echo Verifying orphaned ELF files...
for %%F in ("%ruta%\POPS\XX.*.ELF") do (
    set "archivo_elf=%%~nxF"
    set "nombre_sin_extension=!archivo_elf:XX.=!"
    set "nombre_sin_extension=!nombre_sin_extension:.ELF=!"
    if not exist "%ruta%\POPS\!nombre_sin_extension!.VCD" (
        echo Deleting orphaned file: %%F
        del "%%F"
    )
)

:: Verify .VCD files not in conf_apps.cfg
echo Adding .VCD Games to conf_apps.cfg \\\ Creating ELF Launchers \\\ Creating Folders...
for %%F in ("%ruta%\POPS\*.VCD") do (
    set "archivo_vcd=%%~nxF"
    set "nombre_sin_extension=!archivo_vcd:.VCD=!"
    set "encontrado=0"
    for /f "tokens=1,2 delims==" %%A in ('type "%archivo_cfg%"') do (
        if /i "%%A"=="!nombre_sin_extension!" (
            set "encontrado=1"
        )
    )
    if "!encontrado!"=="0" (
        echo .VCD file not found in conf_apps.cfg: %%F
        echo Adding entry to conf_apps.cfg...
        echo !nombre_sin_extension!=mass:/POPS/XX.!nombre_sin_extension!.ELF>>"%archivo_cfg%"
        if not exist "%ruta%\POPS\XX.!nombre_sin_extension!.ELF" (
            echo Copying POPSTARTER.ELF as XX.!nombre_sin_extension!.ELF...
            copy "%ruta_inicial%\POPSTARTER.ELF" "%ruta%\POPS\XX.!nombre_sin_extension!.ELF" >nul
        )
        if not exist "%ruta%\POPS\!nombre_sin_extension!\" (
            echo Creating folder: %ruta%\POPS\!nombre_sin_extension!
            mkdir "%ruta%\POPS\!nombre_sin_extension!" >nul
        )
    )
)

echo Verification and corrections completed.


pause
cls

echo "________          ________      _________              ";
echo "___  __ )____  __ ___  __ \___________  /____________ _";
echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
echo "        /____/                                         ";

echo " ___  ____  ___  ___    ___ ";
echo "/ __)(_  _)(  _)(  ,\  / __)";
echo "\__ \  )(   ) _) ) _/  \__ \";
echo "(___/ (__) (___)(_)    (___/";

echo Step 5 Installation of local .VCD files
set "contador=0"
set "total_directorios=0"

:: Ask whether to include subdirectories
set /p "instalar_VCD_CMD=Do you want to install the games saved in the executable's path (Y/N): "
if /i "!instalar_VCD_CMD!"=="Y" (
    set /p "incluir_subdirs=Do you also want to copy the games saved in subdirectories? (Y/N): "
    if /i "!incluir_subdirs!"=="Y" (
        echo Searching for .VCD files in the directory and subdirectories...
        for /r "%ruta_inicial%" %%F in (*.VCD) do (
            set "archivo=%%~nxF"
            set "ruta=%%~dpF"
            set /a contador+=1
            set "ruta_de_copiado[!contador!]=%%~dpF"
            set "archivo_nombre[!contador!]=%%~nxF"
            echo Found file: !archivo! in !ruta!
        )
    ) else (
        echo Searching for .VCD files only in the root directory...
        for %%F in ("%ruta_inicial%\*.VCD") do (
            set "archivo=%%~nxF"
            set "ruta=%%~dpF"
            set /a contador+=1
            set "ruta_de_copiado[!contador!]=%%~dpF"
            set "archivo_nombre[!contador!]=%%~nxF"
            echo Found file: !archivo! in !ruta!
        )
    )

    :: Show found files
    if !contador! GTR 0 (
        echo The following .VCD files were found:
        for /l %%I in (1,1,!contador!) do (
            echo [%%I] !archivo_nombre[%%I]! in !ruta_de_copiado[%%I]!
        )
        set /p "confirmar_copia=Do you want to copy all of them? (Y/N): "
        if /i "!confirmar_copia!"=="Y" (
            echo Starting file copy...
            for /l %%I in (1,1,!contador!) do (
                set "archivo=!archivo_nombre[%%I]!"
                set "ruta=!ruta_de_copiado[%%I]!"
                set "nombre_sin_extension=!archivo:.VCD=!"
                if exist "%ruta%\POPS\!archivo!" (
                    echo Skipping !archivo! because it already exists in %ruta%\POPS.
                ) else (
                    echo Copying !archivo! from !ruta! to %ruta%\POPS...
                    copy "!ruta!\!archivo!" "%ruta%\POPS" >nul
                    echo Copied !archivo!.

                    :: Create folder with the same name (without extension)
                    mkdir "%ruta%\POPS\!nombre_sin_extension!" >nul
                    echo Created folder: %ruta%\POPS\!nombre_sin_extension!

                    :: Copy POPSTARTER.ELF with new name
                    if exist "%cd%\POPSTARTER.ELF" (
                        copy "%cd%\POPSTARTER.ELF" "%ruta%\POPS\XX.!nombre_sin_extension!.ELF" >nul
                        echo POPSTARTER.ELF file copied as XX.!nombre_sin_extension!.ELF.
                    ) else (
                        echo Error: POPSTARTER.ELF not found in the current directory.
                    )

                    :: Add line to the conf_apps.cfg file
                    echo !nombre_sin_extension!=mass:/POPS/XX.!nombre_sin_extension!.ELF>>"F:\conf_apps.cfg"
                    echo Line added to conf_apps.cfg: !nombre_sin_extension!=mass:/POPS/XX.!nombre_sin_extension!.ELF
                )
            )
            echo Copy completed.
        ) else (
            echo Copy cancelled.
        )
    ) else (
        echo No .VCD files were found.
    )
)
pause

:continuar6
cls

echo "________          ________      _________              ";
echo "___  __ )____  __ ___  __ \___________  /____________ _";
echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
echo "        /____/                                         ";

echo " ___  ____  ___  ___     _  ";
echo "/ __)(_  _)(  _)(  ,\   / ) ";
echo "\__ \  )(   ) _) ) _/  / , \";
echo "(___/ (__) (___)(_)    \___/";

echo Step 6 CHEATS.TXT Installation

echo What does CHEATS.TXT do? Besides saving cheats, it modifies screen format
echo.
echo Not for dummies, it might work but only if you know what you're doing
echo It can prevent one/all games from running correctly so use it with caution
echo Improves the resolution of PS1 games in several cases
echo.
echo If a particular game doesn't work, simply delete the CHEATS.TXT file
echo From the game's folder or specific lines
echo.
echo Don't worry, the original file will not be deleted or overwritten. It will only be updated
echo If it malfunctions, a Backup will be saved in the !carpeta_backup_cmd!\Cheats.TXT folder
echo.
set /p "crear_cheats= Do you want to Create/Update CHEATS.TXT [Y/N]? Press [H] for help: "
echo !crear_cheats! asd
if /i "!crear_cheats!" == "N" (
    echo CHEATS.TXT file will not be created.
    pause
) else if /i "!crear_cheats!" == "Y" (
    echo Select the desired quality:
    echo [1] Digital 480p - Best quality not compatible with some consoles
    echo     rather, with RCA cable or classic PS1 cable.
    echo     Does not work in some games although only 5%
    echo [2] Analog NTSC America - Compatible with all games and cables.
    echo [3] Analog PAL Europe - Compatible with all games and cables.
    set /p "calidad=Enter your option 1-2-3: "
                echo Creating deletion file...
        (
            echo $SAFEMODE
            echo $SMOOTH
            echo $480p
            echo $FORCEPAL
            echo $NOPAL
            echo $YPOS_
            echo $XPOS_
        ) > temp_del_CHEAT.txt
    if "!calidad!"=="1" (
        echo Creating temporary file for digital quality...
        (
            echo $SAFEMODE
            echo $SMOOTH
            echo $480p
        ) > temp_CHEAT.txt
    ) else if "!calidad!"=="2" (
        echo Creating temporary file for analog NTSC quality...
        (
            echo $SAFEMODE
            echo $SMOOTH
            echo $NOPAL
            echo $YPOS_0
            echo $XPOS_576
        ) > temp_CHEAT.txt
    ) else if "!calidad!"=="3" (
        echo Creating temporary file for analog PAL quality...
        (
            echo $SAFEMODE
            echo $SMOOTH
            echo $FORCEPAL
            echo $YPOS_0
            echo $XPOS_576
        ) > temp_CHEAT.txt
    ) else (
        echo Invalid option. Exiting...
        pause
    )

    :: Navigate through the folders inside \POPS\ that meet the conditions
    echo Navigating through the folders inside \POPS\...
    echo %ruta%\POPS\*
    for /d %%D in ("%ruta%\POPS\*") do (
        if exist "%%D.VCD" (
            set "carpeta=%%D"
            for %%I in ("!carpeta!") do set "solo_nombre=%%~nxI"
            if exist "!carpeta!\CHEATS.TXT" (
                if not exist "!ruta_inicial!\!carpeta_backup_cmd!\CHEATS.TXT" (
                    mkdir "!ruta_inicial!\!carpeta_backup_cmd!\CHEATS.TXT"
                )
                if not exist "!ruta_inicial!\!carpeta_backup_cmd!\CHEATS.TXT\!solo_nombre!" (
                            mkdir "!ruta_inicial!\!carpeta_backup_cmd!\CHEATS.TXT\!solo_nombre!"
                            copy /y "%%D\CHEATS.TXT" "!ruta_inicial!\!carpeta_backup_cmd!\CHEATS.TXT\!solo_nombre!\CHEATS.TXT" >nul
                            )
                echo Scanning CHEATS.TXT file in the game folder: !solo_nombre!
                (for /f "usebackq delims=" %%L in ("!carpeta!\CHEATS.TXT") do (
                    set "encontrado=no"
                    for /f "usebackq delims=" %%M in ("!ruta_inicial!\temp_del_CHEAT.txt") do (
                        if %%L==%%M (
                            set "encontrado=si"
                        ) else (
                            echo "%%L%" | findstr "%%M" > nul 2>&1
                            if %errorlevel% == 0 (
                                set "encontrado=si"
                            ) else (
                                set "encontrado=no"
                            )
                        )
                    )
                    if "!encontrado!"=="no" (
                        echo %%L
                    )
                )) > temp_resultado_CHEATS.TXT
                (
                    type "!ruta_inicial!\temp_CHEAT.txt"
                    type "!ruta_inicial!\temp_resultado_CHEATS.TXT"
                ) > temporal2.TXT
                move /y "!ruta_inicial!\temporal2.TXT" "!carpeta!\CHEATS.TXT" >nul
            ) else (
                echo Creating CHEATS.TXT in the game folder: !carpeta!
                copy /y temp_CHEAT.txt "%%D\CHEATS.TXT" >nul
                echo CHEATS.TXT created in %%D
            )
        )
    )

    :: Delete temporary file
    del temp_CHEAT.txt >nul
    del temp_del_CHEAT.txt >nul
    del temp_resultado_CHEATS.TXT >nul
    :: Final warning
    echo.
    echo A backup of CHEATS.TXT has been made in the Backup Cheats.TXT!hora_actual!\ folder!
    echo If any game doesn't work, try deleting CHEATS.TXT from that game's folder in \POPS\.
    pause
) else if /i "!crear_cheats!" == "H" (
    cls
    echo "________          ________      _________              ";
    echo "___  __ )____  __ ___  __ \___________  /____________ _";
    echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
    echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
    echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
    echo "        /____/                                         ";

    echo " ___  ____  ___  ___     _  ";
    echo "/ __)(_  _)(  _)(  ,\   / ) ";
    echo "\__ \  )(   ) _) ) _/  / , \";
    echo "(___/ (__) (___)(_)    \___/";
    echo.
    echo CHEATS.TXT files are saved in !ruta!\POPS\Game Folder\CHEATS.TXT
    echo If a specific game doesn't work for you, simply change it
    echo To make each configuration work, simply add the $ sign and the command
    echo.
    echo Commands you should never remove
    echo $SAFEMODE
    echo.
    echo Commands to Smooth textures
    echo $SMOOTH
    echo.
    echo Command to run in Digital
    echo $480p
    echo And Commands that stop working with Digital
    echo $YPOS_
    echo $XPOS_
    echo.
    echo Command to run in NTSC
    echo Only if it doesn't run in digital
    echo Recommended for American [Latino/Yankee] televisions
    echo $NOPAL
    echo $YPOS_desired number
    echo $XPOS_desired number
    echo.
    echo Command to run PAL
    echo Only if it doesn't run in digital
    echo Recommended for European [Bloody/Mate] televisions
    echo $FORCEPAL
    echo $YPOS_desired number
    echo $XPOS_desired number
    echo.
    pause
    goto continuar6
) else (
    echo CHEATS.TXT was not updated
)
cls
pause

echo "________          ________      _________              ";
echo "___  __ )____  __ ___  __ \___________  /____________ _";
echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
echo "        /____/                                         ";

echo " ___  ____  ___  ___    ___ ";
echo "/ __)(_  _)(  _)(  ,\  (__ )";
echo "\__ \  )(   ) _) ) _/   / / ";
echo "(___/ (__) (___)(_)    (_/  ";

echo Step 7 Change ELF File Names
echo.
pause
set "contadorlinea=0"
for /f "tokens=1,* delims==" %%A in ('type "%archivo_cfg%"') do (
    set "ruta_cfg=%%B"
    set "nombre_cfg=%%A"
    set /a "contadorlinea=!contadorlinea!+1"
            set "verif_nombre=!ruta_cfg:~14,-4!"
            if not !verif_nombre! == "~14,-4" (
                set "verif_ruta=!ruta_cfg:~0,11!"
                if "!verif_ruta!" == "mass:/POPS/" (
                    if not "!nombre_cfg!"=="!verif_nombre!" (
                        echo The launcher name does not match the description:
                        echo Name: !nombre_cfg!
                        echo Launcher: !verif_nombre!
                        set /p "cambiar=Do you want to change it? y/n: "
                        if /i "!cambiar!"=="y" (
                            echo Renaming files...

                            echo path: !ruta!POPS
                            cd "!ruta!\POPS"
                            echo Renaming: "XX.!verif_nombre!.ELF" to "XX.!nombre_cfg!.ELF"
                            ren "XX.!verif_nombre!.ELF" "XX.!nombre_cfg!.ELF"
                            echo Renaming: "!verif_nombre!.VCD" to "!nombre_cfg!.VCD"
                            ren "!verif_nombre!.VCD" "!nombre_cfg!.VCD"
                            cd "!ruta!\ART"
                            for %%F in (_BG.png _COV.png _COV2.png _ICO.png _LAB.png _LGO.png _SCR.png _SCR2.png _BG.jpg _COV.jpg _COV2.jpg _ICO.jpg _LAB.jpg _LGO.jpg _SCR.jpg _SCR2.jpg _BG.jpeg _COV.jpeg _COV2.jpeg _ICO.jpeg _LAB.jpeg _LGO.jpeg _SCR.jpeg _SCR2.jpeg) do (
                                echo Renaming: "XX.!verif_nombre!.ELF%%F" to "XX.!nombre_cfg!.ELF%%F"
                                ren "XX.!verif_nombre!.ELF%%F" "XX.!nombre_cfg!.ELF%%F"
                            )
                            cd "!ruta!\CFG"
                            echo Renaming: "XX.!verif_nombre!.cfg" to "XX.!nombre_cfg!.cfg"
                            ren "XX.!verif_nombre!.cfg" "XX.!nombre_cfg!.cfg"
                            cd "!ruta!"

                            echo Updating conf_apps.cfg...
                            set "nueva_linea=!nombre_cfg!=mass:/POPS/XX.!nombre_cfg!.ELF"
                            (for /f "usebackq delims=" %%X in ("!archivo_cfg!") do (
                                set "linea_sat=%%X"
                                setlocal enabledelayedexpansion
                                if "!linea_sat!"=="%%A=%%B" (
                                    echo !nueva_linea!
                                ) else (
                                    echo !linea_sat!
                                )
                                endlocal
                            )) > "%archivo_cfg%.tmp"
                            move /y "%archivo_cfg%.tmp" "%archivo_cfg%" >nul
                        )
                        pause
                        cls
                        echo "________          ________      _________              ";
                        echo "___  __ )____  __ ___  __ \___________  /____________ _";
                        echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
                        echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
                        echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
                        echo "        /____/                                         ";

                        echo " ___  ____  ___  ___    ___ ";
                        echo "/ __)(_  _)(  _)(  ,\  (__ )";
                        echo "\__ \  )(   ) _) ) _/   / / ";
                        echo "(___/ (__) (___)(_)    (_/  ";
                    )
                ) else (
                    cls
                    echo "________          ________      _________              ";
                    echo "___  __ )____  __ ___  __ \___________  /____________ _";
                    echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
                    echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
                    echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
                    echo "        /____/                                         ";

                    echo " ___  ____  ___  ___    ___ ";
                    echo "/ __)(_  _)(  _)(  ,\  (__ )";
                    echo "\__ \  )(   ) _) ) _/   / / ";
                    echo "(___/ (__) (___)(_)    (_/  ";
                    echo You have a badly written entry in cfg
                    echo on line !contadorlinea! run the program again
                    echo and activate/use the automatic cfg correction
                    pause
                )
            ) else (
                cls
                echo "________          ________      _________              ";
                echo "___  __ )____  __ ___  __ \___________  /____________ _";
                echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
                echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
                echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
                echo "        /____/                                         ";

                echo " ___  ____  ___  ___    ___ ";
                echo "/ __)(_  _)(  _)(  ,\  (__ )";
                echo "\__ \  )(   ) _) ) _/   / / ";
                echo "(___/ (__) (___)(_)    (_/  ";
                echo You have a badly written entry in cfg
                echo on line !contadorlinea! run the program again
                echo and activate/use the automatic cfg correction
                pause
            )
            cls
            echo "________          ________      _________              ";
            echo "___  __ )____  __ ___  __ \___________  /____________ _";
            echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
            echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
            echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
            echo "        /____/                                         ";

            echo " ___  ____  ___  ___    ___ ";
            echo "/ __)(_  _)(  _)(  ,\  (__ )";
            echo "\__ \  )(   ) _) ) _/   / / ";
            echo "(___/ (__) (___)(_)    (_/  ";
)

cls

echo "________          ________      _________              ";
echo "___  __ )____  __ ___  __ \___________  /____________ _";
echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
echo "        /____/                                         ";

echo " ___  ____  ___  ___    ___ ";
echo "/ __)(_  _)(  _)(  ,\  ( , )";
echo "\__ \  )(   ) _) ) _/  / , \";
echo "(___/ (__) (___)(_)    \___/";

echo Step 8 Sort conf_apps.cfg Lines Alphabetically
echo.

set /p "ordenar=Do you want to sort the entries in conf_apps.cfg alphabetically? (Y/N): "
if /i "!ordenar!" NEQ "Y" (
    echo The conf_apps.cfg file will not be sorted.
) else if not exist "%archivo_cfg%" (
    echo The conf_apps.cfg file does not exist in the specified path.
) else (
    :: Sort the lines alphabetically
    echo Sorting the entries in conf_apps.cfg...
    (for /f "usebackq delims=" %%A in ("%archivo_cfg%") do (
        echo %%A
    )) > "%archivo_cfg%.tmp"

    :: Use sort to order the lines alphabetically
    sort "%archivo_cfg%.tmp" /o "%archivo_cfg%"

    :: Delete temporary file
    del "%archivo_cfg%.tmp" >nul

    echo conf_apps.cfg file sorted successfully.
)

pause
cls

echo "________          ________      _________              ";
echo "___  __ )____  __ ___  __ \___________  /____________ _";
echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
echo "        /____/                                         ";

echo " ___  ____  ___  ___    ___ ";
echo "/ __)(_  _)(  _)(  ,\  / , \";
echo "\__ \  )(   ) _) ) _/  \   /";
echo "(___/ (__) (___)(_)     (_/ ";

echo Step 9 Multidisc Configuration
echo.
echo Do you want to scan for multidisc games in the \POPS\ folder?:
echo Select multidisc search language parameters:
echo [1] [100 speed] Standard abbreviation methods only [faster] [less accurate]
echo [2]  [54 speed] Spanish Portuguese English Spanish w/details
echo [3]  [50 speed] Spanish Portuguese English Italian
echo [4]  [70 speed] English
echo [5]  [58 speed] German English
echo [6]  [58 speed] French English
echo [7]  [39 speed] All languages [Slower] [More accurate]
echo [8] to exit
set /p "opcion=Select an option (1-8): "
if "%opcion%"=="1" (
    set "parametros_multidisco=;CD1;CD$1;CD.1;CD:1;CD:$1;CD.$1;DVD1;DVD$1;DVD.1;DVD:1;DVD:$1;DVD.$1;D$1;D:$1;D:1;D1;D.1;DSC1;DSC$1;DSC.1;DSC:1;DSC:$1;DSC.$1;DSK1;DSK$1;DSK.1;DSK:1;DSK:$1;DSK.$1;DSCK1;DSCK$1;DSCK.1;DSCK:1;DSCK:$1;DSCK.$1;"
) else if "%opcion%"=="2" (
    set "parametros_multidisco=;CD1;CD$1;CD.1;CD:1;CD:$1;CD.$1;DVD1;DVD$1;DVD.1;DVD:1;DVD:$1;DVD.$1;D$1;Disk$1;DISCS$1;DISKS$1;Disco$1;Discos$1;Diskos$1;D:$1;Disk:$1;DISCS:$1;DISKS:$1;Disco:$1;Discos:$1;Diskos:$1;D:1;Disk:1;DISCS:1;DISKS:1;Disco:1;Discos:1;Diskos:1;D1;D.1;Disk.1;Disk1;DISCS.1;DISCS1;DISKS.1;DISKS1;Disco.1;Disco1;Discos.1;Discos1;Diskos.1;DSC1;DSC$1;DSC.1;DSC:1;DSC:$1;DSC.$1;DSK1;DSK$1;DSK.1;DSK:1;DSK:$1;DSK.$1;DSCK1;DSCK$1;DSCK.1;DSCK:1;DSCK:$1;DSCK.$1;Diskos.$1;Diskos.1;"
) else if "%opcion%"=="3" (
    set "parametros_multidisco=;CD1;CD$1;CD.1;CD:1;CD:$1;CD.$1;DVD1;DVD$1;DVD.1;DVD:1;DVD:$1;DVD.$1;D$1;Disk$1;DISCS$1;DISKS$1;D:$1;Disk:$1;DISCS:$1;DISKS:$1;D:1;Disk:1;DISCS:1;DISKS:1;D1;D.1;Disk.1;Disk1;DISCS.1;DISCS1;DISKS.1;DISKS1;Disco$1;Discos$1;Disco:$1;Discos:$1;Disco:1;Discos:1;Disco.1;Disco1;Discos.1;Discos1;Dischi$1;Dischi:$1;Dischi:1;Dischi.1;Dischi1;DSC1;DSC$1;DSC.1;DSC:1;DSC:$1;DSC.$1;DSK1;DSK$1;DSK.1;DSK:1;DSK:$1;DSK.$1;DSCK1;DSCK$1;DSCK.1;DSCK:1;DSCK:$1;DSCK.$1;Diskos$1;Diskos:$1;Diskos:1;Diskos.1;Diskos.$1;"
) else if "%opcion%"=="4" (
    set "parametros_multidisco=;CD1;CD$1;CD.1;CD:1;CD:$1;CD.$1;DVD1;DVD$1;DVD.1;DVD:1;DVD:$1;DVD.$1;D$1;Disk$1;DISCS$1;DISKS$1;D:$1;Disk:$1;DISCS:$1;DISKS:$1;D:1;Disk:1;DISCS:1;DISKS:1;D1;D.1;Disk.1;Disk1;DISCS.1;DISCS1;DISKS.1;DISKS1;DSC1;DSC$1;DSC.1;DSC:1;DSC:$1;DSC.$1;DSK1;DSK$1;DSK.1;DSK:1;DSK:$1;DSK.$1;DSCK1;DSCK$1;DSCK.1;DSCK:1;DSCK:$1;DSCK.$1;"
) else if "%opcion%"=="5" (
    set "parametros_multidisco=;CD1;CD$1;CD.1;CD:1;CD:$1;CD.$1;DVD1;DVD$1;DVD.1;DVD:1;DVD:$1;DVD.$1;D$1;Disk$1;DISCS$1;DISKS$1;D:$1;Disk:$1;DISCS:$1;DISKS:$1;D:1;Disk:1;DISCS:1;DISKS:1;D1;D.1;Disk.1;Disk1;DISCS.1;DISCS1;DISKS.1;DISKS1;Scheibe$1;Scheiben$1;Scheibe:$1;Scheiben:$1;Scheibe:1;Scheiben:1;Scheibe.1;Scheibe1;Scheiben.1;Scheiben1;DSC1;DSC$1;DSC.1;DSC:1;DSC:$1;DSC.$1;DSK1;DSK$1;DSK.1;DSK:1;DSK:$1;DSK.$1;DSCK1;DSCK$1;DSCK.1;DSCK:1;DSCK:$1;DSCK.$1;"
) else if "%opcion%"=="6" (
    set "parametros_multidisco=;CD1;CD$1;CD.1;CD:1;CD:$1;CD.$1;DVD1;DVD$1;DVD.1;DVD:1;DVD:$1;DVD.$1;D$1;Disk$1;DISCS$1;DISKS$1;D:$1;Disk:$1;DISCS:$1;DISKS:$1;D:1;Disk:1;DISCS:1;DISKS:1;D1;D.1;Disk.1;Disk1;DISCS.1;DISCS1;DISKS.1;DISKS1;Disque$1;Disques$1;Disque:$1;Disques:$1;Disque:1;Disques:1;Disque.1;Disque1;Disques.1;Disques1;DSC1;DSC$1;DSC.1;DSC:1;DSC:$1;DSC.$1;DSK1;DSK$1;DSK.1;DSK:1;DSK:$1;DSK.$1;DSCK1;DSCK$1;DSCK.1;DSCK:1;DSCK:$1;DSCK.$1;"
) else if "%opcion%"=="7" (
    set "parametros_multidisco=;CD1;CD$1;CD.1;CD:1;CD:$1;CD.$1;DVD1;DVD$1;DVD.1;DVD:1;DVD:$1;DVD.$1;D$1;Disk$1;DISCS$1;DISKS$1;D:$1;Disk:$1;DISCS:$1;DISKS:$1;D:1;Disk:1;DISCS:1;DISKS:1;D1;D.1;Disk.1;Disk1;DISCS.1;DISCS1;DISKS.1;DISKS1;Disco$1;Discos$1;Disco:$1;Discos:$1;Disco:1;Discos:1;Disco.1;Disco1;Discos.1;Discos1;Dischi$1;Dischi:$1;Dischi:1;Dischi.1;Dischi1;Disque$1;Disques$1;Disque:$1;Disques:$1;Disque:1;Disques:1;Disque.1;Disque1;Disques.1;Disques1;Scheibe$1;Scheiben$1;Scheibe:$1;Scheiben:$1;Scheibe:1;Scheiben:1;Scheibe.1;Scheibe1;Scheiben.1;Scheiben1;DSC1;DSC$1;DSC.1;DSC:1;DSC:$1;DSC.$1;DSK1;DSK$1;DSK.1;DSK:1;DSK:$1;DSK.$1;DSCK1;DSCK$1;DSCK.1;DSCK:1;DSCK:$1;DSCK.$1;Diskos$1;Diskos:$1;Diskos:1;Diskos.1;Diskos.$1;"
) else if "%opcion%"=="8" (
    echo Multidisc games will not be scanned.
    pause
    goto :eof
) else (
    echo Multidisc games will not be scanned.
    pause
    goto :eof
)

del vcd_list.txt >nul 2>&1

:: Base path of the POPS folder
set "ruta_pops=F:\POPS"

:: Create a temporary file with the names of the .VCD files and sort them alphabetically
echo Scanning and sorting .VCD files in \POPS\...
dir /b /a-d "%ruta_pops%\*.VCD" | sort > vcd_list.txt


:: Initialize variables
set "fecha=!date!"
set "fecha=!fecha:/=-!"

RD /S /Q "%cd%\temp_POPS !fecha!"

:: Group multidisc games
for /f "usebackq delims=" %%F in ("vcd_list.txt") do (
    set "archivo=%%F"

    if !posibles_multidisco! GTR 0 (
        set /a "variable_temporal=!posibles_multidisco!-1"
        for /L %%i in (!variable_temporal!,1,!posibles_multidisco!) do (
        set "parametros_multidisco_acertados=!parametros_multidisco_acertados:%%i=!"
        )
        set /a "posibles_multidisco+=1"
        set "parametros_multidisco_acertados=!parametros_multidisco_acertados!!posibles_multidisco!"
        echo "!archivo!" | findstr /I /C:"!parametros_multidisco_acertados!" > nul 2>&1
                                if !errorlevel! equ 0 (
                                    REM Here you can place the code that will be executed if the condition is true
                                ) else (
                                    REM Here you can place the code that will be executed if the condition is false
                                    set "parametros_multidisco_acertados="
                                    set "posibles_multidisco=0"
                                )
    )
    if !posibles_multidisco! LSS 1 (
        for %%C in ("!parametros_multidisco!") do (
            for %%D in ("%%C") do (
                for /f "tokens=1 delims=;" %%E in ("%%D") do (
                    set "variable_guardada=%%E"
                    set "variable_guardada=!variable_guardada:$= !"
                    if not !variable_guardada!== "" (
                        echo "!archivo!" | findstr /I /C:"!variable_guardada!" > nul 2>&1
                        if !errorlevel! equ 0 (
                            REM Here you can place the code that will be executed if the condition is true
                            set variable_nombre_archivo=%%F
                            set "posibles_multidisco=1"
                            set "parametros_multidisco_acertados=!variable_guardada!"
                        ) else (
                            REM Here you can place the code that will be executed if the condition is false
                        )
                    )
                )
            )
        )
    )
    if !posibles_multidisco! GTR 0 (
        if not exist "%cd%\temp_POPS !fecha!" (
            mkdir "%cd%\temp_POPS !fecha!"
        )
        echo %%F>>"%cd%\temp_POPS !fecha!\!variable_nombre_archivo!.temp"
    )
)

if not exist "%cd%\temp_POPS !fecha!\*.temp" (
    echo No multidisc games were found.
    pause
    goto :eof
)


for %%T in ("%cd%\temp_POPS !fecha!\*.temp") do (
    cls

    echo "________          ________      _________              ";
    echo "___  __ )____  __ ___  __ \___________  /____________ _";
    echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
    echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
    echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
    echo "        /____/                                         ";

    echo " ___  ____  ___  ___    ___ ";
    echo "/ __)(_  _)(  _)(  ,\  / , \";
    echo "\__ \  )(   ) _) ) _/  \   /";
    echo "(___/ (__) (___)(_)     (_/ ";
    echo.
    echo Possible multidisc:
    type "%%T"

    :: Ask if multidisc configuration is desired
    set "configurar="
    set /p "configurar=Do you want to configure multidisc? (Y/N): "
    if /i "!configurar!" NEQ "Y" (
        echo %%~nT has not been configured.
    ) else (
        set nombre_principal=%%~nT
        set nombre_principal=!nombre_principal:~0,-4!
        echo Configuring multidisc for !nombre_principal!...


        for /f "usebackq delims=" %%L in ("%%T") do (
            set "linea=%%L"
            set "linea=!linea:~0,-1!"
            set "carpeta_juego=!linea:~0,-3!"

            if not exist "%ruta_pops%\!carpeta_juego!" (
                mkdir "%ruta_pops%\!carpeta_juego!"
            )
            copy "%cd%\temp_POPS !fecha!\!nombre_principal!.VCD.temp" "%ruta_pops%\!carpeta_juego!\DISCS.TXT"
            echo !nombre_principal!>"%ruta_pops%\!carpeta_juego!\VMCDIR.TXT"
        )
    echo DISCS.TXT and VMCDIR.TXT files created successfully.
    echo Configuration completed for %%~nT.
    pause
    cls
    echo "________          ________      _________              ";
    echo "___  __ )____  __ ___  __ \___________  /____________ _";
    echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
    echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
    echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
    echo "        /____/                                         ";

    echo " ___  ____  ___  ___    ___ ";
    echo "/ __)(_  _)(  _)(  ,\  / , \";
    echo "\__ \  )(   ) _) ) _/  \   /";
    echo "(___/ (__) (___)(_)     (_/ ";
    echo.
    )
)

RD /S /Q "%cd%\temp_POPS !fecha!"

del vcd_list.txt >nul
pause