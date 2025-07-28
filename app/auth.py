import os
import secrets
import hashlib
from typing import Optional
from fastapi import HTTPException, Security, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import logging

logger = logging.getLogger(__name__)

# Security scheme
security = HTTPBearer(auto_error=False)

class TokenValidator:
    """Handle Bearer token validation"""
    
    def __init__(self):
        # Get API keys from environment - support multiple keys
        self.api_keys = self._load_api_keys()
        if not self.api_keys:
            logger.warning("No API keys configured! All requests will be rejected.")
    
    def _load_api_keys(self) -> set:
        """Load API keys from environment variables"""
        keys = set()
        
        # Primary API key
        primary_key = os.getenv("API_KEY")
        if primary_key:
            keys.add(self._hash_key(primary_key))
        
        # Support multiple API keys (API_KEY_1, API_KEY_2, etc.)
        i = 1
        while True:
            key = os.getenv(f"API_KEY_{i}")
            if not key:
                break
            keys.add(self._hash_key(key))
            i += 1
        
        # Support comma-separated keys in single env var
        keys_csv = os.getenv("API_KEYS")
        if keys_csv:
            for key in keys_csv.split(","):
                key = key.strip()
                if key:
                    keys.add(self._hash_key(key))
        
        logger.info(f"Loaded {len(keys)} API key(s)")
        return keys
    
    def _hash_key(self, key: str) -> str:
        """Hash API key for secure comparison"""
        return hashlib.sha256(key.encode()).hexdigest()
    
    def validate_token(self, token: str) -> bool:
        """Validate bearer token against configured API keys"""
        if not self.api_keys:
            return False
        
        token_hash = self._hash_key(token)
        return token_hash in self.api_keys

# Global token validator instance
token_validator = TokenValidator()

async def verify_token(
    credentials: Optional[HTTPAuthorizationCredentials] = Security(security)
) -> bool:
    """
    Dependency to verify Bearer token
    
    Args:
        credentials: HTTP authorization credentials
        
    Returns:
        bool: True if token is valid
        
    Raises:
        HTTPException: If token is invalid or missing
    """
    if not credentials:
        logger.warning("Missing Authorization header")
        raise HTTPException(
            status_code=401,
            detail="Missing Authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if credentials.scheme.lower() != "bearer":
        logger.warning(f"Invalid authentication scheme: {credentials.scheme}")
        raise HTTPException(
            status_code=401,
            detail="Invalid authentication scheme. Use Bearer token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not token_validator.validate_token(credentials.credentials):
        logger.warning("Invalid or expired token")
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    logger.debug("Token validated successfully")
    return True

def generate_api_key(length: int = 32) -> str:
    """
    Generate a secure API key
    
    Args:
        length: Length of the API key
        
    Returns:
        str: Generated API key
    """
    return secrets.token_urlsafe(length)

# Optional: Rate limiting per token (basic implementation)
class TokenRateLimiter:
    """Simple in-memory rate limiter per token"""
    
    def __init__(self):
        self.requests = {}  # token_hash -> (count, reset_time)
        self.max_requests = int(os.getenv("RATE_LIMIT_REQUESTS", "100"))
        self.window_seconds = int(os.getenv("RATE_LIMIT_WINDOW", "3600"))  # 1 hour
    
    def is_allowed(self, token: str) -> bool:
        """Check if request is allowed based on rate limit"""
        import time
        
        if not token:
            return False
        
        token_hash = hashlib.sha256(token.encode()).hexdigest()[:16]  # Short hash for memory
        current_time = time.time()
        
        if token_hash not in self.requests:
            self.requests[token_hash] = (1, current_time + self.window_seconds)
            return True
        
        count, reset_time = self.requests[token_hash]
        
        # Reset if window expired
        if current_time > reset_time:
            self.requests[token_hash] = (1, current_time + self.window_seconds)
            return True
        
        # Check if under limit
        if count < self.max_requests:
            self.requests[token_hash] = (count + 1, reset_time)
            return True
        
        return False

# Global rate limiter instance
rate_limiter = TokenRateLimiter()

async def verify_token_with_rate_limit(
    credentials: Optional[HTTPAuthorizationCredentials] = Security(security)
) -> bool:
    """
    Dependency to verify Bearer token with rate limiting
    
    Args:
        credentials: HTTP authorization credentials
        
    Returns:
        bool: True if token is valid and within rate limit
        
    Raises:
        HTTPException: If token is invalid, missing, or rate limited
    """
    # First verify the token
    await verify_token(credentials)
    
    # Then check rate limit
    if not rate_limiter.is_allowed(credentials.credentials):
        logger.warning("Rate limit exceeded for token")
        raise HTTPException(
            status_code=429,
            detail="Rate limit exceeded. Try again later.",
            headers={"Retry-After": str(rate_limiter.window_seconds)}
        )
    
    return True