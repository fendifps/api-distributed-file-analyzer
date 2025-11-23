"""
Redis Client and Queue Configuration
"""

import redis
from rq import Queue
from app.config import settings

# Redis connection
redis_conn = redis.Redis(
    host=settings.REDIS_HOST,
    port=settings.REDIS_PORT,
    db=settings.REDIS_DB,
    decode_responses=True
)

# RQ Queue for background tasks
task_queue = Queue('file_processing', connection=redis_conn)


def enqueue_task(func, *args, **kwargs):
    """
    Enqueue a task for background processing
    
    Args:
        func: Function to execute
        *args: Positional arguments
        **kwargs: Keyword arguments
    
    Returns:
        Job object
    """
    job = task_queue.enqueue(func, *args, **kwargs)
    return job


def get_job_status(job_id: str):
    """
    Get job status from Redis
    
    Args:
        job_id: Job ID
    
    Returns:
        Job status string
    """
    from rq.job import Job
    try:
        job = Job.fetch(job_id, connection=redis_conn)
        return job.get_status()
    except Exception:
        return None