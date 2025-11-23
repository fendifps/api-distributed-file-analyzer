"""
Upload Routes
Handles file upload and queuing for processing
"""

from fastapi import APIRouter, UploadFile, File, Form, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pathlib import Path
import uuid
from datetime import datetime
import aiofiles

from app.database import get_db, log_event
from app.models.task import Task
from app.redis_client import enqueue_task
from app.config import settings

router = APIRouter()


@router.post("/upload", status_code=status.HTTP_202_ACCEPTED)
async def upload_file(
    file: UploadFile = File(...),
    user_id: str = Form(...),
    db: Session = Depends(get_db)
):
    """
    Upload a file for analysis
    
    - **file**: File to upload
    - **user_id**: User ID from authentication
    
    Returns task ID and status
    """
    
    # Validate file
    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No filename provided"
        )
    
    # Read file content
    content = await file.read()
    file_size = len(content)
    
    # Check file size
    if file_size > settings.MAX_UPLOAD_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File too large. Maximum size: {settings.MAX_UPLOAD_SIZE} bytes"
        )
    
    if file_size == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Empty file"
        )
    
    # Create task record
    task_id = uuid.uuid4()
    file_path = Path(settings.UPLOAD_DIR) / f"{task_id}_{file.filename}"
    
    # Ensure upload directory exists
    Path(settings.UPLOAD_DIR).mkdir(parents=True, exist_ok=True)
    
    # Save file
    async with aiofiles.open(file_path, 'wb') as f:
        await f.write(content)
    
    # Create task in database
    task = Task(
        id=task_id,
        user_id=uuid.UUID(user_id),
        filename=file.filename,
        file_path=str(file_path),
        file_size=file_size,
        status="queued"
    )
    
    db.add(task)
    db.commit()
    db.refresh(task)
    
    # Enqueue processing job
    from app.workers.file_worker import process_file
    job = enqueue_task(process_file, str(task_id), str(file_path))
    
    # Update task with job ID
    task.job_id = job.id
    db.commit()
    
    # Log event to MongoDB
    log_event('file_uploads', {
        'task_id': str(task_id),
        'user_id': user_id,
        'filename': file.filename,
        'file_size': file_size,
        'timestamp': datetime.utcnow(),
        'status': 'queued'
    })
    
    return {
        "taskId": str(task_id),
        "status": "queued",
        "message": "File uploaded and queued for processing",
        "filename": file.filename,
        "fileSize": file_size
    }