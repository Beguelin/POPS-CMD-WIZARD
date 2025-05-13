@echo off

chcp 65001 >nul

setlocal enabledelayedexpansion
set "hora_actual=%time:~0,5%"
set "hora_actual=%hora_actual::=.%"
set "ruta_inicial=%cd%"
set "fecha=!date!"
set "fecha=!fecha:/=-!"
set "carpeta_backup_cmd=Backup !fecha! !hora_actual!\"
set "cmd_ruta=!ruta_inicial:~0,2!"

echo La ultima beta de OPL anda teniendo problemas para correr POPS
echo o por lo menos hasta la ultima vez que intente
echo intente probar instalar la version estable 1.10 para probar los juegos
echo.

echo "________          ________      _________              ";
echo "___  __ )____  __ ___  __ \___________  /____________ _";
echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
echo "        /____/                                         ";

echo " ____   __    ___  _____     __ ";
echo "(  _ \ /__\  / __)(  _  )   /  )";
echo " )___//(__)\ \__ \ )(_)(     )( ";
echo "(__) (__)(__)(___/(_____)   (__)";

echo.
echo Paso 1 Deteccion de Archivos necesarios para correr POPS o PS1
REM Detectar dispositivos USB con letras de unidad asignadas y sus etiquetas
echo Detectando dispositivos USB con letras de unidad asignadas...
set index=0
for /f "tokens=1,2 delims=," %%A in ('powershell -Command "Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 } | Select-Object DeviceID, VolumeName | ForEach-Object { $_.DeviceID + ',' + $_.VolumeName }"') do (
    set /a index+=1
    set "device[!index!]=%%A"
    echo !index!. %%A - %%B
)

REM Preguntar al usuario qué dispositivo seleccionar
echo.
set /p choice=Seleccione el número del dispositivo USB: 

REM Validar la selección del usuario
if "!device[%choice%]!"=="" (
    echo Opción no válida. Saliendo...
    pause
    exit /b
)

REM Ruta seleccionada
set ruta=!device[%choice%]!
echo.
echo Ruta seleccionada: %ruta%\

REM Inicializar variables para verificar archivos
set faltaPOPS_IOX=0
set faltaPOPSTARTER=0
set faltaTROJAN=0
set archivosValidos=1
set archivosPendriveValidos=1
set reemplazarTROJAN=0

REM Verificar si existe la carpeta /POPS/
if exist "%ruta%\POPS\" (
    echo La carpeta /POPS/ existe en la ruta seleccionada.
    echo Verificando archivos...

    REM Verificar si existe POPS_IOX.PAK
    if exist "%ruta%\POPS/POPS_IOX.PAK" (
        echo Verificando MD5 de POPS_IOX.PAK...
        for /f "tokens=*" %%A in ('CertUtil -hashfile "%ruta%\POPS/POPS_IOX.PAK" MD5 ^| find /i /v "hash"') do set hashCalculado1=%%A
        set "hashCalculado1=!hashCalculado1: =!"
        if /i "!hashCalculado1!"=="a625d0b3036823cdbf04a3c0e1648901" (
            echo POPS_IOX.PAK es válido.
        ) else (
            echo POPS_IOX.PAK está corrupto o no es el correcto.
            set faltaPOPS_IOX=1
            set archivosPendriveValidos=0
        )
    ) else (
        echo Falta POPS_IOX.PAK en el pendrive.
        set faltaPOPS_IOX=1
        set archivosPendriveValidos=0
    )

    REM Verificar si existe POPSTARTER.ELF
    if exist "%ruta%\POPS\POPSTARTER.ELF" (
        echo Verificando MD5 de POPSTARTER.ELF...
        for /f "tokens=*" %%A in ('CertUtil -hashfile "%ruta%\POPS/POPSTARTER.ELF" MD5 ^| find /i /v "hash"') do set hashCalculado2=%%A
        set "hashCalculado2=!hashCalculado2: =!"
        if /i "!hashCalculado2!"=="4a39d44dfb477ea747f5ca5e39ee011e" (
            echo POPSTARTER.ELF es válido.
        ) else (
            echo POPSTARTER.ELF está corrupto o no es la ultima version.
            set faltaPOPSTARTER=1
            set archivosPendriveValidos=0
        )
        if not exist "!ruta_inicial!\POPSTARTER.ELF" (
                echo Guardando POPSTARTER.ELF a la carpeta del CMD para futuros cambios...
                copy "%ruta%\POPS\POPSTARTER.ELF" "%ruta_inicial%\POPSTARTER.ELF"
            )
    ) else (
        echo Falta POPSTARTER.ELF en el pendrive.
        set faltaPOPSTARTER=1
        set archivosPendriveValidos=0
    )

    REM Verificar si existe TROJAN_7.BIN
    if exist "%ruta%\POPS/TROJAN_7.BIN" (
        echo Se encuentra TROJAN_7.BIN en el pendrive.
        echo Verificando MD5 de TROJAN_7.BIN...
        for /f "tokens=*" %%A in ('CertUtil -hashfile "%ruta%\POPS/TROJAN_7.BIN" MD5 ^| find /i /v "hash"') do set hashCalculadoTrojan=%%A
        set "hashCalculadoTrojan=!hashCalculadoTrojan: =!"
        if /i "!hashCalculadoTrojan!"=="25f6bd59559b25b60881a92353bf0e9f" (
            echo TROJAN_7.BIN es la última R7 modificada por hugopocked.
        ) else if /i "!hashCalculadoTrojan!"=="7bbcb73e5f2e068d735573e62c80bd08" (
            echo TROJAN_7.BIN es la R7 sacada de elotrolado.
        ) else if /i "!hashCalculadoTrojan!"=="ca48a3e90d10866361faf008656c25b2" (
            echo TROJAN_7.BIN es la versión R6 sacada de ps2-home.
        ) else (
            echo TROJAN_7.BIN tiene un MD5 desconocido. Las versiones recomendadas son las mencionadas anteriormente.
        )

        echo.
        echo Aclaro no se que versión sea la correcta o mejor, pero estas son las 3 versiones que encontré:
        echo - MD5: 25f6bd59559b25b60881a92353bf0e9f - Última R7 modificada por hugopocked -Año-2024-
        echo - MD5: 7bbcb73e5f2e068d735573e62c80bd08 - R7 sacada de elotrolado -Año-2021-
        echo - MD5: ca48a3e90d10866361faf008656c25b2 - R6 sacada de ps2-home -Año-2020-
        echo.

        set hashPendriveTrojan=!hashCalculadoTrojan!
    ) else (
        echo Falta el archivo TROJAN_7.BIN. Es opcional, aunque se recomienda ya que soluciona problemas en varios juegos.
        echo.
        echo Aclaro no se que versión sea la correcta o mejor, pero estas son las 3 versiones que encontré:
        echo - MD5: 25f6bd59559b25b60881a92353bf0e9f - Última R7 modificada por hugopocked -Año-2024-
        echo - MD5: 7bbcb73e5f2e068d735573e62c80bd08 - R7 sacada de elotrolado -Año-2021-
        echo - MD5: ca48a3e90d10866361faf008656c25b2 - R6 Sacada de ps2-home -Año-2020-
        echo.
        set faltaTROJAN=1
    )
) else (
    echo La carpeta /POPS/ no existe en la ruta seleccionada.
    set faltaPOPS_IOX=1
    set faltaPOPSTARTER=1
    set faltaTROJAN=1
    set archivosPendriveValidos=0
)

echo Terminada la verificacion de archivos en el pendrive.
pause
cls

echo "________          ________      _________              ";
echo "___  __ )____  __ ___  __ \___________  /____________ _";
echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
echo "        /____/                                         ";

echo " ____   __    ___  _____    ___  ";
echo "(  _ \ /__\  / __)(  _  )  (__ \ ";
echo " )___//(__)\ \__ \ )(_)(    / _/ ";
echo "(__) (__)(__)(___/(_____)  (____)";

echo Paso 2 Copia de Archivos necesarios para correr POPS o PS1
echo Verificando archivos en la carpeta del CMD...

@echo off
setlocal enabledelayedexpansion

:: Verificar si POPSTARTER.ELF existe
if exist "%ruta_inicial%\POPSTARTER.ELF" (
    echo POPSTARTER.ELF está presente en la ruta del CMD.
) else if exist "%ruta%/POPS/POPSTARTER.ELF" (
    echo POPSTARTER.ELF se encuentra en el pendrive.
) else (
    set "hash_objetivo=4a39d44dfb477ea747f5ca5e39ee011e"
    set "archivo_encontrado="
    set "ultimo_archivo="
    echo Buscando archivos POPSTARTER en %ruta_pendrive% y sus subdirectorios...
    for /r "%ruta%\" %%F in (XX.*.ELF) do (
        echo Verificando archivo: %%F
        set "ultimo_archivo=%%F"
        for /f "tokens=*" %%H in ('CertUtil -hashfile "%%F" MD5 ^| find /i /v "hash"') do set "hash_actual=%%H"
            set "!hash_actual=!hash_actual: =!"
            if /i "!hash_actual!"=="!hash_objetivo%!" (
                echo Archivo con hash objetivo encontrado: %%F
                set "archivo_encontrado=%%F"
                if defined archivo_encontrado (
                    echo Copiando !archivo_encontrado! a %ruta_inicial%\POPSTARTER.ELF...
                    copy "!archivo_encontrado!" "%ruta_inicial%\POPSTARTER.ELF" >nul
                    if %errorlevel%==0 (
                        echo Archivo copiado correctamente.
                    ) else (
                        echo Error al copiar el archivo.
                    )
                    goto :FINALIZAR_BUSQUEDA_POPSI
                ) else (
                    echo No se encontró ningún archivo para copiar.
                )
            )
    )

    :: Si no se encontró un archivo con el hash objetivo, usar el último archivo encontrado
    if defined ultimo_archivo (
        echo No se encontró un archivo con el hash objetivo. Usando el último archivo encontrado: !ultimo_archivo!
        set "archivo_encontrado=!ultimo_archivo!"
            if defined archivo_encontrado (
            echo Copiando !archivo_encontrado! a %ruta_inicial%\POPSTARTER.ELF...
            copy "!archivo_encontrado!" "%ruta_inicial%\POPSTARTER.ELF" >nul
            if %errorlevel%==0 (
                    echo Archivo copiado correctamente.
                ) else (
                    echo Error al copiar el archivo.
                )
            ) else (
                echo No se encontró ningún archivo para copiar.
            )
            goto :FINALIZAR_BUSQUEDA_POPSI
    ) else (
        echo No se encontró ningún archivo XX.*.ELF en %ruta%\.
        pause
        exit /b
    )
)

:FINALIZAR_BUSQUEDA_POPSI

:: Verificar si POPS_IOX.PAK existe
if exist "%ruta_inicial%\POPS_IOX.PAK" (
    echo POPS_IOX.PAK está presente en la ruta del CMD.
) else (
    echo POPS_IOX.PAK no se encuentra en la ruta del CMD.
)

pause

REM Mensajes finales y copia de archivos obligatorios
if "!archivosPendriveValidos!"=="1" (
    echo Todos los archivos necesarios están correctos en el pendrive. No es necesario copiarlos.
) else if "!archivosPendriveValidos!"=="0" (
    echo Para correr correctamente POPS se necesitan algunos archivos que estan ubicados en la carpeta CMD.
    set /p copiar=Desea copiarlos al pendrive? S/N: 
    if /i "!copiar!"=="S" (
        REM Crear la carpeta /POPS/ solo si no existe
        if not exist "%ruta%\POPS\" (
            echo Creando carpeta /POPS/ en el pendrive...
            mkdir "%ruta%\POPS"
        )
        if "!faltaPOPS_IOX!"=="1" (
            echo Copiando POPS_IOX.PAK...
            copy "POPS_IOX.PAK" "%ruta%\POPS"
        )
        if "!faltaPOPSTARTER!"=="1" (
            echo Copiando POPSTARTER.ELF...
            copy "POPSTARTER.ELF" "%ruta%\POPS"
        )
        echo Archivos copiados correctamente.
    )
) else (
    echo Faltan archivos necesarios para Correr POPS o PS1 en la ruta del CMD
    echo Descarguelos y extraigalos en la carpeta del ejecutable.
    echo el programa lo instalara donde sea necesario.
    echo.
    if not exist "POPSTARTER.ELF" (
        echo no existe POPSTARTER.ELF en la carpeta del Ejecutable
        echo para descargar POPSTARTER.ELF
        echo vaya a este enlace
        echo https://www.ps2-home.com/forum/viewtopic.php?f=19&t=1819
        echo.
    )
    if not exist "POPS_IOX.PAK" (
        echo para descargar POPS_IOX.PAK
        echo busque en internet es ilegal ponerlo aqui en el launcher
        echo su md5 es a625d0b3036823cdbf04a3c0e1648901
        echo de todas formas el programa lo verificara una vez este
        echo en la misma carpeta que el ejecutable.
        echo.
    )
    )

REM Verificar si TROJAN_7.BIN está en la carpeta del CMD
if exist "TROJAN_7.BIN" (
    echo Verificando MD5 de TROJAN_7.BIN en la carpeta del CMD...
    echo.
    for /f "tokens=*" %%A in ('CertUtil -hashfile "TROJAN_7.BIN" MD5 ^| find /i /v "hash"') do set hashCmdTrojan=%%A
    set "!hashCmdTrojan=!hashCmdTrojan: =!"
    if defined hashPendriveTrojan (
        if /i "!hashPendriveTrojan!" NEQ "!hashCmdTrojan!" (
            echo TROJAN_7.BIN tiene diferentes versiones:
            echo.
            echo - En el pendrive POPS: !hashPendriveTrojan!
            
            if /i "!hashPendriveTrojan!"=="25f6bd59559b25b60881a92353bf0e9f" (
            echo es la última R7 modificada por hugopocked.
            ) else if /i "!hashPendriveTrojan!"=="7bbcb73e5f2e068d735573e62c80bd08" (
            echo es la R7 sacada de elotrolado.
            ) else if /i "!hashPendriveTrojan!"=="ca48a3e90d10866361faf008656c25b2" (
            echo es la versión R6 sacada de ps2-home.
            ) else (
            echo tiene un MD5 desconocido.
            )

            echo.

            echo - En la carpeta del CMD: !hashCmdTrojan!
            if /i "!hashCmdTrojan!"=="25f6bd59559b25b60881a92353bf0e9f" (
            echo es la última R7 modificada por hugopocked.
            
            ) else if /i "!hashCmdTrojan!"=="7bbcb73e5f2e068d735573e62c80bd08" (
            echo es la R7 sacada de elotrolado.
            ) else if /i "!hashCmdTrojan!"=="ca48a3e90d10866361faf008656c25b2" (
            echo es la versión R6 sacada de ps2-home.
            ) else (
            echo tiene un MD5 desconocido.
            )
            echo.
            echo Aclaro no se que versión sea la correcta o mejor, pero estas son las 3 versiones que encontré:
            echo - MD5: 25f6bd59559b25b60881a92353bf0e9f - Última R7 modificada por hugopocked -Año-2024-
            echo - MD5: 7bbcb73e5f2e068d735573e62c80bd08 - R7 sacada de elotrolado -Año-2021-
            echo - MD5: ca48a3e90d10866361faf008656c25b2 - R6 sacada de ps2-home -Año-2020-
            echo.
            set /p reemplazar=Desea reemplazar el TROJAN_7.BIN del pendrive con el de la carpeta CMD? S/N: 
            if /i "!reemplazar!"=="S" (
                echo Reemplazando TROJAN_7.BIN en el pendrive...
                copy /y "TROJAN_7.BIN" "%ruta%\POPS"
            ) else (
                echo No se reemplazó TROJAN_7.BIN en el pendrive.
            )
        ) else if "!faltaTROJAN!"=="1" (
            echo Copiando TROJAN_7.BIN al pendrive...
            copy "TROJAN_7.BIN" "%ruta%\POPS"
        ) else (
            echo Ya se tiene un TROJAN_7 bin y es el mismo en la carpeta cmd como del pen.
        )
    
    )
)else (
    echo No se encontró TROJAN_7.BIN en la carpeta del CMD.
    echo este es opcional aunque lo recomiendo
     echo para descargar TROJAN_7.BIN
    echo hay varios enlaces
    echo para la ultima version modificada por hugopocked
    echo https://www.mediafire.com/file/c6eqcx81yn3n8yu/Cumulative_r7_Disabled_something_XD.rar/file
    echo para la version de elotrolado
    echo https://mega.nz/file/YpBTkAyR#BX9IzbfQy7mxNYzPkvvfYyimoP7vhgkfTMwULwK94z0
    echo para la version de ps2-home
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

echo " ____   __    ___  _____    ___ ";
echo "(  _ \ /__\  / __)(  _  )  (__ )";
echo " )___//(__)\ \__ \ )(_)(    (_ \";
echo "(__) (__)(__)(___/(_____)  (___/";

echo Paso 3 Revision de conf_apps.cfg
:: Cambiar a la unidad F:
%ruta%

if not exist "!ruta_inicial!\!carpeta_backup_cmd!" (
   mkdir "!ruta_inicial!\!carpeta_backup_cmd!"
)
:: Archivo de configuración
set "archivo_cfg=%ruta%conf_apps.cfg"

:: Variables para almacenar errores
set "incorrectos_cfg="
set "incorrectos_msj="
set "incorrecto_nivel="
set "incorrecto_nivel_temp="
set "contador=0"
set "contadorlimpio=0"
set "variable_nombre="
set "variable_ruta_nombre="

:: Leer el archivo línea por línea

for /f "tokens=1,* delims==" %%A in ('type "%archivo_cfg%"') do (

    if "%%B"=="" (
        set /a contadorlimpio+=1
        set "nombre_cfg=%%A"
        set "ruta_cfg1=%ruta%\POPS\XX.%%A.ELF"
        set "ruta_cfg2=%ruta%\POPS\%%A.VCD"
        if not exist "!ruta_cfg2!" (
            set "variable_ruta_nombre[!contadorlimpio!]=!nombre_cfg!"
            set "incorrectos_msj[!contadorlimpio!]=Linea !contadorlimpio!: No se encuentra la ROM de !nombre_cfg!"
            set "incorrectos_sol[!contadorlimpio!]=Solucion: Eliminar la linea, no existe la ROM ni siquiera con su nombre nominal en la carpeta POPS"
            set "incorrecto_nivel[!contadorlimpio!]=7"
            if not exist "!ruta_cfg1!" (
                set "variable_ruta_nombre[!contadorlimpio!]=!nombre_cfg!"
                set "incorrectos_msj[!contadorlimpio!]=Linea !contadorlimpio!: No se encuentra Nada con !nombre_cfg! incluso con su nombre nominal"
                set "incorrectos_sol[!contadorlimpio!]=Solucion: Eliminar la linea, no existe la ROM y ELF ni siquiera con su nombre nominal en la carpeta POPS"
                set "incorrecto_nivel[!contadorlimpio!]=8"
            )
        ) else (
            set "variable_ruta_nombre[!contadorlimpio!]=!nombre_cfg!"
            set "incorrectos_msj[!contadorlimpio!]=Linea !contadorlimpio!: Parece que la ROM de !nombre_cfg! existe para agregar a conf_apps.cfg"
            set "incorrectos_sol[!contadorlimpio!]=Solucion: reparar Ruta del launcher"
            set "incorrecto_nivel[!contadorlimpio!]=4"
            if not exist "!ruta_cfg1!" (
                set "variable_ruta_nombre[!contadorlimpio!]=!nombre_cfg!"
                set "incorrectos_msj[!contadorlimpio!]=Linea !contadorlimpio!: Parece que la ROM de !nombre_cfg! existe pero no su ELF para agregar a conf_apps.cfg"
                set "incorrectos_sol[!contadorlimpio!]=Solucion: reparar Ruta del launcher"
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
        set "incorrectos_msj[!contadorlimpio!]=Linea !contadorlimpio!: !nombre_cfg! Parece andar Perfectamente"
        set "incorrectos_sol[!contadorlimpio!]=Solucion: No se necesita esta todo correcto"
        set "incorrecto_nivel[!contadorlimpio!]=0"

        :: Verificar existencia del launcher
        set "temp_ruta_launcher=!ruta_cfg:mass:/=%ruta%!"
        if not exist "!temp_ruta_launcher!" (
            set "incorrectos_msj[!contadorlimpio!]=Linea !contadorlimpio!: Launcher de !nombre_cfg! no existe"
            set "incorrectos_sol[!contadorlimpio!]=Solucion: Crear Launcher para el juego .VCD"
            set "incorrecto_nivel[!contadorlimpio!]=1"
            set "incorrecto_nivel_temp=1"
        )

        :: Verificar existencia de la ROM
        set "temp_ruta_vcd=%ruta%POPS/!ruta_cfg:~14,-4!.VCD"
        if not exist "!temp_ruta_vcd!" (
            set "incorrectos_msj[!contadorlimpio!]=Linea !contadorlimpio!: No se encuentra la ROM de !nombre_cfg!"
            set "incorrectos_sol[!contadorlimpio!]=Solucion: Eliminar la linea, no existe la ROM en la carpeta POPS"
            set "incorrecto_nivel[!contadorlimpio!]=6"
            set "incorrecto_nivel_temp=6"
        )

        if !incorrecto_nivel_temp!==6 (
            set "testear_ruta=%ruta%/POPS/!nombre_cfg!.VCD"
            set "testear_ruta2=%ruta%/POPS/XX.!nombre_cfg!.ELF"
            if not exist "!testear_ruta!" (
                echo "!testear_ruta!"
                set "incorrectos_msj[!contadorlimpio!]=Linea !contadorlimpio!: No se encuentra la ROM de !nombre_cfg! incluso con su nombre nominal"
                set "incorrectos_sol[!contadorlimpio!]=Solucion: Eliminar la linea, no existe la ROM ni siquiera con su nombre nominal en la carpeta POPS"
                set "incorrecto_nivel[!contadorlimpio!]=7"
            ) else (
                set "incorrecto_nivel[!contadorlimpio!]=2"
                set "incorrectos_msj[!contadorlimpio!]=Linea !contadorlimpio!: Se encuentra la ROM de !nombre_cfg! usando formato nominal"
                set "incorrectos_sol[!contadorlimpio!]=Solucion: Reparar la ruta de la ROM en conf_apps.cfg"
                if not exist "!testear_ruta2!" (
                    set "incorrecto_nivel[!contadorlimpio!]=3"
                    set "incorrectos_msj[!contadorlimpio!]=Linea !contadorlimpio!: Se encuentra la ROM de !nombre_cfg! usando formato nominal pero no su ELF"
                    set "incorrectos_sol[!contadorlimpio!]=Solucion: Reparar la ruta de la ROM y agregar laucher en la carpeta POPS"
                )
            )
        )
    )
)

:: Mostrar errores
echo Correccion de conf_apps.cfg:
echo.
copy /y "%archivo_cfg%" "%ruta_inicial%\!carpeta_backup_cmd!\conf_apps.cfg" >nul
(for /l %%I in (1,1,!contadorlimpio!) do (

    if !incorrecto_nivel[%%I]! LSS 6 (
    call echo !incorrectos_msj[%%I]!
    call echo Nivel del Error: !incorrecto_nivel[%%I]!
    call echo !incorrectos_sol[%%I]!
    call echo.
    )
)) > Dianostico_Reparables-conf_apps.cfg.txt
move /y "Dianostico_Reparables-conf_apps.cfg.txt" "%ruta_inicial%\!carpeta_backup_cmd!\Dianostico_Reparables-conf_apps.cfg.txt" >nul

(for /l %%I in (1,1,!contadorlimpio!) do (

    if !incorrecto_nivel[%%I]! GTR 5 (
    call echo !incorrectos_msj[%%I]!
    call echo Nivel del Error: !incorrecto_nivel[%%I]!
    call echo !incorrectos_sol[%%I]!
    call echo.
    )
))> Dianostico_Irreparables-conf_apps.cfg.txt
move /y "Dianostico_Irreparables-conf_apps.cfg.txt" "%ruta_inicial%\!carpeta_backup_cmd!\Dianostico_Irreparables-conf_apps.cfg.txt" >nul
echo conf_apps.cfg Se arreglara de forma automatica al presionar la proxima tecla
echo.
echo se guardara un backup de conf_apps.cfg en la carpeta 
echo %ruta_inicial%\!carpeta_backup_cmd!
echo tambien se guardara los datos de diagnostico en la misma carpeta
echo.
pause
set "contara=0"
    echo Aplicando correcciones...
    (for /f "usebackq delims=" %%L in ("%archivo_cfg%") do (
    set "linea=%%L"
    set /a contara+=1
    setlocal enabledelayedexpansion
    set "guardar=1"
    :: Verificar si la línea debe ser eliminada
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
echo Verificando entradas duplicadas en conf_apps.cfg...
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

echo Borradas !entradas_duplicadas! entradas duplicadas.

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

echo " ____   __    ___  _____     __  ";
echo "(  _ \ /__\  / __)(  _  )   /. | ";
echo " )___//(__)\ \__ \ )(_)(   (_  _)";
echo "(__) (__)(__)(___/(_____)    (_) ";

echo Paso 4 Verificacion Reparacion y instalacion de archivos locales .VCD 

:: Escanear todos los .VCD en F:\ y sus subdirectorios, excepto \POPS\
echo Escaneando archivos .VCD mal ubicados !ruta!\ y subdirectorios (excepto \POPS\)...
set "archivos_mal_ubicados=0"
for /r "%ruta%" %%F in (*.VCD) do (
    set "archivo_vcd=%%~nxF"
    set "ruta_vcd=%%~dpF"
    if /i not "%%~dpF"=="%ruta%\POPS\" (
        echo Archivo mal ubicado: %%F
        set /a archivos_mal_ubicados+=1
        set "archivo_mal_ubicado[!archivos_mal_ubicados!]=%%~fF"
    )
)

:: Mostrar archivos mal ubicados
if !archivos_mal_ubicados! GTR 0 (
    echo Se encontraron los siguientes archivos .VCD mal ubicados:
    for /l %%I in (1,1,!archivos_mal_ubicados!) do (
        echo [%%I] !archivo_mal_ubicado[%%I]!
    )
    echo.
    set /p "mover_archivos=¿Desea moverlos a la carpeta \POPS\? (S/N): "
    if /i "!mover_archivos!"=="S" (
        echo Moviendo archivos .VCD a la carpeta \POPS\...
        for /l %%I in (1,1,!archivos_mal_ubicados!) do (
            move "!archivo_mal_ubicado[%%I]!" "%ruta%\POPS\" >nul
            echo Archivo movido: !archivo_mal_ubicado[%%I]!
        )
        echo Todos los archivos mal ubicados fueron movidos a \POPS\.
    ) else (
        echo No se movieron los archivos mal ubicados.
    )
) else (
    echo No se encontraron archivos .VCD mal ubicados.
)
echo.
pause
:: Eliminando archivos huérfanos .ELF
echo Verificando archivos ELF huerfanos...
for %%F in ("%ruta%\POPS\XX.*.ELF") do (
    set "archivo_elf=%%~nxF"
    set "nombre_sin_extension=!archivo_elf:XX.=!"
    set "nombre_sin_extension=!nombre_sin_extension:.ELF=!"
    if not exist "%ruta%\POPS\!nombre_sin_extension!.VCD" (
        echo Eliminando archivo huérfano: %%F
        del "%%F"
    )
)

:: Verificar archivos .VCD que no estén en conf_apps.cfg
echo Agregando Juegos .VCD en conf_apps.cfg \\\ Creando Launcher ELF \\\ Creando Carpetas...
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
        echo Archivo .VCD no encontrado en conf_apps.cfg: %%F
        echo Añadiendo entrada a conf_apps.cfg...
        echo !nombre_sin_extension!=mass:/POPS/XX.!nombre_sin_extension!.ELF>>"%archivo_cfg%"
        if not exist "%ruta%\POPS\XX.!nombre_sin_extension!.ELF" (
            echo Copiando POPSTARTER.ELF como XX.!nombre_sin_extension!.ELF...
            copy "%ruta_inicial%\POPSTARTER.ELF" "%ruta%\POPS\XX.!nombre_sin_extension!.ELF" >nul
        )
        if not exist "%ruta%\POPS\!nombre_sin_extension!\" (
            echo Creando carpeta: %ruta%\POPS\!nombre_sin_extension!
            mkdir "%ruta%\POPS\!nombre_sin_extension!" >nul
        )
    )
)

echo Verificación y correcciones completadas.


pause
cls

echo "________          ________      _________              ";
echo "___  __ )____  __ ___  __ \___________  /____________ _";
echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
echo "        /____/                                         ";

echo " ____   __    ___  _____    ___ ";
echo "(  _ \ /__\  / __)(  _  )  | __)";
echo " )___//(__)\ \__ \ )(_)(   |__ \";
echo "(__) (__)(__)(___/(_____)  (___/";

echo Paso 5 Instalacion de archivos locales .VCD
set "contador=0"
set "total_directorios=0"

:: Consultar si incluir subdirectorios
set /p "instalar_VCD_CMD=¿Desea instalar los juegos guardados en la ruta del ejecutable (S/N): "
if /i "!instalar_VCD_CMD!"=="S" (
    set /p "incluir_subdirs=¿Desea copiar también los juegos guardados en subdirectorios? (S/N): "
    if /i "!incluir_subdirs!"=="S" (
        echo Buscando archivos .VCD en el directorio y subdirectorios...
        for /r "%ruta_inicial%" %%F in (*.VCD) do (
            set "archivo=%%~nxF"
            set "ruta=%%~dpF"
            set /a contador+=1
            set "ruta_de_copiado[!contador!]=%%~dpF"
            set "archivo_nombre[!contador!]=%%~nxF"
            echo Archivo encontrado: !archivo! en !ruta!
        )
    ) else (
        echo Buscando archivos .VCD solo en el directorio raíz...
        for %%F in ("%ruta_inicial%\*.VCD") do (
            set "archivo=%%~nxF"
            set "ruta=%%~dpF"
            set /a contador+=1
            set "ruta_de_copiado[!contador!]=%%~dpF"
            set "archivo_nombre[!contador!]=%%~nxF"
            echo Archivo encontrado: !archivo! en !ruta!
        )
    )

    :: Mostrar archivos encontrados
    if !contador! GTR 0 (
        echo Se encontraron los siguientes archivos .VCD:
        for /l %%I in (1,1,!contador!) do (
            echo [%%I] !archivo_nombre[%%I]! en !ruta_de_copiado[%%I]!
        )
        set /p "confirmar_copia=¿Desea copiarlos todos? (S/N): "
        if /i "!confirmar_copia!"=="S" (
            echo Iniciando copia de archivos...
            for /l %%I in (1,1,!contador!) do (
                set "archivo=!archivo_nombre[%%I]!"
                set "ruta=!ruta_de_copiado[%%I]!"
                set "nombre_sin_extension=!archivo:.VCD=!"
                if exist "%ruta%\POPS\!archivo!" (
                    echo Omitiendo !archivo! porque ya existe en %ruta%\POPS.
                ) else (
                    echo Copiando !archivo! desde !ruta! a %ruta%\POPS...
                    copy "!ruta!\!archivo!" "%ruta%\POPS" >nul
                    echo Copiado !archivo!.

                    :: Crear carpeta con el mismo nombre (sin extensión)
                    mkdir "%ruta%\POPS\!nombre_sin_extension!" >nul
                    echo Carpeta creada: %ruta%\POPS\!nombre_sin_extension!

                    :: Copiar POPSTARTER.ELF con nuevo nombre
                    if exist "%cd%\POPSTARTER.ELF" (
                        copy "%cd%\POPSTARTER.ELF" "%ruta%\POPS\XX.!nombre_sin_extension!.ELF" >nul
                        echo Archivo POPSTARTER.ELF copiado como XX.!nombre_sin_extension!.ELF.
                    ) else (
                        echo Error: POPSTARTER.ELF no encontrado en el directorio actual.
                    )

                    :: Agregar línea al archivo conf_apps.cfg
                    echo !nombre_sin_extension!=mass:/POPS/XX.!nombre_sin_extension!.ELF>>"F:\conf_apps.cfg"
                    echo Línea agregada a conf_apps.cfg: !nombre_sin_extension!=mass:/POPS/XX.!nombre_sin_extension!.ELF
                )
            )
            echo Copia completada.
        ) else (
            echo Copia cancelada.
        )
    ) else (
        echo No se encontraron archivos .VCD.
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

echo " ____   __    ___  _____     _  ";
echo "(  _ \ /__\  / __)(  _  )   / ) ";
echo " )___//(__)\ \__ \ )(_)(   / _ \";
echo "(__) (__)(__)(___/(_____)  \___/";

echo Paso 6 Instalacion de CHEATS.TXT

echo Que Hace CHEATS.TXT? aparte de guardar trucos, Modifica formato de pantalla
echo.
echo No apto para tontos, puede funcionar pero solo si sabe lo que hace
echo Puede impedir que se corra correctamente uno\todos los juegos asi que uselo con cuidado
echo Mejora la resolución de los juegos de PS1 en varios casos
echo.
echo Si no funciona algun juego en particular simplemente borre el archivo CHEATS.TXT
echo De la carpeta del juego o determinadas lineas
echo.
echo No se preocupe que no se borrará ni sobreescribira el archivo original. Solo se Actualizara
echo En caso de que funcione mal se guardara un Backup en la carpeta !carpeta_backup_cmd!\Cheats.TXT
echo.
set /p "crear_cheats= Desea Crear/Actualizar archivo CHEATS.TXT [S/N]? Ponga [H] para ayuda: "
echo !crear_cheats! asd
if /i "!crear_cheats!" == "N" (
    echo No se creará el archivo CHEATS.TXT.
    pause
) else if /i "!crear_cheats!" == "S" (
    echo Seleccione la calidad deseada:
    echo [1] Digital 480p - Mejor calidad no compatible con algunas consolas
    echo     mejor dicho con cable RCA o cable clásico de PS1.
    echo     No funciona en Algunos juegos aunque solo el 5%
    echo [2] Analógica NTSC América - Compatible con todos los juegos y cables.
    echo [3] Analógica PAL Europa - Compatible con todos los juegos y cables.
    set /p "calidad=Ingrese su opción 1-2-3: "
            echo Creando archivo de borrado...
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
        echo Creando archivo temporal para calidad digital...
        (
            echo $SAFEMODE
            echo $SMOOTH
            echo $480p
        ) > temp_CHEAT.txt
    ) else if "!calidad!"=="2" (
        echo Creando archivo temporal para calidad analógica NTSC...
        (
            echo $SAFEMODE
            echo $SMOOTH
            echo $NOPAL
            echo $YPOS_0
            echo $XPOS_576
        ) > temp_CHEAT.txt
    ) else if "!calidad!"=="3" (
        echo Creando archivo temporal para calidad analógica PAL...
        (
            echo $SAFEMODE
            echo $SMOOTH
            echo $FORCEPAL
            echo $YPOS_0
            echo $XPOS_576
        ) > temp_CHEAT.txt
    ) else (
        echo Opción no válida. Saliendo...
        pause
    )

    :: Navegar por las carpetas dentro de \POPS\ que cumplan con las condiciones
    echo Navegando por las carpetas dentro de \POPS\...
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
                echo Escaneando el archivo CHEATS.TXT en la carpeta del juego: !solo_nombre!
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
                echo Creando CHEATS.TXT en la carpeta del juego: !carpeta!
                copy /y temp_CHEAT.txt "%%D\CHEATS.TXT" >nul
                echo CHEATS.TXT creado en %%D
            )
        )
    )

    :: Eliminar archivo temporal
    del temp_CHEAT.txt >nul
    del temp_del_CHEAT.txt >nul
    del temp_resultado_CHEATS.TXT >nul
    :: Advertencia final
    echo.
    echo se ha hecho un backup de CHEATS.TXT en la carpeta Backup Cheats.TXT!hora_actual!\
    echo Si no llega a andar algún juego, pruebe eliminar CHEATS.TXT de la carpeta de ese juego en \POPS\.
    pause
) else if /i "!crear_cheats!" == "H" (
    cls
    echo "________          ________      _________              ";
    echo "___  __ )____  __ ___  __ \___________  /____________ _";
    echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
    echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
    echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
    echo "        /____/                                         ";

    echo " ____   __    ___  _____     _  ";
    echo "(  _ \ /__\  / __)(  _  )   / ) ";
    echo " )___//(__)\ \__ \ )(_)(   / _ \";
    echo "(__) (__)(__)(___/(_____)  \___/";
    echo.
    echo los archivos CHEATS.TXT se guardan en !ruta!\POPS\Carpeta del Juego\CHEATS.TXT
    echo en caso de no funcionarle algun juego en especifico simplemente cambielo
    echo para hacer funcionar cada configuracion simplemente agregue el signo $ y el comando
    echo.
    echo Comandos que nunca tiene que quitar
    echo $SAFEMODE
    echo.
    echo Comandos para Suavizar texturas
    echo $SMOOTH
    echo.
    echo Comando para correr en Digital
    echo $480p
    echo Y Comandos que dejan de funcionar con Digital
    echo $YPOS_
    echo $XPOS_
    echo.
    echo Comando para correr en NTSC
    echo Solo si no corre en digital
    echo recomendado para televisores de America[Latina/Yanqui]
    echo $NOPAL
    echo $YPOS_numero deseado
    echo $XPOS_numero deseado
    echo.
    echo Comando para correr PAL
    echo Solo si no corre en digital
    echo recomendado para televisores de Europa[Coño/Tio]
    echo $FORCEPAL
    echo $YPOS_numero deseado
    echo $XPOS_numero deseado
    echo.
    pause
    goto continuar6
) else (
    echo no se Actualizo CHEATS.TXT
)
cls
pause

echo "________          ________      _________              ";
echo "___  __ )____  __ ___  __ \___________  /____________ _";
echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
echo "        /____/                                         ";

echo " ____   __    ___  _____    ___ ";
echo "(  _ \ /__\  / __)(  _  )  (__ )";
echo " )___//(__)\ \__ \ )(_)(    / / ";
echo "(__) (__)(__)(___/(_____)  (_/  ";

echo Paso 7 Cambiar Nombre de Archivos ELF
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
                        echo El nombre del launcher no coincide con la descripción:
                        echo Nombre: !nombre_cfg!
                        echo Launcher: !verif_nombre!
                        set /p "cambiar=¿Desea cambiarlo? s/n: "
                        if /i "!cambiar!"=="s" (
                            echo Renombrando archivos...

                            echo ruta: !ruta!POPS
                            cd "!ruta!\POPS"
                            echo Renombrando: "XX.!verif_nombre!.ELF" a "XX.!nombre_cfg!.ELF"
                            ren "XX.!verif_nombre!.ELF" "XX.!nombre_cfg!.ELF"
                            echo Renombrando: "!verif_nombre!.VCD" a "!nombre_cfg!.VCD"
                            ren "!verif_nombre!.VCD" "!nombre_cfg!.VCD"
                            cd "!ruta!\ART"
                            for %%F in (_BG.png _COV.png _COV2.png _ICO.png _LAB.png _LGO.png _SCR.png _SCR2.png _BG.jpg _COV.jpg _COV2.jpg _ICO.jpg _LAB.jpg _LGO.jpg _SCR.jpg _SCR2.jpg _BG.jpeg _COV.jpeg _COV2.jpeg _ICO.jpeg _LAB.jpeg _LGO.jpeg _SCR.jpeg _SCR2.jpeg) do (
                                echo Renombrando: "XX.!verif_nombre!.ELF%%F" a "XX.!nombre_cfg!.ELF%%F"
                                ren "XX.!verif_nombre!.ELF%%F" "XX.!nombre_cfg!.ELF%%F"
                            )
                            cd "!ruta!\CFG"
                            echo Renombrando: "XX.!verif_nombre!.cfg" a "XX.!nombre_cfg!.cfg"
                            ren "XX.!verif_nombre!.cfg" "XX.!nombre_cfg!.cfg"
                            cd "!ruta!"

                            echo Actualizando conf_apps.cfg...
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

                        echo " ____   __    ___  _____    ___ ";
                        echo "(  _ \ /__\  / __)(  _  )  (__ )";
                        echo " )___//(__)\ \__ \ )(_)(    / / ";
                        echo "(__) (__)(__)(___/(_____)  (_/  ";
                    )
                ) else (
                    cls
                    echo "________          ________      _________              ";
                    echo "___  __ )____  __ ___  __ \___________  /____________ _";
                    echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
                    echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
                    echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
                    echo "        /____/                                         ";

                    echo " ____   __    ___  _____    ___ ";
                    echo "(  _ \ /__\  / __)(  _  )  (__ )";
                    echo " )___//(__)\ \__ \ )(_)(    / / ";
                    echo "(__) (__)(__)(___/(_____)  (_/  ";
                    echo Tienes una entrada mal escrita en cfg 
                    echo en la linea !contadorlinea! vuelve a ejecutar el programa
                    echo y activa/utiliza la correccion automatica de cfg
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

                echo " ____   __    ___  _____    ___ ";
                echo "(  _ \ /__\  / __)(  _  )  (__ )";
                echo " )___//(__)\ \__ \ )(_)(    / / ";
                echo "(__) (__)(__)(___/(_____)  (_/  ";
                echo Tienes una entrada mal escrita en cfg
                echo en la linea !contadorlinea! vuelve a ejecutar el programa
                echo y activa/utiliza la correccion automatica de cfg
                pause
            )
            cls
            echo "________          ________      _________              ";
            echo "___  __ )____  __ ___  __ \___________  /____________ _";
            echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
            echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
            echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
            echo "        /____/                                         ";

            echo " ____   __    ___  _____    ___ ";
            echo "(  _ \ /__\  / __)(  _  )  (__ )";
            echo " )___//(__)\ \__ \ )(_)(    / / ";
            echo "(__) (__)(__)(___/(_____)  (_/  ";
)

cls

echo "________          ________      _________              ";
echo "___  __ )____  __ ___  __ \___________  /____________ _";
echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
echo "        /____/                                         ";

echo " ____   __    ___  _____    ___ ";
echo "(  _ \ /__\  / __)(  _  )  ( _ )";
echo " )___//(__)\ \__ \ )(_)(   / _ \";
echo "(__) (__)(__)(___/(_____)  \___/";

echo Paso 8 Ordenar Lineas de conf_apps.cfg alfabéticamente
echo.

set /p "ordenar=¿Desea ordenar alfabéticamente las entradas de conf_apps.cfg? (S/N): "
if /i "!ordenar!" NEQ "S" (
    echo No se ordenará el archivo conf_apps.cfg.
) else if not exist "%archivo_cfg%" (
    echo El archivo conf_apps.cfg no existe en la ruta especificada.
) else (
    :: Ordenar las líneas alfabéticamente
    echo Ordenando las entradas de conf_apps.cfg...
    (for /f "usebackq delims=" %%A in ("%archivo_cfg%") do (
        echo %%A
    )) > "%archivo_cfg%.tmp"

    :: Usar sort para ordenar las líneas alfabéticamente
    sort "%archivo_cfg%.tmp" /o "%archivo_cfg%"

    :: Eliminar archivo temporal
    del "%archivo_cfg%.tmp" >nul

    echo Archivo conf_apps.cfg ordenado correctamente.
)

pause
cls

echo "________          ________      _________              ";
echo "___  __ )____  __ ___  __ \___________  /____________ _";
echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
echo "        /____/                                         ";

echo " ____   __    ___  _____    ___ ";
echo "(  _ \ /__\  / __)(  _  )  / _ \";
echo " )___//(__)\ \__ \ )(_)(   \_  /";
echo "(__) (__)(__)(___/(_____)   (_/ ";

echo Paso 9 Configuracion multidisco
echo.
echo desea escanear juegos multidisco en la carpeta \POPS\?:
echo seleccione parametros de idioma de busqueda de multidiscos:
echo [1] [100 vel]Solo Metodos de abreviacion estandar[mas rapido][menos certero]
echo [2]  [54 vel]Español Portugués Ingles Español c/detalles
echo [3]  [50 vel]Español Portugués Ingles Italiano
echo [4]  [70 vel]Inglés
echo [5]  [58 vel]Alemán Ingles
echo [6]  [58 vel]Francés Ingles
echo [7]  [39 vel]Todos los idiomas[Mas Lento][Mas certero]
echo [8] para salir
set /p "opcion=Seleccione una opción (1-6): "
if "%opcion%"=="1" (
    set "parametros_multidisco=;CD1;CD$1;CD.1;CD:1;CD:$1;CD.$1;DVD1;DVD$1;DVD.1;DVD:1;DVD:$1;DVD.$1;D$1;D:$1;D:1;D1;D.1;DSC1;DSC$1;DSC.1;DSC:1;DSC:$1;DSC.$1;DSK1;DSK$1;DSK.1;DSK:1;DSK:$1;DSK.$1;DSCK1;DSCK$1;DSCK.1;DSCK:1;DSCK:$1;DSCK.$1;" 
) else if "%opcion%"=="2" (
    set "parametros_multidisco=;CD1;CD$1;CD.1;CD:1;CD:$1;CD.$1;DVD1;DVD$1;DVD.1;DVD:1;DVD:$1;DVD.$1;D$1;Disc1;Disc$1;Disc.1;Disc:1;Disc:$1;Disc.$1;Disk$1;DISCS$1;DISKS$1;Disco$1;Discos$1;Diskos$1;D:$1;Disk:$1;DISCS:$1;DISKS:$1;Disco:$1;Discos:$1;Diskos:$1;D:1;Disk:1;DISCS:1;DISKS:1;Disco:1;Discos:1;Diskos:1;D1;D.1;Disk.1;Disk1;DISCS.1;DISCS1;DISKS.1;DISKS1;Disco.1;Disco1;Discos.1;Discos1;Diskos.1;DSC1;DSC$1;DSC.1;DSC:1;DSC:$1;DSC.$1;DSK1;DSK$1;DSK.1;DSK:1;DSK:$1;DSK.$1;DSCK1;DSCK$1;DSCK.1;DSCK:1;DSCK:$1;DSCK.$1;Diskos.$1;Diskos.1;" 
) else if "%opcion%"=="3" (
    set "parametros_multidisco=;CD1;CD$1;CD.1;CD:1;CD:$1;CD.$1;DVD1;DVD$1;DVD.1;DVD:1;DVD:$1;DVD.$1;D$1;Disc1;Disc$1;Disc.1;Disc:1;Disc:$1;Disc.$1;Disk$1;DISCS$1;DISKS$1;D:$1;Disk:$1;DISCS:$1;DISKS:$1;D:1;Disk:1;DISCS:1;DISKS:1;D1;D.1;Disk.1;Disk1;DISCS.1;DISCS1;DISKS.1;DISKS1;Disco$1;Discos$1;Disco:$1;Discos:$1;Disco:1;Discos:1;Disco.1;Disco1;Discos.1;Discos1;Dischi$1;Dischi:$1;Dischi:1;Dischi.1;Dischi1;DSC1;DSC$1;DSC.1;DSC:1;DSC:$1;DSC.$1;DSK1;DSK$1;DSK.1;DSK:1;DSK:$1;DSK.$1;DSCK1;DSCK$1;DSCK.1;DSCK:1;DSCK:$1;DSCK.$1;Diskos$1;Diskos:$1;Diskos:1;Diskos.1;Diskos.$1;"
) else if "%opcion%"=="4" (
    set "parametros_multidisco=;CD1;CD$1;CD.1;CD:1;CD:$1;CD.$1;DVD1;DVD$1;DVD.1;DVD:1;DVD:$1;DVD.$1;D$1;Disc1;Disc$1;Disc.1;Disc:1;Disc:$1;Disc.$1;Disk$1;DISCS$1;DISKS$1;D:$1;Disk:$1;DISCS:$1;DISKS:$1;D:1;Disk:1;DISCS:1;DISKS:1;D1;D.1;Disk.1;Disk1;DISCS.1;DISCS1;DISKS.1;DISKS1;DSC1;DSC$1;DSC.1;DSC:1;DSC:$1;DSC.$1;DSK1;DSK$1;DSK.1;DSK:1;DSK:$1;DSK.$1;DSCK1;DSCK$1;DSCK.1;DSCK:1;DSCK:$1;DSCK.$1;"
) else if "%opcion%"=="5" (
    set "parametros_multidisco=;CD1;CD$1;CD.1;CD:1;CD:$1;CD.$1;DVD1;DVD$1;DVD.1;DVD:1;DVD:$1;DVD.$1;D$1;Disc1;Disc$1;Disc.1;Disc:1;Disc:$1;Disc.$1;Disk$1;DISCS$1;DISKS$1;D:$1;Disk:$1;DISCS:$1;DISKS:$1;D:1;Disk:1;DISCS:1;DISKS:1;D1;D.1;Disk.1;Disk1;DISCS.1;DISCS1;DISKS.1;DISKS1;Scheibe$1;Scheiben$1;Scheibe:$1;Scheiben:$1;Scheibe:1;Scheiben:1;Scheibe.1;Scheibe1;Scheiben.1;Scheiben1;DSC1;DSC$1;DSC.1;DSC:1;DSC:$1;DSC.$1;DSK1;DSK$1;DSK.1;DSK:1;DSK:$1;DSK.$1;DSCK1;DSCK$1;DSCK.1;DSCK:1;DSCK:$1;DSCK.$1;"
) else if "%opcion%"=="6" (
    set "parametros_multidisco=;CD1;CD$1;CD.1;CD:1;CD:$1;CD.$1;DVD1;DVD$1;DVD.1;DVD:1;DVD:$1;DVD.$1;D$1;Disc1;Disc$1;Disc.1;Disc:1;Disc:$1;Disc.$1;Disk$1;DISCS$1;DISKS$1;D:$1;Disk:$1;DISCS:$1;DISKS:$1;D:1;Disk:1;DISCS:1;DISKS:1;D1;D.1;Disk.1;Disk1;DISCS.1;DISCS1;DISKS.1;DISKS1;Disque$1;Disques$1;Disque:$1;Disques:$1;Disque:1;Disques:1;Disque.1;Disque1;Disques.1;Disques1;DSC1;DSC$1;DSC.1;DSC:1;DSC:$1;DSC.$1;DSK1;DSK$1;DSK.1;DSK:1;DSK:$1;DSK.$1;DSCK1;DSCK$1;DSCK.1;DSCK:1;DSCK:$1;DSCK.$1;"
) else if "%opcion%"=="7" (
    set "parametros_multidisco=;CD1;CD$1;CD.1;CD:1;CD:$1;CD.$1;DVD1;DVD$1;DVD.1;DVD:1;DVD:$1;DVD.$1;D$1;Disc1;Disc$1;Disc.1;Disc:1;Disc:$1;Disc.$1;Disk$1;DISCS$1;DISKS$1;D:$1;Disk:$1;DISCS:$1;DISKS:$1;D:1;Disk:1;DISCS:1;DISKS:1;D1;D.1;Disk.1;Disk1;DISCS.1;DISCS1;DISKS.1;DISKS1;Disco$1;Discos$1;Disco:$1;Discos:$1;Disco:1;Discos:1;Disco.1;Disco1;Discos.1;Discos1;Dischi$1;Dischi:$1;Dischi:1;Dischi.1;Dischi1;Disque$1;Disques$1;Disque:$1;Disques:$1;Disque:1;Disques:1;Disque.1;Disque1;Disques.1;Disques1;Scheibe$1;Scheiben$1;Scheibe:$1;Scheiben:$1;Scheibe:1;Scheiben:1;Scheibe.1;Scheibe1;Scheiben.1;Scheiben1;DSC1;DSC$1;DSC.1;DSC:1;DSC:$1;DSC.$1;DSK1;DSK$1;DSK.1;DSK:1;DSK:$1;DSK.$1;DSCK1;DSCK$1;DSCK.1;DSCK:1;DSCK:$1;DSCK.$1;Diskos$1;Diskos:$1;Diskos:1;Diskos.1;Diskos.$1;"
) else if "%opcion%"=="8" (
    echo No se escanearán juegos multidisco.
    pause
    goto :eof
) else (
    echo No se escanearán juegos multidisco.
    pause
    goto :eof
)

del vcd_list.txt >nul 2>&1

:: Ruta base de la carpeta POPS
set "ruta_pops=F:\POPS"

:: Crear un archivo temporal con los nombres de los archivos .VCD y ordenarlos alfabéticamente
echo Escaneando y ordenando archivos .VCD en \POPS\...
dir /b /a-d "%ruta_pops%\*.VCD" | sort > vcd_list.txt


:: Inicializar variables
set "fecha=!date!"
set "fecha=!fecha:/=-!"

RD /S /Q "%cd%\temp_POPS !fecha!"

:: Agrupar juegos multidisco
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
                            REM Aquí puedes colocar el código que se ejecutará si la condición es verdadera
                        ) else (
                            REM Aquí puedes colocar el código que se ejecutará si la condición es falsa
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
                    if not !variable_guardada!=="" (
                        echo "!archivo!" | findstr /I /C:"!variable_guardada!" > nul 2>&1
                        if !errorlevel! equ 0 (
                            REM Aquí puedes colocar el código que se ejecutará si la condición es verdadera
                            set variable_nombre_archivo=%%F
                            set "posibles_multidisco=1"
                            set "parametros_multidisco_acertados=!variable_guardada!"
                        ) else (
                            REM Aquí puedes colocar el código que se ejecutará si la condición es falsa
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
    echo No se encontraron juegos multidisco.
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

    echo " ____   __    ___  _____    ___ ";
    echo "(  _ \ /__\  / __)(  _  )  / _ \";
    echo " )___//(__)\ \__ \ )(_)(   \_  /";
    echo "(__) (__)(__)(___/(_____)   (_/ ";
    echo.
    echo Posibles multidisco:
    type "%%T"

    :: Consultar si se desea configurar multidisco
    set "configurar="
    set /p "configurar=¿Desea configurar multidisco? (S/N): "
    if /i "!configurar!" NEQ "S" (
        echo %%~nT no se ha configurado.
    ) else (
        set nombre_principal=%%~nT
        set nombre_principal=!nombre_principal:~0,-4!
        echo Configurando multidisco para !nombre_principal!...
    
        
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
    echo Archivos DISCS.TXT y VMCDIR.TXT creados correctamente.
    echo Configuración completada para %%~nT.
    pause
    cls
    echo "________          ________      _________              ";
    echo "___  __ )____  __ ___  __ \___________  /____________ _";
    echo "__  __  |_  / / / __  /_/ /  __ \  __  /__  ___/  __ `/";
    echo "_  /_/ /_  /_/ /  _  _, _// /_/ / /_/ / _  /   / /_/ / ";
    echo "/_____/ _\__, /   /_/ |_| \____/\__,_/  /_/    \__,_/  ";
    echo "        /____/                                         ";

    echo " ____   __    ___  _____    ___ ";
    echo "(  _ \ /__\  / __)(  _  )  / _ \";
    echo " )___//(__)\ \__ \ )(_)(   \_  /";
    echo "(__) (__)(__)(___/(_____)   (_/ ";
    echo.
    )
)

RD /S /Q "%cd%\temp_POPS !fecha!"

del vcd_list.txt >nul
pause