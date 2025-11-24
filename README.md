# API Distributed File Analyzer

![Architecture](https://img.shields.io/badge/Architecture-Microservices-blue)
![Python](https://img.shields.io/badge/Python-3.11-green)
![Node](https://img.shields.io/badge/Node-20-green)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![ML](https://img.shields.io/badge/ML-Embeddings-orange)

**Proyecto de portafolio** que demuestra arquitectura de microservicios profesional con procesamiento distribuido de archivos y búsqueda semántica con Machine Learning.

## 🎯 Objetivo del Proyecto

Este proyecto es una **demostración técnica** diseñada para mostrar:
- Arquitectura de microservicios escalable
- Procesamiento asíncrono con colas
- Integración de múltiples tecnologías backend
- **Machine Learning con embeddings semánticos**
- **Búsqueda por similitud de documentos**
- Buenas prácticas de desarrollo y documentación

**No es un producto final**, sino un showcase de habilidades backend y ML.

---

## 🏗️ ArquitecturaCliente HTTP
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
│  - Generación de embeddings ML      │
│  - Búsqueda por similitud           │
└───┬──────────────────────┬──────────┘
↓                      ↓
┌─────────┐          ┌──────────┐
│  Redis  │          │PostgreSQL│
│  Queue  │          │   + ML   │
└─────────┘          └──────────┘
↓                      ↑
┌─────────┐                │
│  Worker │────────────────┘
│ Process │          ┌──────────┐
│ + ML    │          │ MongoDB  │
└─────────┘          │   Logs   │
└──────────┘

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
- **Sentence Transformers** para embeddings (ML)
- **OpenAPI/Swagger** documentación automática

### Machine Learning
- **Model:** all-MiniLM-L6-v2 (22MB)
- **Embeddings:** 384 dimensiones
- **Búsqueda semántica:** Similaridad coseno
- **Performance:** ~0.3s por documento (CPU)

### Infraestructura
- **Docker** y **Docker Compose**
- **PostgreSQL 15** con soporte ARRAY para vectores
- **MongoDB 7**
- **Redis 7**

---

## 🚀 Cómo Levantar el Proyecto

### Prerrequisitos
- Docker y Docker Compose instalados
- Puertos disponibles: 3000, 8000, 5432, 27017, 6379

### Pasos

#### Opción 1: Setup Automático (Windows)
```cmdREM Ejecutar el script de setup
setup.bat

#### Opción 2: Manual

1. **Clonar el repositorio**
```bashgit clone https://github.com/tu-usuario/api-distributed-file-analyzer.git
cd api-distributed-file-analyzer

2. **Configurar variables de entorno**
```bashcp .env.example .env
Editar .env si es necesario (valores por defecto funcionan)

3. **Levantar todos los servicios**
```bashdocker-compose up --build

4. **Esperar a que todo esté listo** (~2 minutos)✓ PostgreSQL ready
✓ MongoDB ready
✓ Redis ready
✓ Gateway Service running on port 3000
✓ Analyzer Service running on port 8000
✓ Worker process started
✓ Embedding model loaded

5. **Acceder a la documentación**
- Gateway API: http://localhost:3000/health
- Analyzer API: http://localhost:8000/docs (Swagger UI)
- OpenAPI Schema: http://localhost:8000/openapi.json

---

## 📡 Endpoints y Flujo de Uso

### 1. Registro de Usuario
```bashPOST http://localhost:3000/api/auth/register
Content-Type: application/json{
"email": "user@example.com",
"password": "securepass123",
"name": "John Doe"
}Response: 201 Created
{
"message": "User registered successfully",
"userId": "uuid-here"
}

### 2. Login
```bashPOST http://localhost:3000/api/auth/login
Content-Type: application/json{
"email": "user@example.com",
"password": "securepass123"
}Response: 200 OK
{
"token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
"user": {
"id": "uuid",
"email": "user@example.com",
"name": "John Doe"
}
}

### 3. Subir Archivo para Análisis
```bashPOST http://localhost:3000/api/analyzer/upload
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: multipart/form-datafile: [tu_archivo.txt/csv/json]Response: 202 Accepted
{
"taskId": "task-uuid",
"status": "queued",
"message": "File uploaded and queued for processing"
}

### 4. Consultar Estado de Tarea
```bashGET http://localhost:3000/api/analyzer/tasks/{taskId}
Authorization: Bearer YOUR_JWT_TOKENResponse cuando termina: 200 OK
{
"taskId": "task-uuid",
"status": "completed",
"filename": "archivo.txt",
"result": {
"fileSize": 1024,
"lineCount": 42,
"wordCount": 256,
"characterCount": 1024,
"hasEmbedding": true,
"embeddingDimensions": 384,
"processingTime": "2.8s"
},
"has_embedding": true,
"content_preview": "First 500 characters..."
}

### 5. 🆕 Buscar Documentos Similares
```bashGET http://localhost:3000/api/analyzer/similarity/search/{taskId}?top_k=5
Authorization: Bearer YOUR_JWT_TOKENResponse: 200 OK
{
"referenceTask": {
"taskId": "uuid-1",
"filename": "tech-article.txt",
"contentPreview": "Python is a programming language..."
},
"similarDocuments": [
{
"taskId": "uuid-2",
"filename": "python-guide.txt",
"similarityScore": 0.8542,
"interpretation": "Very similar content"
},
{
"taskId": "uuid-3",
"filename": "javascript-intro.txt",
"similarityScore": 0.6123,
"interpretation": "Similar content"
}
],
"totalFound": 2
}

### 6. 🆕 Comparar Dos Documentos
```bashPOST http://localhost:3000/api/analyzer/similarity/compare?task_id_1=UUID1&task_id_2=UUID2
Authorization: Bearer YOUR_JWT_TOKENResponse: 200 OK
{
"task1": {
"taskId": "uuid-1",
"filename": "doc1.txt"
},
"task2": {
"taskId": "uuid-2",
"filename": "doc2.txt"
},
"similarityScore": 0.7845,
"interpretation": "Very similar content"
}

---

## 🧪 Testing con cURL
```bash1. Registrar usuario
curl -X POST http://localhost:3000/api/auth/register 
-H "Content-Type: application/json" 
-d '{"email":"test@test.com","password":"test123","name":"Test User"}'2. Login
TOKEN=$(curl -X POST http://localhost:3000/api/auth/login 
-H "Content-Type: application/json" 
-d '{"email":"test@test.com","password":"test123"}' 
| jq -r '.token')3. Subir archivo
TASK_ID=$(curl -X POST http://localhost:3000/api/analyzer/upload 
-H "Authorization: Bearer $TOKEN" 
-F "file=@test.txt" 
| jq -r '.taskId')4. Consultar estado (esperar 5 segundos)
sleep 5
curl http://localhost:3000/api/analyzer/tasks/$TASK_ID 
-H "Authorization: Bearer $TOKEN"5. Buscar documentos similares
curl "http://localhost:3000/api/analyzer/similarity/search/$TASK_ID?top_k=5" 
-H "Authorization: Bearer $TOKEN"

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

### Machine Learning
- ✅ Embeddings semánticos (384D)
- ✅ Búsqueda por similitud (cosine similarity)
- ✅ Detección de documentos duplicados
- ✅ Clustering automático de contenido
- ✅ CPU-friendly (~0.3s por documento)

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

## 📂 Estructura de Códigogateway-service/
├── src/
│   ├── index.js              # Entry point
│   ├── config/               # Configuraciones (DB, Redis)
│   ├── middleware/           # Auth, Rate Limit, Errors
│   ├── routes/               # Definición de rutas
│   ├── controllers/          # Lógica de negocio
│   └── utils/                # Helpers (JWT, etc)analyzer-service/
├── app/
│   ├── main.py               # Entry point FastAPI
│   ├── config.py             # Configuración centralizada
│   ├── database.py           # Conexiones DB
│   ├── models/               # Modelos SQLAlchemy y Pydantic
│   ├── routes/               # Routers FastAPI
│   ├── services/             # Lógica de negocio + ML
│   │   └── embedding_service.py  # 🆕 Servicio ML
│   └── workers/              # Worker de procesamiento + ML

---

## 🆕 Búsqueda Semántica con Embeddings

### ¿Qué son los embeddings?

Los embeddings son representaciones vectoriales de texto que capturan su significado semántico. Documentos con contenido similar tienen vectores cercanos en el espacio de embeddings.

### Tecnología

- **Modelo:** `all-MiniLM-L6-v2` (Sentence Transformers)
- **Tamaño:** 22MB (muy ligero)
- **Dimensiones:** 384 (vector por documento)
- **Performance:** ~0.3 segundos por documento en CPU
- **Almacenamiento:** PostgreSQL ARRAY column

### Casos de Uso

1. **Búsqueda Semántica:** Encuentra documentos similares por contenido
2. **Deduplicación:** Detecta archivos duplicados o casi-duplicados
3. **Clustering:** Agrupa documentos relacionados automáticamente
4. **Clasificación:** Base para clasificación automática de documentos

### Ejemplo de Uso
```pythonEl sistema genera automáticamente embeddings al procesar archivos
Luego puedes buscar documentos similares:Documento A: "Python is a programming language"
Documento B: "JavaScript is used for web development"
Documento C: "Baking a chocolate cake requires flour"Similarity A-B: ~0.65 (similar - ambos sobre programación)
Similarity A-C: ~0.25 (diferente - temas distintos)

---

## 🎓 Uso como Proyecto de Portafolio

### Para Presentarlo

**En tu CV/LinkedIn:**
- "Sistema de microservicios con procesamiento distribuido y ML"
- "API RESTful con embeddings semánticos y búsqueda por similitud"
- "Integración de sentence-transformers para análisis de documentos"

**En entrevistas:**
- Explica la arquitectura y por qué elegiste cada tecnología
- Demuestra el flujo completo (registro → upload → embedding → búsqueda)
- Menciona las decisiones técnicas (PostgreSQL vs MongoDB, sentence-transformers)
- Muestra la búsqueda semántica en acción

**En tu portafolio web:**
- Link al repositorio GitHub
- Screenshots de Swagger UI
- Diagrama de arquitectura
- Demo de búsqueda por similitud
- Métricas: "4 servicios, 3 DBs, ML embeddings, búsqueda semántica"

### Habilidades Demostradas

✅ **Backend Development**
- Node.js + Express
- Python + FastAPI
- RESTful API design
- Microservices architecture

✅ **Bases de Datos**
- PostgreSQL (relacional + vectores)
- MongoDB (NoSQL)
- Redis (cache + queue)

✅ **Machine Learning**
- Sentence Transformers
- Embeddings semánticos (384D)
- Búsqueda por similitud (cosine)
- Procesamiento de lenguaje natural

✅ **DevOps**
- Docker + Docker Compose
- Multi-stage builds
- Health checks
- Service orchestration

✅ **Seguridad**
- JWT authentication
- Rate limiting
- Password hashing
- Input validation

### Mejoras Futuras Sugeridas

Para expandir el proyecto puedes agregar:
- [ ] Tests unitarios y de integración (Pytest, Jest)
- [ ] CI/CD con GitHub Actions
- [ ] Monitoring con Prometheus + Grafana
- [ ] Deploy en AWS/GCP con Kubernetes
- [ ] WebSockets para notificaciones en tiempo real
- [ ] Procesamiento de imágenes con OpenCV
- [ ] Clasificación de documentos con fine-tuning
- [ ] Dashboard frontend con React
- [ ] Clustering automático con K-means
- [ ] Exportación de embeddings para visualización

---

## 🛑 Detener el Proyecto
```bashdocker-compose down           # Detener servicios
docker-compose down -v        # Detener y eliminar volúmenes (limpieza total)

---

## 📝 Licencia

MIT License - Este proyecto es open source y de uso educativo.

---

## 👨‍💻 Autor

- GitHub: [@fendifps](https://github.com/fendifps)
- LinkedIn: [Anthony Romero](https://www.linkedin.com/in/anthony-romero-32867b309/)
- Portfolio: [arrn](https://arrn-portfolio.netlify.app/)

---

## 🙏 Agradecimientos

Proyecto creado como demostración técnica para portafolio profesional.

**Stack:** Node.js • Python • FastAPI • Express • PostgreSQL • MongoDB • Redis • Docker • ML • Sentence Transformers

**Features:** Microservices • JWT Auth • Rate Limiting • Async Processing • Semantic Search • Document Embeddings