"""
Similarity Search Routes
Find similar documents based on semantic embeddings
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List
import uuid

from app.database import get_db
from app.models.task import Task
from app.services.embedding_service import embedding_service

router = APIRouter()


@router.get("/similarity/search/{task_id}")
async def search_similar_documents(
    task_id: str,
    user_id: str = Query(...),
    top_k: int = Query(5, ge=1, le=20),
    db: Session = Depends(get_db)
):
    """
    Find documents similar to a given task
    
    - **task_id**: Reference task UUID
    - **user_id**: User ID for authorization
    - **top_k**: Number of similar documents to return (1-20)
    
    Returns list of similar documents with similarity scores
    """
    
    try:
        task_uuid = uuid.UUID(task_id)
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid UUID format"
        )
    
    # Get reference task
    ref_task = db.query(Task).filter(
        Task.id == task_uuid,
        Task.user_id == user_uuid
    ).first()
    
    if not ref_task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found or access denied"
        )
    
    if not ref_task.embedding:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Reference task does not have embedding. File may not be processed yet."
        )
    
    # Get all user's tasks with embeddings (exclude reference task)
    candidate_tasks = db.query(Task).filter(
        Task.user_id == user_uuid,
        Task.id != task_uuid,
        Task.embedding.isnot(None),
        Task.status == "completed"
    ).all()
    
    if not candidate_tasks:
        return {
            "referenceTask": {
                "taskId": str(ref_task.id),
                "filename": ref_task.filename
            },
            "similarDocuments": [],
            "message": "No other documents with embeddings found"
        }
    
    # Prepare candidate embeddings
    candidates = [(str(task.id), task.embedding) for task in candidate_tasks]
    
    # Find similar documents
    similar = embedding_service.find_similar_embeddings(
        ref_task.embedding,
        candidates,
        top_k=top_k
    )
    
    # Format response
    similar_docs = []
    for task_id_str, similarity_score in similar:
        task = next(t for t in candidate_tasks if str(t.id) == task_id_str)
        similar_docs.append({
            "taskId": task_id_str,
            "filename": task.filename,
            "fileSize": task.file_size,
            "similarityScore": round(similarity_score, 4),
            "contentPreview": task.content_preview[:100] if task.content_preview else None,
            "createdAt": task.created_at.isoformat() if task.created_at else None
        })
    
    return {
        "referenceTask": {
            "taskId": str(ref_task.id),
            "filename": ref_task.filename,
            "contentPreview": ref_task.content_preview[:100] if ref_task.content_preview else None
        },
        "similarDocuments": similar_docs,
        "totalFound": len(similar_docs)
    }


@router.post("/similarity/compare")
async def compare_two_documents(
    task_id_1: str = Query(...),
    task_id_2: str = Query(...),
    user_id: str = Query(...),
    db: Session = Depends(get_db)
):
    """
    Compare similarity between two specific documents
    
    - **task_id_1**: First task UUID
    - **task_id_2**: Second task UUID  
    - **user_id**: User ID for authorization
    
    Returns similarity score between 0 and 1
    """
    
    try:
        task_uuid_1 = uuid.UUID(task_id_1)
        task_uuid_2 = uuid.UUID(task_id_2)
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid UUID format"
        )
    
    # Get both tasks
    task1 = db.query(Task).filter(
        Task.id == task_uuid_1,
        Task.user_id == user_uuid
    ).first()
    
    task2 = db.query(Task).filter(
        Task.id == task_uuid_2,
        Task.user_id == user_uuid
    ).first()
    
    if not task1 or not task2:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="One or both tasks not found or access denied"
        )
    
    if not task1.embedding or not task2.embedding:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="One or both tasks do not have embeddings"
        )
    
    # Calculate similarity
    similarity = embedding_service.calculate_similarity(
        task1.embedding,
        task2.embedding
    )
    
    return {
        "task1": {
            "taskId": str(task1.id),
            "filename": task1.filename
        },
        "task2": {
            "taskId": str(task2.id),
            "filename": task2.filename
        },
        "similarityScore": round(similarity, 4),
        "interpretation": get_similarity_interpretation(similarity)
    }


def get_similarity_interpretation(score: float) -> str:
    """Get human-readable interpretation of similarity score"""
    if score >= 0.9:
        return "Nearly identical content"
    elif score >= 0.75:
        return "Very similar content"
    elif score >= 0.6:
        return "Similar content"
    elif score >= 0.4:
        return "Somewhat similar content"
    else:
        return "Different content"