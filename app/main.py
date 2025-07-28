from fastapi import FastAPI, HTTPException, BackgroundTasks, Depends
from fastapi.middleware.cors import CORSMiddleware
from app.downloader import process_and_upload, VideoProcessingError
from app.auth import verify_token, verify_token_with_rate_limit, generate_api_key
from pydantic import BaseModel, HttpUrl
import logging
import asyncio
from concurrent.futures import ThreadPoolExecutor
from contextlib import asynccontextmanager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Thread pool for CPU-bound tasks
executor = ThreadPoolExecutor(max_workers=3)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting ytdl-microservice")
    yield
    # Shutdown
    logger.info("Shutting down ytdl-microservice")
    executor.shutdown(wait=True)

app = FastAPI(
    title="YouTube Downloader Microservice",
    description="A robust microservice for downloading YouTube videos and uploading to S3",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class VideoRequest(BaseModel):
    youtube_url: HttpUrl
    
    class Config:
        schema_extra = {
            "example": {
                "youtube_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
            }
        }

class VideoResponse(BaseModel):
    s3_key: str
    message: str = "Video processed successfully"

class ErrorResponse(BaseModel):
    error: str
    detail: str

@app.get("/health")
async def health_check():
    """Health check endpoint - no authentication required"""
    return {"status": "healthy", "service": "ytdl-microservice"}

@app.get("/generate-key")
async def generate_key(authenticated: bool = Depends(verify_token)):
    """
    Generate a new API key (admin endpoint)
    Requires valid authentication
    """
    new_key = generate_api_key()
    return {
        "api_key": new_key,
        "message": "Store this key securely. It cannot be retrieved again.",
        "usage": "Include in Authorization header: Bearer <api_key>"
    }

@app.post("/download", response_model=VideoResponse)
async def download_and_upload(
    req: VideoRequest,
    authenticated: bool = Depends(verify_token_with_rate_limit)
):
    """
    Download a YouTube video and upload it to S3
    Requires Bearer token authentication
    
    Args:
        req: VideoRequest containing the YouTube URL
        
    Returns:
        VideoResponse with S3 key
        
    Raises:
        HTTPException: If processing fails or authentication fails
    """
    try:
        logger.info(f"Processing authenticated request for URL: {req.youtube_url}")
        
        # Run the blocking operation in thread pool
        loop = asyncio.get_event_loop()
        s3_key = await loop.run_in_executor(
            executor, 
            process_and_upload, 
            str(req.youtube_url)
        )
        
        return VideoResponse(
            s3_key=s3_key,
            message="Video processed and uploaded successfully"
        )
        
    except VideoProcessingError as e:
        logger.error(f"Video processing error: {str(e)}")
        raise HTTPException(
            status_code=422,
            detail=f"Video processing failed: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error occurred"
        )

@app.post("/download-async")
async def download_and_upload_async(
    req: VideoRequest, 
    background_tasks: BackgroundTasks,
    authenticated: bool = Depends(verify_token_with_rate_limit)
):
    """
    Asynchronously download a YouTube video and upload it to S3
    Requires Bearer token authentication
    Returns immediately with a task ID for status checking
    """
    task_id = f"task_{asyncio.current_task().get_name()}"
    
    async def process_video():
        try:
            loop = asyncio.get_event_loop()
            s3_key = await loop.run_in_executor(
                executor, 
                process_and_upload, 
                str(req.youtube_url)
            )
            logger.info(f"Background task {task_id} completed: {s3_key}")
        except Exception as e:
            logger.error(f"Background task {task_id} failed: {str(e)}")
    
    background_tasks.add_task(process_video)
    
    return {
        "task_id": task_id,
        "message": "Video processing started in background",
        "status": "processing"
    }

@app.exception_handler(VideoProcessingError)
async def video_processing_exception_handler(request, exc):
    return HTTPException(
        status_code=422,
        detail=str(exc)
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        log_level="info",
        access_log=True
    )