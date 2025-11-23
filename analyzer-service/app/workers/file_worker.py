"""
File Worker
Background worker that processes files from Redis queue
"""

import time
from datetime import datetime
from pathlib import Path
import uuid

from rq import Worker, Queue
from sqlalchemy.orm import Session

from app.config import settings
from app.database import SessionLocal, log_event
from app.models.task import Task
from app.redis_client import redis_conn


def process_file(task_id: str, file_path: str):
    """
    Process uploaded file and extract information
    
    Args:
        task_id: Task UUID
        file_path: Path to uploaded file
    
    This function simulates file analysis by:
    1. Reading the file
    2. Counting lines, words, characters
    3. Calculating processing time
    4. Storing results in PostgreSQL
    5. Logging to MongoDB
    """
    
    print(f"📝 Processing task: {task_id}")
    
    db = SessionLocal()
    start_time = time.time()
    
    try:
        # Get task from database
        task = db.query(Task).filter(Task.id == uuid.UUID(task_id)).first()
        
        if not task:
            raise Exception(f"Task {task_id} not found")
        
        # Update status to processing
        task.status = "processing"
        task.started_at = datetime.utcnow()
        db.commit()
        
        # Log processing start
        log_event('task_processing', {
            'task_id': task_id,
            'status': 'started',
            'timestamp': datetime.utcnow()
        })
        
        # Simulate file analysis
        print(f"   Reading file: {file_path}")
        
        file_obj = Path(file_path)
        
        if not file_obj.exists():
            raise Exception(f"File not found: {file_path}")
        
        # Read and analyze file
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Calculate metrics
        line_count = len(content.splitlines())
        word_count = len(content.split())
        char_count = len(content)
        
        # Simulate processing delay (remove in production)
        time.sleep(2)
        
        processing_time = time.time() - start_time
        
        # Prepare result
        result = {
            'fileSize': task.file_size,
            'lineCount': line_count,
            'wordCount': word_count,
            'characterCount': char_count,
            'processingTime': f"{processing_time:.2f}s",
            'analyzedAt': datetime.utcnow().isoformat()
        }
        
        # Update task with result
        task.status = "completed"
        task.result = result
        task.completed_at = datetime.utcnow()
        db.commit()
        
        print(f"✅ Task {task_id} completed successfully")
        print(f"   Lines: {line_count}, Words: {word_count}, Chars: {char_count}")
        
        # Log completion
        log_event('task_processing', {
            'task_id': task_id,
            'status': 'completed',
            'result': result,
            'timestamp': datetime.utcnow()
        })
        
    except Exception as e:
        error_msg = str(e)
        print(f"❌ Task {task_id} failed: {error_msg}")
        
        # Update task as failed
        try:
            task = db.query(Task).filter(Task.id == uuid.UUID(task_id)).first()
            if task:
                task.status = "failed"
                task.error = error_msg
                task.completed_at = datetime.utcnow()
                db.commit()
        except Exception as db_error:
            print(f"Failed to update task status: {db_error}")
        
        # Log failure
        log_event('task_processing', {
            'task_id': task_id,
            'status': 'failed',
            'error': error_msg,
            'timestamp': datetime.utcnow()
        })
        
        raise
    
    finally:
        db.close()


def run_worker():
    """
    Start RQ worker to process tasks from queue
    """
    print("=" * 60)
    print("  File Processing Worker")
    print("=" * 60)
    print(f"  Environment: {settings.ENVIRONMENT}")
    print(f"  Redis: {settings.REDIS_HOST}:{settings.REDIS_PORT}")
    print(f"  Queue: file_processing")
    print("=" * 60)
    print()
    print("🚀 Worker started, waiting for jobs...")
    print()
    
    # Create queue
    queue = Queue('file_processing', connection=redis_conn)
    
    # Create and start worker
    worker = Worker([queue], connection=redis_conn)
    worker.work(with_scheduler=True)


if __name__ == "__main__":
    run_worker()