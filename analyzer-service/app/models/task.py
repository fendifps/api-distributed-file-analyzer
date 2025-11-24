"""
Task Model for PostgreSQL
Stores information about file analysis tasks
"""

from sqlalchemy import Column, String, DateTime, JSON, Integer, Text, Float
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from datetime import datetime
import uuid

from app.database import Base


class Task(Base):
    """Task model for file analysis"""
    
    __tablename__ = "tasks"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    filename = Column(String(255), nullable=False)
    file_path = Column(String(512), nullable=False)
    file_size = Column(Integer, nullable=False)
    status = Column(String(50), nullable=False, default="queued", index=True)
    job_id = Column(String(255), nullable=True)
    result = Column(JSON, nullable=True)
    error = Column(String(1000), nullable=True)
    embedding = Column(ARRAY(Float), nullable=True)
    content_preview = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    
    def to_dict(self):
        """Convert model to dictionary"""
        return {
            "id": str(self.id),
            "user_id": str(self.user_id),
            "filename": self.filename,
            "file_size": self.file_size,
            "status": self.status,
            "result": self.result,
            "error": self.error,
            "has_embedding": self.embedding is not None,
            "content_preview": self.content_preview,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None
        }