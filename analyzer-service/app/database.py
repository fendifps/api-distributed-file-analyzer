"""
Database Connections
Manages PostgreSQL and MongoDB connections
"""

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from pymongo import MongoClient
from app.config import settings

# PostgreSQL Setup
engine = create_engine(
    settings.postgres_url,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# MongoDB Setup
mongo_client = None
mongo_db = None


def init_db():
    """Initialize database connections"""
    global mongo_client, mongo_db
    
    # Create PostgreSQL tables
    from app.models.task import Task
    Base.metadata.create_all(bind=engine)
    print("✓ PostgreSQL tables created")
    
    # Connect to MongoDB
    mongo_client = MongoClient(settings.mongodb_url)
    mongo_db = mongo_client[settings.MONGODB_DB]
    print("✓ MongoDB connected")


def close_db():
    """Close database connections"""
    global mongo_client
    if mongo_client:
        mongo_client.close()


def get_db():
    """
    Dependency for PostgreSQL sessions
    Usage: db: Session = Depends(get_db)
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_mongo_db():
    """
    Get MongoDB database instance
    """
    return mongo_db


def log_event(collection: str, event: dict):
    """
    Log event to MongoDB
    
    Args:
        collection: Collection name
        event: Event data to log
    """
    try:
        mongo_db[collection].insert_one(event)
    except Exception as e:
        print(f"Failed to log event: {e}")