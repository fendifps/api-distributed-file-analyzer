"""
Analyzer Service - FastAPI Entry Point
Handles file upload and task management
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn

from app.config import settings
from app.database import init_db, close_db
from app.routes import upload, tasks


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events"""
    # Startup
    print("🚀 Starting Analyzer Service...")
    init_db()
    print("✓ Database connections established")
    yield
    # Shutdown
    print("🛑 Shutting down Analyzer Service...")
    close_db()
    print("✓ Database connections closed")


# Create FastAPI app
app = FastAPI(
    title="File Analyzer API",
    description="Microservice for distributed file analysis with background processing",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify allowed origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check endpoint
@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint"""
    return {
        "status": "UP",
        "service": "analyzer-service",
        "version": "1.0.0"
    }

# Include routers
app.include_router(upload.router, prefix="/api/v1", tags=["Upload"])
app.include_router(tasks.router, prefix="/api/v1", tags=["Tasks"])

# Root endpoint
@app.get("/", tags=["Root"])
async def root():
    """Root endpoint with API information"""
    return {
        "service": "File Analyzer API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health"
    }


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.ENVIRONMENT == "development"
    )