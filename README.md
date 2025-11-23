# API Distributed File Analyzer

![Architecture](https://img.shields.io/badge/Architecture-Microservices-blue)
![Python](https://img.shields.io/badge/Python-3.11-green)
![Node](https://img.shields.io/badge/Node-20-green)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)

**Proyecto de portafolio** que demuestra arquitectura de microservicios profesional con procesamiento distribuido de archivos.

## 🎯 Objetivo del Proyecto

Este proyecto es una **demostración técnica** diseñada para mostrar:
- Arquitectura de microservicios escalable
- Procesamiento asíncrono con colas
- Integración de múltiples tecnologías backend
- Buenas prácticas de desarrollo y documentación

**No es un producto final**, sino un showcase de habilidades backend.

---

## 🏗️ Arquitectura

```
Cliente HTTP
    ↓
┌─────────────────────────────────────┐
│  Gateway Service (Node.js/Express)  │
│  - Autenticación JWT                │
│  - Rate Limiting                    │
│  - API Gateway                      │
└─────────────┬───────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ Analyzer Service (Python/FastAPI)   │
│  - Procesamiento de archivos        │
│  - Gestión de tareas                │
└───┬──────────────────────┬──────────┘
    ↓                      ↓
┌─────────┐          ┌──────────┐
│  Redis  │          │PostgreSQL│
│  Queue  │          │   DB     │
└─────────┘          └──────────┘
    ↓                      ↑
┌─────────┐                │
│  Worker │────────────────┘
│ Process │          ┌──────────┐
└─────────┘          │ MongoDB  │
                     │   Logs   │
                     └──────────┘
```

**Ver:** [architecture-diagram.md](./architecture-diagram.md) para detalles completos.

---

## 🛠️ Stack Tecnológico

### Gateway Service (Puerto 3000)
- **Node.js 20** + Express.js
- **JWT** para autenticación
- **Redis** para rate limiting
- **PostgreSQL** para usuarios

### Analyzer Service (Puerto 8000)
- **Python 3.11** + FastAPI
- **Redis Queue (RQ)** para procesamiento asíncrono
- **PostgreSQL** para tareas y resultados
- **MongoDB** para logs y auditoría
- **OpenAPI/Swagger** documentación automática

### Infraestructura
- **Docker** y **Docker Compose**
- **PostgreSQL 15**
- **MongoDB 7**
- **Redis 7**

---

## 🚀 Cómo Levantar el Proyecto

### Prerrequisitos
- Docker y Docker Compose instalados
- Puertos disponibles: 3000, 8000, 5432, 27017, 6379

### Pasos

1. **Clonar el repositorio**
```bash
git clone https://github.com/tu-usuario/api-distributed-file-analyzer.git
cd api-distributed-file-analyzer
```

2. **Configurar variables de entorno**
```bash
cp .env.example .env
# Editar .env si es necesario (valores por defecto funcionan)
```

3. **Levantar todos los servicios**
```bash
docker-compose up --build
```

4. **Esperar a que todo esté listo** (~30 segundos)
```
✓ PostgreSQL ready
✓ MongoDB ready
✓ Redis ready
✓ Gateway Service running on port 3000
✓ Analyzer Service running on port 8000
✓ Worker process started
```

5. **Acceder a la documentación**
- Gateway API: http://localhost:3000/health
- Analyzer API: http://localhost:8000/docs (Swagger UI)
- OpenAPI Schema: http://localhost:8000/openapi.json

---

## 📡 Endpoints y Flujo de Uso

### 1. Registro de Usuario
```bash
POST http://localhost:3000/api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepass123",
  "name": "John Doe"
}

# Response: 201 Created
{
  "message": "User registered successfully",
  "userId": "uuid-here"
}
```

### 2. Login
```bash
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepass123"
}

# Response: 200 OK
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

### 3. Subir Archivo para Análisis
```bash
POST http://localhost:3000/api/analyzer/upload
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: multipart/form-data

file: [tu_archivo.txt/csv/json]

# Response: 202 Accepted
{
  "taskId": "task-uuid",
  "status": "queued",
  "message": "File uploaded and queued for processing"
}
```

### 4. Consultar Estado de Tarea
```bash
GET http://localhost:3000/api/analyzer/tasks/{taskId}
Authorization: Bearer YOUR_JWT_TOKEN

# Response mientras procesa: 200 OK
{
  "taskId": "task-uuid",
  "status": "processing",
  "filename": "archivo.txt",
  "createdAt": "2025-01-15T10:30:00Z"
}

# Response cuando termina: 200 OK
{
  "taskId": "task-uuid",
  "status": "completed",
  "filename": "archivo.txt",
  "result": {
    "fileSize": 1024,
    "lineCount": 42,
    "wordCount": 256,
    "characterCount": 1024,
    "processingTime": "2.3s"
  },
  "createdAt": "2025-01-15T10:30:00Z",
  "completedAt": "2025-01-15T10:30:02Z"
}
```

### 5. Listar Todas las Tareas del Usuario
```bash
GET http://localhost:3000/api/analyzer/tasks
Authorization: Bearer YOUR_JWT_TOKEN

# Response: 200 OK
{
  "tasks": [
    {
      "taskId": "uuid-1",
      "status": "completed",
      "filename": "file1.txt",
      "createdAt": "..."
    },
    {
      "taskId": "uuid-2",
      "status": "processing",
      "filename": "file2.csv",
      "createdAt": "..."
    }
  ]
}
```

---

## 🧪 Testing con cURL

```bash
# 1. Registrar usuario
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123","name":"Test User"}'

# 2. Login
TOKEN=$(curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}' \
  | jq -r '.token')

# 3. Subir archivo
TASK_ID=$(curl -X POST http://localhost:3000/api/analyzer/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@test.txt" \
  | jq -r '.taskId')

# 4. Consultar estado
curl http://localhost:3000/api/analyzer/tasks/$TASK_ID \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🔍 Características Técnicas Destacadas

### Seguridad
- ✅ Autenticación JWT con expiración
- ✅ Passwords hasheados con bcrypt
- ✅ Rate limiting por IP (100 req/15min)
- ✅ Validación de tokens en cada request

### Escalabilidad
- ✅ Procesamiento asíncrono con Redis Queue
- ✅ Workers escalables independientes
- ✅ Microservicios desacoplados
- ✅ Bases de datos separadas por función

### Observabilidad
- ✅ Logs estructurados en MongoDB
- ✅ Timestamps en todas las operaciones
- ✅ Estados de tareas rastreables
- ✅ Auditoría de eventos

### Buenas Prácticas
- ✅ Código organizado por capas (routes/controllers/services)
- ✅ Variables de entorno para configuración
- ✅ Manejo centralizado de errores
- ✅ Documentación OpenAPI automática
- ✅ Docker multi-stage builds
- ✅ Health checks en servicios

---

## 📂 Estructura de Código

```
gateway-service/
├── src/
│   ├── index.js              # Entry point
│   ├── config/               # Configuraciones (DB, Redis)
│   ├── middleware/           # Auth, Rate Limit, Errors
│   ├── routes/               # Definición de rutas
│   ├── controllers/          # Lógica de negocio
│   ├── models/               # Modelos de datos
│   └── utils/                # Helpers (JWT, etc)

analyzer-service/
├── app/
│   ├── main.py               # Entry point FastAPI
│   ├── config.py             # Configuración centralizada
│   ├── database.py           # Conexiones DB
│   ├── models/               # Modelos SQLAlchemy y Pydantic
│   ├── routes/               # Routers FastAPI
│   ├── services/             # Lógica de negocio
│   └── workers/              # Worker de procesamiento
```

---

## 🎓 Uso como Proyecto de Portafolio

### Para Presentarlo
1. **En tu CV/LinkedIn:**
   - "Sistema de microservicios con procesamiento distribuido"
   - "API RESTful con autenticación JWT y colas asíncronas"
   
2. **En entrevistas:**
   - Explica la arquitectura y por qué elegiste cada tecnología
   - Demuestra el flujo completo (registro → upload → worker → resultado)
   - Menciona las decisiones técnicas (PostgreSQL vs MongoDB, Redis Queue)

3. **En tu portafolio web:**
   - Link al repositorio GitHub
   - Screenshots de Swagger UI
   - Diagrama de arquitectura
   - Métricas: "4 servicios, 3 DBs, procesamiento asíncrono"

### Mejoras Futuras Sugeridas
Para expandir el proyecto puedes agregar:
- [ ] Tests unitarios y de integración (Pytest, Jest)
- [ ] CI/CD con GitHub Actions
- [ ] Monitoring con Prometheus + Grafana
- [ ] Deploy en AWS/GCP con Kubernetes
- [ ] WebSockets para notificaciones en tiempo real
- [ ] Procesamiento de imágenes con OpenCV
- [ ] Caché con Redis para resultados frecuentes

---

## 🛑 Detener el Proyecto

```bash
docker-compose down           # Detener servicios
docker-compose down -v        # Detener y eliminar volúmenes (limpieza total)
```

---

## 📝 Licencia

MIT License - Este proyecto es open source y de uso educativo.

---

## 👨‍💻 Autor

**Anthony Romero aka fendifps**
- GitHub: [@fendifps](https://github.com/fendifps)
- LinkedIn: [Anthony Romero](https://www.linkedin.com/in/anthony-romero-32867b309/)
- Portfolio: [arrn](https://arrn-portfolio.netlify.app/)

---

## 🙏 Agradecimientos

Proyecto creado como demostración técnica para portafolio profesional.

**Stack:** Node.js • Python • FastAPI • Express • PostgreSQL • MongoDB • Redis • Docker