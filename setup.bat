@echo off
setlocal EnableDelayedExpansion

REM ================================================================================
REM   API Distributed File Analyzer - Setup Profesional
REM   Machine Learning + Semantic Search + Microservices
REM   Version 3.0 - Ultra Estable
REM ================================================================================

title API File Analyzer - Professional Setup

REM Verificar que estamos en el directorio correcto
if not exist "docker-compose.yml" (
    echo ERROR: No se encuentra docker-compose.yml
    echo Ejecuta este script desde la raiz del proyecto
    pause
    exit /b 1
)

REM Mantener ventana abierta
if "%1"=="" (
    cmd /k "%~f0 run"
    exit
)

cls
echo.
echo ================================================================================
echo.
echo           API DISTRIBUTED FILE ANALYZER - PROFESSIONAL SETUP
echo.
echo           Machine Learning + Semantic Search + Microservices
echo.
echo ================================================================================
echo.
timeout /t 2 /nobreak >nul

REM ============================================================================
REM   DETECTAR ESTADO DEL SISTEMA
REM ============================================================================

:detect_first_run
cls
echo.
echo [DETECCION] Analizando estado del sistema...
echo.

set FIRST_RUN=0
set IMAGES_EXIST=0
set CONTAINERS_EXIST=0
set RUNNING=0

REM Verificar imagenes
docker images 2>nul | findstr "api-distributed-file-analyzer" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    set IMAGES_EXIST=1
    echo [OK] Imagenes Docker encontradas
) else (
    set FIRST_RUN=1
    echo [INFO] No hay imagenes - Primera ejecucion
)

REM Verificar contenedores
docker-compose ps -a 2>nul | findstr "file-analyzer" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    set CONTAINERS_EXIST=1
    echo [OK] Contenedores encontrados
) else (
    echo [INFO] No hay contenedores creados
)

REM Verificar si esta corriendo
docker-compose ps 2>nul | findstr "Up" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    set RUNNING=1
    echo [OK] Sistema ya esta corriendo
    timeout /t 2 /nobreak >nul
    goto show_running_info
)

echo.
timeout /t 2 /nobreak >nul

REM ============================================================================
REM   VERIFICAR PRERREQUISITOS
REM ============================================================================

:check_prerequisites
cls
echo.
echo [PASO 1/7] VERIFICANDO PRERREQUISITOS
echo --------------------------------------------------------------------------------
echo.

where docker >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo [ERROR] Docker no esta instalado
    echo.
    echo Descarga Docker Desktop desde:
    echo https://www.docker.com/products/docker-desktop
    echo.
    pause
    exit /b 1
)
echo [OK] Docker instalado

docker ps >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo [ERROR] Docker Desktop no esta corriendo
    echo.
    echo Por favor inicia Docker Desktop y ejecuta este script nuevamente
    echo.
    pause
    exit /b 1
)
echo [OK] Docker Desktop corriendo

docker-compose --version >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo [ERROR] Docker Compose no esta instalado
    pause
    exit /b 1
)
echo [OK] Docker Compose instalado

echo.
echo [EXITO] Todos los prerrequisitos verificados
timeout /t 2 /nobreak >nul

REM ============================================================================
REM   VERIFICAR ESTRUCTURA
REM ============================================================================

:check_structure
cls
echo.
echo [PASO 2/7] VERIFICANDO ESTRUCTURA DEL PROYECTO
echo --------------------------------------------------------------------------------
echo.

set STRUCTURE_OK=1

if not exist "gateway-service\src" (
    echo [ERROR] Falta: gateway-service\src
    set STRUCTURE_OK=0
) else (
    echo [OK] gateway-service\src
)

if not exist "analyzer-service\app" (
    echo [ERROR] Falta: analyzer-service\app
    set STRUCTURE_OK=0
) else (
    echo [OK] analyzer-service\app
)

if not exist "analyzer-service\app\services\embedding_service.py" (
    echo [WARN] Falta: embedding_service.py (ML)
) else (
    echo [OK] embedding_service.py (ML)
)

if not exist "analyzer-service\app\routes\similarity.py" (
    echo [WARN] Falta: similarity.py (Busqueda)
) else (
    echo [OK] similarity.py (Busqueda)
)

if !STRUCTURE_OK! EQU 0 (
    echo.
    echo [ERROR] Estructura del proyecto incompleta
    set /p continue="Continuar de todos modos? (S/N): "
    if /i not "!continue!"=="S" exit /b 1
)

echo.
echo [EXITO] Estructura verificada
timeout /t 2 /nobreak >nul

REM ============================================================================
REM   CONFIGURAR VARIABLES DE ENTORNO
REM ============================================================================

:setup_env
cls
echo.
echo [PASO 3/7] CONFIGURANDO VARIABLES DE ENTORNO
echo --------------------------------------------------------------------------------
echo.

if exist ".env" (
    echo [INFO] Archivo .env ya existe
    set /p overwrite="Sobrescribir? (S/N): "
    if /i not "!overwrite!"=="S" (
        echo [INFO] Usando .env existente
        timeout /t 1 /nobreak >nul
        goto pull_images
    )
)

echo [INFO] Creando archivo .env...

(
echo # Gateway Service
echo NODE_ENV=development
echo PORT=3000
echo JWT_SECRET=your-super-secret-jwt-key-change-in-production
echo JWT_EXPIRES_IN=24h
echo.
echo # Analyzer Service
echo ENVIRONMENT=development
echo.
echo # PostgreSQL
echo POSTGRES_HOST=postgres
echo POSTGRES_PORT=5432
echo POSTGRES_DB=fileanalyzer
echo POSTGRES_USER=admin
echo POSTGRES_PASSWORD=admin123
echo.
echo # MongoDB
echo MONGODB_HOST=mongodb
echo MONGODB_PORT=27017
echo MONGODB_USER=admin
echo MONGODB_PASSWORD=admin123
echo MONGODB_DB=logs
echo.
echo # Redis
echo REDIS_HOST=redis
echo REDIS_PORT=6379
echo REDIS_DB=0
echo.
echo # Services
echo ANALYZER_SERVICE_URL=http://analyzer:8000
echo.
echo # Upload
echo UPLOAD_DIR=/app/uploads
echo MAX_UPLOAD_SIZE=10485760
) > .env

echo [OK] Archivo .env creado exitosamente
timeout /t 2 /nobreak >nul

REM ============================================================================
REM   DESCARGAR IMAGENES
REM ============================================================================

:pull_images
if !IMAGES_EXIST! EQU 1 (
    cls
    echo.
    echo [PASO 4/7] DESCARGA DE IMAGENES
    echo --------------------------------------------------------------------------------
    echo.
    echo [INFO] Imagenes ya descargadas - Saltando paso
    timeout /t 2 /nobreak >nul
    goto build_or_start
)

cls
echo.
echo [PASO 4/7] DESCARGANDO IMAGENES DOCKER
echo --------------------------------------------------------------------------------
echo.
echo [INFO] Esto puede tomar 5-10 minutos en la primera ejecucion
echo.

echo [INFO] Descargando PostgreSQL 15...
docker pull postgres:15-alpine
echo [OK] PostgreSQL descargado

echo [INFO] Descargando MongoDB 7...
docker pull mongo:7
echo [OK] MongoDB descargado

echo [INFO] Descargando Redis 7...
docker pull redis:7-alpine
echo [OK] Redis descargado

echo [INFO] Descargando Node.js 20...
docker pull node:20-alpine
echo [OK] Node.js descargado

echo [INFO] Descargando Python 3.11...
docker pull python:3.11-slim
echo [OK] Python descargado

echo.
echo [EXITO] Todas las imagenes descargadas
timeout /t 2 /nobreak >nul

REM ============================================================================
REM   CONSTRUIR O INICIAR
REM ============================================================================

:build_or_start
if !IMAGES_EXIST! EQU 1 if !CONTAINERS_EXIST! EQU 1 (
    cls
    echo.
    echo [INFO] Sistema ya configurado - Iniciando servicios...
    timeout /t 2 /nobreak >nul
    goto start_services
)

REM ============================================================================
REM   CONSTRUIR SERVICIOS
REM ============================================================================

:build_services
cls
echo.
echo [PASO 5/7] CONSTRUYENDO SERVICIOS
echo --------------------------------------------------------------------------------
echo.
if !FIRST_RUN! EQU 1 (
    echo [INFO] Primera construccion: 10-15 minutos
    echo [INFO] Se descargara el modelo ML (aprox. 150MB)
) else (
    echo [INFO] Reconstruyendo: 2-3 minutos
)
echo.
echo Por favor espera...
echo.

docker-compose build

if !ERRORLEVEL! NEQ 0 (
    echo.
    echo [ERROR] Fallo al construir servicios
    echo.
    echo Posibles causas:
    echo   - Archivos faltantes
    echo   - Error en requirements.txt
    echo   - Conexion a internet
    echo.
    pause
    exit /b 1
)

echo.
echo [EXITO] Servicios construidos exitosamente
timeout /t 2 /nobreak >nul

REM ============================================================================
REM   INICIAR SERVICIOS
REM ============================================================================

:start_services
cls
echo.
echo [PASO 6/7] INICIANDO SERVICIOS
echo --------------------------------------------------------------------------------
echo.

docker-compose up -d

if !ERRORLEVEL! NEQ 0 (
    echo [ERROR] Fallo al iniciar servicios
    pause
    exit /b 1
)

echo [INFO] Esperando que los servicios esten listos (30 segundos)...
timeout /t 30 /nobreak >nul

REM ============================================================================
REM   VERIFICAR ESTADO
REM ============================================================================

:verify_status
cls
echo.
echo [PASO 7/7] VERIFICANDO ESTADO DE SERVICIOS
echo --------------------------------------------------------------------------------
echo.

docker-compose ps

echo.
echo [INFO] Verificando health checks...
echo.

curl -s http://localhost:3000/health >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo [OK] Gateway Service - http://localhost:3000
) else (
    echo [WARN] Gateway Service - Puede no estar listo aun
)

curl -s http://localhost:8000/health >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo [OK] Analyzer Service - http://localhost:8000
) else (
    echo [WARN] Analyzer Service - Puede no estar listo aun
)

echo.
timeout /t 3 /nobreak >nul
goto show_info

REM ============================================================================
REM   SISTEMA YA CORRIENDO
REM ============================================================================

:show_running_info
cls
echo.
echo ================================================================================
echo                    SISTEMA YA ESTA CORRIENDO
echo ================================================================================
echo.
echo Estado actual:
echo.

docker-compose ps

echo.
echo URLs disponibles:
echo   - Gateway:  http://localhost:3000/health
echo   - Analyzer: http://localhost:8000/docs
echo.
echo --------------------------------------------------------------------------------
echo.
set /p goto_menu="Ir al menu principal? (S/N): "
if /i "!goto_menu!"=="S" goto main_menu
echo.
pause
exit

REM ============================================================================
REM   MOSTRAR INFORMACION
REM ============================================================================

:show_info
cls
echo.
echo ================================================================================
echo                    SISTEMA INICIADO CORRECTAMENTE
echo ================================================================================
echo.
echo SERVICIOS DISPONIBLES:
echo --------------------------------------------------------------------------------
echo.
echo   Gateway Service:
echo   - URL:     http://localhost:3000
echo   - Health:  http://localhost:3000/health
echo   - API:     http://localhost:3000/api/auth
echo.
echo   Analyzer Service:
echo   - URL:     http://localhost:8000
echo   - Health:  http://localhost:8000/health
echo   - Docs:    http://localhost:8000/docs (Swagger UI)
echo.
echo FUNCIONES DE MACHINE LEARNING:
echo --------------------------------------------------------------------------------
echo.
echo   Busqueda Semantica:
echo   - GET /api/analyzer/similarity/search/:taskId
echo   - Encuentra documentos similares por contenido
echo.
echo   Comparacion de Documentos:
echo   - POST /api/analyzer/similarity/compare
echo   - Compara similitud entre dos documentos
echo.
echo   Modelo ML: all-MiniLM-L6-v2 (384D embeddings)
echo   Performance: aprox. 0.3s por documento
echo.
echo PRUEBA RAPIDA:
echo --------------------------------------------------------------------------------
echo.
echo   1. Registrar:  POST /api/auth/register
echo   2. Login:      POST /api/auth/login
echo   3. Subir:      POST /api/analyzer/upload
echo   4. Buscar ML:  GET /api/analyzer/similarity/search/:id
echo.
echo COMANDOS UTILES:
echo --------------------------------------------------------------------------------
echo.
echo   docker-compose logs -f         Ver logs en tiempo real
echo   docker-compose ps              Ver estado de servicios
echo   docker-compose restart         Reiniciar servicios
echo   docker-compose down            Detener servicios
echo   docker-compose down -v         Limpiar todo
echo.
echo ================================================================================

REM Crear archivo de prueba
if not exist "test-sample.txt" (
    (
    echo This is a sample file for testing the API Distributed File Analyzer.
    echo The file demonstrates ML embeddings and semantic similarity search.
    echo Python is used for the analyzer service with FastAPI framework.
    ) > test-sample.txt
    echo.
    echo [OK] Archivo de prueba creado: test-sample.txt
)

echo.
set /p open_browser="Abrir documentacion en el navegador? (S/N): "
if /i "!open_browser!"=="S" (
    start http://localhost:8000/docs
    start http://localhost:3000/health
)

echo.
echo [EXITO] Setup completado exitosamente
echo.
pause
goto main_menu

REM ============================================================================
REM   MENU PRINCIPAL
REM ============================================================================

:main_menu
cls
echo.
echo ================================================================================
echo                    API FILE ANALYZER - MENU PRINCIPAL
echo ================================================================================
echo.
echo   1. Ver estado de servicios
echo   2. Ver logs en tiempo real
echo   3. Ver logs del ML Worker
echo   4. Reiniciar servicios
echo   5. Detener servicios
echo   6. Iniciar servicios
echo   7. Abrir documentacion (Swagger)
echo   8. Ver informacion completa
echo   9. Limpiar todo (PRECAUCION)
echo   0. Salir
echo.
echo --------------------------------------------------------------------------------
echo.
set /p choice="Selecciona una opcion (0-9): "

if "%choice%"=="1" goto menu_status
if "%choice%"=="2" goto menu_logs
if "%choice%"=="3" goto menu_ml_logs
if "%choice%"=="4" goto menu_restart
if "%choice%"=="5" goto menu_stop
if "%choice%"=="6" goto menu_start
if "%choice%"=="7" goto menu_docs
if "%choice%"=="8" goto show_info
if "%choice%"=="9" goto menu_clean
if "%choice%"=="0" goto exit_script
goto main_menu

:menu_status
cls
echo.
echo ESTADO DE SERVICIOS
echo --------------------------------------------------------------------------------
echo.
docker-compose ps
echo.
echo --------------------------------------------------------------------------------
pause
goto main_menu

:menu_logs
cls
echo.
echo LOGS EN TIEMPO REAL (Ctrl+C para salir)
echo --------------------------------------------------------------------------------
echo.
docker-compose logs -f
goto main_menu

:menu_ml_logs
cls
echo.
echo LOGS DEL ML WORKER (Ctrl+C para salir)
echo --------------------------------------------------------------------------------
echo.
docker-compose logs -f analyzer worker
goto main_menu

:menu_restart
cls
echo.
echo [INFO] Reiniciando servicios...
docker-compose restart
echo [OK] Servicios reiniciados
timeout /t 3 /nobreak >nul
goto main_menu

:menu_stop
cls
echo.
echo [INFO] Deteniendo servicios...
docker-compose down
echo [OK] Servicios detenidos
echo.
pause
goto main_menu

:menu_start
cls
echo.
echo [INFO] Iniciando servicios...
docker-compose up -d
echo [OK] Servicios iniciados
timeout /t 3 /nobreak >nul
goto main_menu

:menu_docs
start http://localhost:8000/docs
start http://localhost:3000/health
cls
echo.
echo [OK] Documentacion abierta en el navegador
timeout /t 2 /nobreak >nul
goto main_menu

:menu_clean
cls
echo.
echo ADVERTENCIA: LIMPIEZA COMPLETA
echo --------------------------------------------------------------------------------
echo.
echo Esta accion eliminara:
echo   - Todos los contenedores
echo   - Todos los volumenes (datos de BD)
echo   - Usuarios registrados
echo   - Tareas procesadas
echo   - Embeddings generados
echo.
set /p confirm="Estas seguro? Escribe 'SI' para confirmar: "
if /i not "!confirm!"=="SI" (
    echo.
    echo [INFO] Operacion cancelada
    timeout /t 2 /nobreak >nul
    goto main_menu
)

echo.
echo [INFO] Limpiando sistema...
docker-compose down -v
echo [OK] Limpieza completada
echo.
echo El sistema ha sido restaurado a su estado inicial
echo Ejecuta este script nuevamente para reinstalar
echo.
pause
exit

:exit_script
cls
echo.
echo [INFO] Saliendo del script...
echo.
echo Los servicios seguiran corriendo en segundo plano
echo Para detenerlos ejecuta: docker-compose down
echo.
timeout /t 2 /nobreak >nul
exit