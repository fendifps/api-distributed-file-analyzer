@echo off
REM ================================================================================
REM API Distributed File Analyzer - Windows Setup Script
REM Este script automatiza la descarga, configuración e inicio del proyecto
REM ================================================================================

setlocal EnableDelayedExpansion
title API Distributed File Analyzer - Setup

REM Colores usando PowerShell
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "BLUE=[94m"
set "NC=[0m"

echo.
echo ================================================================================
echo   API Distributed File Analyzer - Setup para Windows
echo ================================================================================
echo.

REM ============================================================================
REM 1. VERIFICAR PRERREQUISITOS
REM ============================================================================

:check_prerequisites
echo [%BLUE%INFO%NC%] Verificando prerrequisitos...
echo.

REM Verificar Git
where git >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [%RED%ERROR%NC%] Git no esta instalado
    echo [%YELLOW%SOLUCION%NC%] Descarga Git desde: https://git-scm.com/download/win
    pause
    exit /b 1
) else (
    echo [%GREEN%OK%NC%] Git instalado
)

REM Verificar Docker Desktop
where docker >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [%RED%ERROR%NC%] Docker no esta instalado
    echo [%YELLOW%SOLUCION%NC%] Descarga Docker Desktop desde: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
) else (
    echo [%GREEN%OK%NC%] Docker instalado
)

REM Verificar que Docker esté corriendo
docker ps >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [%RED%ERROR%NC%] Docker Desktop no esta corriendo
    echo [%YELLOW%SOLUCION%NC%] Inicia Docker Desktop y ejecuta este script nuevamente
    pause
    exit /b 1
) else (
    echo [%GREEN%OK%NC%] Docker Desktop esta corriendo
)

REM Verificar Docker Compose
docker-compose --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [%RED%ERROR%NC%] Docker Compose no esta instalado
    pause
    exit /b 1
) else (
    echo [%GREEN%OK%NC%] Docker Compose instalado
)

echo.
echo [%GREEN%EXITO%NC%] Todos los prerrequisitos estan instalados
echo.
pause

REM ============================================================================
REM 2. CLONAR O USAR REPOSITORIO
REM ============================================================================

:setup_repository
cls
echo.
echo ================================================================================
echo   Configuracion del Repositorio
echo ================================================================================
echo.
echo Opciones:
echo   1. Crear estructura de carpetas en el directorio actual
echo   2. Clonar desde GitHub (si ya subiste el repo)
echo   3. Salir
echo.
set /p repo_choice="Selecciona una opcion (1-3): "

if "%repo_choice%"=="1" goto create_structure
if "%repo_choice%"=="2" goto clone_repo
if "%repo_choice%"=="3" exit /b 0
goto setup_repository

:clone_repo
echo.
set /p repo_url="Ingresa la URL del repositorio GitHub: "
echo.
echo [%BLUE%INFO%NC%] Clonando repositorio...
git clone %repo_url% api-distributed-file-analyzer
cd api-distributed-file-analyzer
echo [%GREEN%OK%NC%] Repositorio clonado
goto setup_environment

:create_structure
echo.
echo [%BLUE%INFO%NC%] Creando estructura de carpetas...

REM Crear directorios principales
if not exist "gateway-service" mkdir gateway-service
if not exist "analyzer-service" mkdir analyzer-service
if not exist "scripts" mkdir scripts

REM Gateway Service
mkdir gateway-service\src\config 2>nul
mkdir gateway-service\src\middleware 2>nul
mkdir gateway-service\src\routes 2>nul
mkdir gateway-service\src\controllers 2>nul
mkdir gateway-service\src\models 2>nul
mkdir gateway-service\src\utils 2>nul

REM Analyzer Service
mkdir analyzer-service\app\models 2>nul
mkdir analyzer-service\app\routes 2>nul
mkdir analyzer-service\app\services 2>nul
mkdir analyzer-service\app\workers 2>nul

echo [%GREEN%OK%NC%] Estructura de carpetas creada
echo.
echo [%YELLOW%IMPORTANTE%NC%] Ahora debes copiar todos los archivos de codigo
echo que te proporcione Claude en sus respectivas carpetas.
echo.
echo Estructura creada:
echo   - gateway-service/
echo   - analyzer-service/
echo   - scripts/
echo.
echo Presiona cualquier tecla cuando hayas copiado todos los archivos...
pause >nul

REM ============================================================================
REM 3. CONFIGURAR AMBIENTE
REM ============================================================================

:setup_environment
cls
echo.
echo ================================================================================
echo   Configuracion del Ambiente
echo ================================================================================
echo.

REM Crear archivo .env
if exist ".env" (
    echo [%YELLOW%ADVERTENCIA%NC%] El archivo .env ya existe
    set /p overwrite="Deseas sobrescribirlo? (S/N): "
    if /i not "!overwrite!"=="S" goto skip_env
)

echo [%BLUE%INFO%NC%] Creando archivo .env...

(
echo # Gateway Service Configuration
echo NODE_ENV=development
echo PORT=3000
echo JWT_SECRET=your-super-secret-jwt-key-change-in-production
echo JWT_EXPIRES_IN=24h
echo.
echo # Analyzer Service Configuration
echo ENVIRONMENT=development
echo.
echo # PostgreSQL Configuration
echo POSTGRES_HOST=postgres
echo POSTGRES_PORT=5432
echo POSTGRES_DB=fileanalyzer
echo POSTGRES_USER=admin
echo POSTGRES_PASSWORD=admin123
echo.
echo # MongoDB Configuration
echo MONGODB_HOST=mongodb
echo MONGODB_PORT=27017
echo MONGODB_USER=admin
echo MONGODB_PASSWORD=admin123
echo MONGODB_DB=logs
echo.
echo # Redis Configuration
echo REDIS_HOST=redis
echo REDIS_PORT=6379
echo.
echo # Service URLs
echo ANALYZER_SERVICE_URL=http://analyzer:8000
echo.
echo # File Upload Configuration
echo UPLOAD_DIR=/app/uploads
echo MAX_UPLOAD_SIZE=10485760
) > .env

echo [%GREEN%OK%NC%] Archivo .env creado
goto pull_images

:skip_env
echo [%BLUE%INFO%NC%] Usando archivo .env existente

REM ============================================================================
REM 4. DESCARGAR IMAGENES DOCKER
REM ============================================================================

:pull_images
echo.
echo ================================================================================
echo   Descargando Imagenes Docker
echo ================================================================================
echo.
echo [%BLUE%INFO%NC%] Esto puede tomar varios minutos...
echo.

echo [%BLUE%INFO%NC%] Descargando PostgreSQL 15...
docker pull postgres:15-alpine
echo [%GREEN%OK%NC%] PostgreSQL descargado
echo.

echo [%BLUE%INFO%NC%] Descargando MongoDB 7...
docker pull mongo:7
echo [%GREEN%OK%NC%] MongoDB descargado
echo.

echo [%BLUE%INFO%NC%] Descargando Redis 7...
docker pull redis:7-alpine
echo [%GREEN%OK%NC%] Redis descargado
echo.

echo [%BLUE%INFO%NC%] Descargando Node.js 20...
docker pull node:20-alpine
echo [%GREEN%OK%NC%] Node.js descargado
echo.

echo [%BLUE%INFO%NC%] Descargando Python 3.11...
docker pull python:3.11-slim
echo [%GREEN%OK%NC%] Python descargado
echo.

echo [%GREEN%EXITO%NC%] Todas las imagenes base descargadas
echo.
pause

REM ============================================================================
REM 5. CONSTRUIR SERVICIOS
REM ============================================================================

:build_services
cls
echo.
echo ================================================================================
echo   Construyendo Servicios
echo ================================================================================
echo.
echo [%BLUE%INFO%NC%] Construyendo contenedores Docker...
echo [%BLUE%INFO%NC%] Esto puede tomar 5-10 minutos la primera vez...
echo.

docker-compose build

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [%RED%ERROR%NC%] Fallo al construir los servicios
    echo [%YELLOW%POSIBLES CAUSAS%NC%]:
    echo   1. Archivos faltantes en gateway-service o analyzer-service
    echo   2. Error en los Dockerfiles
    echo   3. Problema de conexion a internet
    echo.
    pause
    exit /b 1
)

echo.
echo [%GREEN%EXITO%NC%] Servicios construidos exitosamente
echo.
pause

REM ============================================================================
REM 6. INICIAR SERVICIOS
REM ============================================================================

:start_services
cls
echo.
echo ================================================================================
echo   Iniciando Servicios
echo ================================================================================
echo.
echo [%BLUE%INFO%NC%] Iniciando todos los servicios...
echo.

docker-compose up -d

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [%RED%ERROR%NC%] Fallo al iniciar los servicios
    pause
    exit /b 1
)

echo [%GREEN%OK%NC%] Servicios iniciados
echo.
echo [%BLUE%INFO%NC%] Esperando a que los servicios esten listos (30 segundos)...

timeout /t 30 /nobreak >nul

REM ============================================================================
REM 7. VERIFICAR ESTADO
REM ============================================================================

:check_status
cls
echo.
echo ================================================================================
echo   Estado de los Servicios
echo ================================================================================
echo.

docker-compose ps

echo.
echo ================================================================================
echo   Verificando Health Checks
echo ================================================================================
echo.

REM Verificar Gateway
curl -s http://localhost:3000/health >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [%GREEN%OK%NC%] Gateway Service esta corriendo en http://localhost:3000
) else (
    echo [%YELLOW%ADVERTENCIA%NC%] Gateway Service puede no estar listo aun
)

REM Verificar Analyzer
curl -s http://localhost:8000/health >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [%GREEN%OK%NC%] Analyzer Service esta corriendo en http://localhost:8000
) else (
    echo [%YELLOW%ADVERTENCIA%NC%] Analyzer Service puede no estar listo aun
)

REM ============================================================================
REM 8. MOSTRAR INFORMACION
REM ============================================================================

:show_info
echo.
echo ================================================================================
echo   INFORMACION DE ACCESO
echo ================================================================================
echo.
echo   Gateway Service:
echo     - URL:          http://localhost:3000
echo     - Health:       http://localhost:3000/health
echo     - Registro:     POST http://localhost:3000/api/auth/register
echo     - Login:        POST http://localhost:3000/api/auth/login
echo.
echo   Analyzer Service:
echo     - URL:          http://localhost:8000
echo     - Health:       http://localhost:8000/health
echo     - Docs:         http://localhost:8000/docs
echo     - OpenAPI:      http://localhost:8000/openapi.json
echo.
echo ================================================================================
echo   PRUEBA RAPIDA
echo ================================================================================
echo.
echo   1. Registrar usuario:
echo      curl -X POST http://localhost:3000/api/auth/register ^
echo        -H "Content-Type: application/json" ^
echo        -d "{\"email\":\"test@test.com\",\"password\":\"test123\",\"name\":\"Test User\"}"
echo.
echo   2. Login:
echo      curl -X POST http://localhost:3000/api/auth/login ^
echo        -H "Content-Type: application/json" ^
echo        -d "{\"email\":\"test@test.com\",\"password\":\"test123\"}"
echo.
echo ================================================================================
echo   COMANDOS UTILES
echo ================================================================================
echo.
echo   Ver logs:              docker-compose logs -f
echo   Detener servicios:     docker-compose down
echo   Reiniciar servicios:   docker-compose restart
echo   Limpiar todo:          docker-compose down -v
echo.
echo ================================================================================

REM Crear archivo de prueba
if not exist "test-sample.txt" (
    (
    echo This is a sample file for testing the API Distributed File Analyzer.
    echo The file contains multiple lines of text.
    echo Each line will be counted by the analyzer service.
    echo It also counts words and characters.
    echo This demonstrates the complete file processing workflow.
    ) > test-sample.txt
    echo [%GREEN%OK%NC%] Archivo de prueba creado: test-sample.txt
    echo.
)

REM Preguntar si abrir navegador
set /p open_browser="Deseas abrir la documentacion en el navegador? (S/N): "
if /i "%open_browser%"=="S" (
    start http://localhost:8000/docs
    start http://localhost:3000/health
)

echo.
echo [%GREEN%EXITO%NC%] Setup completado exitosamente!
echo.
echo Presiona cualquier tecla para ver el menu principal...
pause >nul

REM ============================================================================
REM 9. MENU PRINCIPAL
REM ============================================================================

:main_menu
cls
echo.
echo ================================================================================
echo   API Distributed File Analyzer - Menu Principal
echo ================================================================================
echo.
echo   1. Ver estado de servicios
echo   2. Ver logs en tiempo real
echo   3. Reiniciar servicios
echo   4. Detener servicios
echo   5. Iniciar servicios
echo   6. Abrir documentacion
echo   7. Limpiar todo (eliminar contenedores y volumenes)
echo   8. Ver informacion de acceso
echo   0. Salir
echo.
set /p menu_choice="Selecciona una opcion (0-8): "

if "%menu_choice%"=="1" goto show_status
if "%menu_choice%"=="2" goto show_logs
if "%menu_choice%"=="3" goto restart_services
if "%menu_choice%"=="4" goto stop_services
if "%menu_choice%"=="5" goto start_services
if "%menu_choice%"=="6" goto open_docs
if "%menu_choice%"=="7" goto clean_all
if "%menu_choice%"=="8" goto show_info_loop
if "%menu_choice%"=="0" goto exit_script
goto main_menu

:show_status
cls
echo.
echo ================================================================================
echo   Estado de los Servicios
echo ================================================================================
echo.
docker-compose ps
echo.
pause
goto main_menu

:show_logs
cls
echo.
echo ================================================================================
echo   Logs en Tiempo Real (Ctrl+C para salir)
echo ================================================================================
echo.
docker-compose logs -f
goto main_menu

:restart_services
echo.
echo [%BLUE%INFO%NC%] Reiniciando servicios...
docker-compose restart
echo [%GREEN%OK%NC%] Servicios reiniciados
timeout /t 3 >nul
goto main_menu

:stop_services
echo.
echo [%BLUE%INFO%NC%] Deteniendo servicios...
docker-compose down
echo [%GREEN%OK%NC%] Servicios detenidos
pause
goto main_menu

:open_docs
start http://localhost:8000/docs
start http://localhost:3000/health
echo [%GREEN%OK%NC%] Documentacion abierta en el navegador
timeout /t 2 >nul
goto main_menu

:clean_all
echo.
echo [%YELLOW%ADVERTENCIA%NC%] Esto eliminara TODOS los contenedores y volumenes
echo Perderas TODOS los datos (usuarios, tareas, logs)
echo.
set /p confirm="Estas seguro? (S/N): "
if /i not "%confirm%"=="S" goto main_menu
echo.
echo [%BLUE%INFO%NC%] Limpiando todo...
docker-compose down -v
echo [%GREEN%OK%NC%] Limpieza completada
pause
goto main_menu

:show_info_loop
call :show_info
pause
goto main_menu

:exit_script
echo.
echo [%BLUE%INFO%NC%] Saliendo...
echo [%YELLOW%NOTA%NC%] Los servicios seguiran corriendo en segundo plano
echo Para detenerlos ejecuta: docker-compose down
echo.
exit /b 0