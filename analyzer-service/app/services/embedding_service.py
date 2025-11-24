"""
Embedding Service
Generates semantic embeddings for text content using sentence-transformers
"""

from sentence_transformers import SentenceTransformer
import numpy as np
from typing import List, Optional
import logging

logger = logging.getLogger(__name__)


class EmbeddingService:
    """Service for generating text embeddings"""
    
    def __init__(self):
        """Initialize the embedding model"""
        try:
            # Load lightweight model (22MB, 384 dimensions)
            # CPU-friendly, fast inference (~0.1s per document)
            self.model = SentenceTransformer('all-MiniLM-L6-v2')
            logger.info("✓ Embedding model loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load embedding model: {e}")
            self.model = None
    
    def generate_embedding(self, text: str, max_length: int = 1000) -> Optional[List[float]]:
        """
        Generate embedding vector for text
        
        Args:
            text: Input text to embed
            max_length: Maximum text length to process (truncate if longer)
        
        Returns:
            List of 384 floats representing the embedding, or None if failed
        """
        if not self.model:
            logger.warning("Embedding model not available")
            return None
        
        try:
            # Truncate text if too long (for performance)
            text_truncated = text[:max_length] if len(text) > max_length else text
            
            # Generate embedding
            embedding = self.model.encode(
                text_truncated,
                convert_to_numpy=True,
                show_progress_bar=False
            )
            
            # Convert to list for JSON serialization
            return embedding.tolist()
        
        except Exception as e:
            logger.error(f"Error generating embedding: {e}")
            return None
    
    def calculate_similarity(self, embedding1: List[float], embedding2: List[float]) -> float:
        """
        Calculate cosine similarity between two embeddings
        
        Args:
            embedding1: First embedding vector
            embedding2: Second embedding vector
        
        Returns:
            Similarity score between 0 and 1 (1 = identical)
        """
        try:
            vec1 = np.array(embedding1)
            vec2 = np.array(embedding2)
            
            # Cosine similarity
            dot_product = np.dot(vec1, vec2)
            norm1 = np.linalg.norm(vec1)
            norm2 = np.linalg.norm(vec2)
            
            if norm1 == 0 or norm2 == 0:
                return 0.0
            
            similarity = dot_product / (norm1 * norm2)
            
            # Normalize to 0-1 range
            return float((similarity + 1) / 2)
        
        except Exception as e:
            logger.error(f"Error calculating similarity: {e}")
            return 0.0
    
    def find_similar_embeddings(
        self, 
        query_embedding: List[float], 
        candidate_embeddings: List[tuple],
        top_k: int = 5
    ) -> List[tuple]:
        """
        Find most similar embeddings to query
        
        Args:
            query_embedding: Query embedding vector
            candidate_embeddings: List of (id, embedding) tuples
            top_k: Number of top results to return
        
        Returns:
            List of (id, similarity_score) tuples, sorted by similarity
        """
        similarities = []
        
        for item_id, embedding in candidate_embeddings:
            similarity = self.calculate_similarity(query_embedding, embedding)
            similarities.append((item_id, similarity))
        
        # Sort by similarity (descending)
        similarities.sort(key=lambda x: x[1], reverse=True)
        
        return similarities[:top_k]


# Global instance
embedding_service = EmbeddingService()