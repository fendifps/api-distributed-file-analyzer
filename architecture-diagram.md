# API Distributed File Analyzer - Architecture

System Architecture Overview:

CLIENT LAYER (Browser, API Clients)
         |
         v
GATEWAY SERVICE (Port 3000) - Node.js + Express
  - JWT Authentication
  - Rate Limiting
  - API Gateway
         |
         v
ANALYZER SERVICE (Port 8000) - Python + FastAPI
  - File Processing
  - ML Embeddings (384D)
  - Similarity Search
         |
    +----+----+
    v    v    v
PostgreSQL  MongoDB  Redis
(tasks+ML)  (logs)   (queue)
         |
         v
WORKER PROCESS - Python + RQ
  - Process Files
  - Generate Embeddings
  - Update Database

## Key Features

- Microservices Architecture
- JWT Authentication
- Rate Limiting with Redis
- Async Processing with Queue
- ML Embeddings (Sentence Transformers)
- Semantic Similarity Search
- PostgreSQL (relational + vectors)
- MongoDB (logs)
- Docker Compose orchestration

## Endpoints

Gateway Service (Port 3000):
- POST /api/auth/register
- POST /api/auth/login
- GET /api/auth/profile
- POST /api/analyzer/upload
- GET /api/analyzer/tasks/:id
- GET /api/analyzer/tasks
- GET /api/analyzer/similarity/search/:id (NEW - ML)
- POST /api/analyzer/similarity/compare (NEW - ML)
- GET /health

Analyzer Service (Port 8000):
- POST /api/v1/upload
- GET /api/v1/tasks/:id
- GET /api/v1/tasks
- GET /api/v1/similarity/search/:id (NEW - ML)
- POST /api/v1/similarity/compare (NEW - ML)
- GET /health
- GET /docs (Swagger UI)

## Data Flow

1. User Registration/Login
   Client -> Gateway -> PostgreSQL -> JWT Token

2. File Upload
   Client -> Gateway (auth) -> Analyzer -> Save file -> PostgreSQL
   -> Redis Queue -> Worker -> Process + ML Embedding
   -> PostgreSQL (results + 384D vector) -> MongoDB (logs)

3. Similarity Search (NEW)
   Client -> Gateway (auth) -> Analyzer -> PostgreSQL (get embeddings)
   -> Calculate cosine similarity -> Return similar documents

## ML Features

Model: all-MiniLM-L6-v2 (Sentence Transformers)
- Size: 22MB
- Dimensions: 384
- Performance: ~0.3s per document (CPU)
- Use Cases:
  * Semantic search
  * Document deduplication
  * Content clustering
  * Similarity scoring

## Database Schemas

PostgreSQL - tasks table:
- id (UUID)
- user_id (UUID)
- filename (VARCHAR)
- file_path (VARCHAR)
- file_size (INTEGER)
- status (VARCHAR)
- result (JSONB)
- embedding (FLOAT ARRAY) - NEW: 384 dimensions
- content_preview (TEXT) - NEW
- created_at, started_at, completed_at (TIMESTAMP)

PostgreSQL - users table:
- id (UUID)
- email (VARCHAR)
- password (VARCHAR) - bcrypt hashed
- name (VARCHAR)
- created_at, updated_at (TIMESTAMP)

MongoDB - Collections:
- file_uploads: Upload events
- task_processing: Processing logs
- audit_logs: System events

## Technology Stack

Gateway Service:
- Node.js 20
- Express.js
- JWT (jsonwebtoken)
- bcrypt
- Redis (rate limiting)
- PostgreSQL

Analyzer Service:
- Python 3.11
- FastAPI
- SQLAlchemy
- Sentence Transformers (ML)
- Redis Queue (RQ)
- PostgreSQL
- MongoDB

Infrastructure:
- Docker + Docker Compose
- PostgreSQL 15
- MongoDB 7
- Redis 7

## Scalability

- Multiple Gateway instances (load balancer)
- Multiple Analyzer instances
- Multiple Workers (horizontal scaling)
- Database replication
- Redis cluster
- ML model caching

## Security

- JWT authentication with expiration
- bcrypt password hashing (10 rounds)
- Rate limiting (Redis-backed)
- Input validation
- Security headers (Helmet)
- CORS configuration

## Performance

- Async processing (Redis Queue)
- Connection pooling (PostgreSQL)
- In-memory embeddings cache
- CPU-friendly ML model
- ~0.3s embedding generation
- ~2-3s total file processing

## Project Stats

- 2 Microservices
- 3 Databases
- 9 Public Endpoints
- 6 Docker Containers
- ~5,600 Lines of Code
- ML-powered semantic search