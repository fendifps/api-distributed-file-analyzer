"""
Tasks Routes
Handles task status queries and results
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List
import uuid

from app.database import get_db
from app.models.task import Task

router = APIRouter()


@router.get("/tasks/{task_id}")
async def get_task(
    task_id: str,
    user_id: str = Query(...),
    db: Session = Depends(get_db)
):
    """
    Get task status and result by ID
    
    - **task_id**: Task UUID
    - **user_id**: User ID for authorization
    
    Returns task details including status and result
    """
    
    try:
        task_uuid = uuid.UUID(task_id)
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid UUID format"
        )
    
    # Query task
    task = db.query(Task).filter(
        Task.id == task_uuid,
        Task.user_id == user_uuid
    ).first()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found or access denied"
        )
    
    # Return task details
    response = {
        "taskId": str(task.id),
        "filename": task.filename,
        "fileSize": task.file_size,
        "status": task.status,
        "createdAt": task.created_at.isoformat() if task.created_at else None,
    }
    
    # Add processing times if available
    if task.started_at:
        response["startedAt"] = task.started_at.isoformat()
    
    if task.completed_at:
        response["completedAt"] = task.completed_at.isoformat()
    
    # Add result if completed
    if task.status == "completed" and task.result:
        response["result"] = task.result
    
    # Add error if failed
    if task.status == "failed" and task.error:
        response["error"] = task.error
    
    return response


@router.get("/tasks")
async def get_user_tasks(
    user_id: str = Query(...),
    limit: int = Query(10, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    """
    Get all tasks for a user
    
    - **user_id**: User ID for filtering
    - **limit**: Maximum number of tasks to return (1-100)
    - **offset**: Number of tasks to skip
    
    Returns list of tasks
    """
    
    try:
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID format"
        )
    
    # Query tasks
    tasks = db.query(Task).filter(
        Task.user_id == user_uuid
    ).order_by(
        Task.created_at.desc()
    ).limit(limit).offset(offset).all()
    
    # Get total count
    total = db.query(Task).filter(Task.user_id == user_uuid).count()
    
    # Format response
    tasks_list = []
    for task in tasks:
        task_data = {
            "taskId": str(task.id),
            "filename": task.filename,
            "fileSize": task.file_size,
            "status": task.status,
            "createdAt": task.created_at.isoformat() if task.created_at else None
        }
        
        if task.completed_at:
            task_data["completedAt"] = task.completed_at.isoformat()
        
        tasks_list.append(task_data)
    
    return {
        "tasks": tasks_list,
        "total": total,
        "limit": limit,
        "offset": offset
    }