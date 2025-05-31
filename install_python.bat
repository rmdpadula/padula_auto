@echo off
setlocal ENABLEDELAYEDEXPANSION

rem ========== CONFIGURACAO ==========
set "PYTHON_VERSION=3.13.3"
set "INSTALADOR=python-%PYTHON_VERSION%-amd64.exe"
set "VERSAO_INSTALADOR=%PYTHON_VERSION%"
set "CAMINHO_INSTALADOR=%~dp0utils\%INSTALADOR%"
set "LOG_FILE=%~dp0logs\python_instalacao.log"
set "NOME_MAQUINA=%COMPUTERNAME%"



rem ========== VERIFICAR PERMISSAO DE ADMINISTRADOR ==========
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    call :log "Por favor, execute este arquivo como administrador."
    echo.
    echo Pressione qualquer tecla para sair...
    pause >nul
    exit /b
)

rem ========== LIMPAR LOG ==========
> "%LOG_FILE%" rem inicia ou limpa o arquivo

rem ========== VERIFICAR PYTHON INSTALADO ==========
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :log "Python nao esta instalado. Iniciando instalacao..."
    goto :instalar_python
)

for /f "tokens=2 delims= " %%a in ('python --version 2^>nul') do (
    set "VERSAO_INSTALADA=%%a"
)
goto :verificar_versao

:verificar_versao
call :log "Python ja esta instalado. Versao encontrada: !VERSAO_INSTALADA!"

rem ========== COMPARAR VERSOES ==========
call :comparar_versoes !VERSAO_INSTALADA! %VERSAO_INSTALADOR%
if "!VERSAO_COMPARADA!"=="menor" (
    call :log "Versao instalada e mais antiga. Atualizando..."
    goto :instalar_python
) else (
    call :log "A versao instalada (!VERSAO_INSTALADA!) e igual ou mais recente que a do instalador (%VERSAO_INSTALADOR%)."
    call :log "Nenhuma acao necessaria."
    goto :verificar_instalacao
)

:comparar_versoes
setlocal
set "VERSAO_ATUAL=%~1"
set "VERSAO_NOVA=%~2"

rem Remover pontos para comparacao numerica
set "VA=%VERSAO_ATUAL:.=%"
set "VN=%VERSAO_NOVA:.=%"

rem Preencher zeros a direita para 6 digitos
:ajuste_va
if not "!VA:~5!"=="" goto :va_ok
set "VA=!VA!0"
goto :ajuste_va
:va_ok

:ajuste_vn
if not "!VN:~5!"=="" goto :vn_ok
set "VN=!VN!0"
goto :ajuste_vn
:vn_ok

if %VA% LSS %VN% (
    endlocal & set "VERSAO_COMPARADA=menor" & goto :eof
)
endlocal & set "VERSAO_COMPARADA=maior_ou_igual"
goto :eof

:instalar_python
call :log "Iniciando instalacao do Python..."
call :log "Executando instalador: %CAMINHO_INSTALADOR%"

start /wait "" "%CAMINHO_INSTALADOR%" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 >> "%LOG_FILE%" 2>&1

if %ERRORLEVEL% EQU 0 (
    call :log "INSTALACAO CONCLUIDA COM SUCESSO"
    call :log "Python instalado com sucesso!"
) else (
    call :log "FALHA NA INSTALACAO. CODIGO DE ERRO: %ERRORLEVEL%"
    call :log "Python falhou ao instalar. Verifique o log."
)

:verificar_instalacao
call :log "Verificando instalacao apos execucao:"
set "PYTHON_EXE="
for /d %%d in ("%ProgramFiles%\Python3*") do (
    if exist "%%d\python.exe" (
        set "PYTHON_EXE=%%d\python.exe"
    )
)

if defined PYTHON_EXE (
    for /f "tokens=2 delims= " %%v in ('"!PYTHON_EXE!" --version 2^>nul') do (
        set "PYTHON_DETECTADA=%%v"
    )
    call :log "Versao detectada: !PYTHON_DETECTADA!"
    call :log "Caminho do Python detectado: !PYTHON_EXE!"
) else (
    call :log "Nao foi possivel localizar o Python em %ProgramFiles%\Python3*"
)

call :log "Log salvo em: %LOG_FILE%"

rem ========== OPCIONAL: SOLICITAR REINICIO ==========
echo.
set /p REINICIAR="Deseja reiniciar o sistema agora? (S/N): "
if /i "!REINICIAR!"=="S" (
    call :log "Usuario optou por reiniciar o sistema."
    shutdown /r /t 0
) else (
    call :log "Usuario optou por nao reiniciar o sistema."
)
echo.
echo Pressione qualquer tecla para sair...
pause >nul
endlocal
goto :eof

rem ========== FUNCAO DE LOG COM DATA/HORA/NOME DA MAQUINA ==========
:log
set "MSG=%~1"
for /f "tokens=* delims=" %%a in ('powershell -Command "Get-Date -Format \"dd/MM/yyyy HH:mm:ss\""') do set "AGORA=%%a"
echo [%AGORA% - %NOME_MAQUINA%] %MSG%
echo [%AGORA% - %NOME_MAQUINA%] %MSG%>> "%LOG_FILE%"
goto :eof
