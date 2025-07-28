import os
import uuid
import boto3
import subprocess
import requests
import logging
from pathlib import Path
from typing import Optional
from botocore.exceptions import ClientError, BotoCoreError
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from urllib3.exceptions import InsecureRequestWarning
import tempfile

# Suppress urllib3 warnings for cleaner logs
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
BUCKET_NAME = os.getenv("AWS_BUCKET_NAME")
S3_REGION = os.getenv("AWS_REGION", "us-east-1")
COOKIES_FILE = os.getenv("COOKIE_FILE_PATH", "/app/cookies/youtube_cookies.txt")
MAX_FILE_SIZE_MB = int(os.getenv("MAX_FILE_SIZE_MB", "500"))  # 500MB default limit


class VideoProcessingError(Exception):
    """Custom exception for video processing errors"""
    pass


def create_robust_session() -> requests.Session:
    """Create a requests session with retry strategy and proper SSL handling"""
    session = requests.Session()
    
    # Configure retry strategy
    retry_strategy = Retry(
        total=3,
        status_forcelist=[429, 500, 502, 503, 504],
        method_whitelist=["HEAD", "GET", "PUT", "DELETE", "OPTIONS", "TRACE"],
        backoff_factor=1,  # Wait 1, 2, 4 seconds between retries
        raise_on_status=False
    )
    
    adapter = HTTPAdapter(
        max_retries=retry_strategy,
        pool_connections=10,
        pool_maxsize=10,
        pool_block=False
    )
    
    session.mount("http://", adapter)
    session.mount("https://", adapter)
    
    # Set reasonable timeouts
    session.timeout = (30, 300)  # (connect, read) timeout in seconds
    
    return session


def validate_environment() -> None:
    """Validate required environment variables"""
    required_vars = ["AWS_BUCKET_NAME", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"]
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    
    if missing_vars:
        raise VideoProcessingError(f"Missing required environment variables: {', '.join(missing_vars)}")


def download_video(url: str, output_path: str) -> None:
    """Download video using yt-dlp with robust error handling"""
    cmd = [
        "yt-dlp",
        "--no-warnings",
        "--quiet",
        "--progress",
        "-f", "bv*[height<=1080]+ba/b[height<=1080]/b",  # Limit to 1080p max
        "--merge-output-format", "mp4",
        "-o", output_path,
        url
    ]
    
    # Add cookies if file exists
    if os.path.exists(COOKIES_FILE):
        cmd.extend(["--cookies", COOKIES_FILE])
        logger.info("Using cookies file for authentication")
    
    try:
        logger.info(f"Starting download from: {url}")
        result = subprocess.run(
            cmd,
            check=True,
            capture_output=True,
            text=True,
            timeout=900  # 15 minutes timeout
        )
        logger.info("Video download completed successfully")
        
        if result.stderr:
            logger.warning(f"yt-dlp warnings: {result.stderr}")
            
    except subprocess.TimeoutExpired:
        raise VideoProcessingError("Video download timed out after 15 minutes")
    except subprocess.CalledProcessError as e:
        logger.error(f"yt-dlp error: {e.stderr}")
        raise VideoProcessingError(f"Failed to download video: {e.stderr}")


def validate_file(file_path: str) -> None:
    """Validate downloaded file"""
    if not os.path.exists(file_path):
        raise VideoProcessingError("Downloaded file does not exist")
    
    file_size = os.path.getsize(file_path)
    if file_size == 0:
        raise VideoProcessingError("Downloaded file is empty")
    
    max_size_bytes = MAX_FILE_SIZE_MB * 1024 * 1024
    if file_size > max_size_bytes:
        raise VideoProcessingError(f"File size ({file_size / 1024 / 1024:.1f}MB) exceeds limit ({MAX_FILE_SIZE_MB}MB)")
    
    logger.info(f"File validated: {file_size / 1024 / 1024:.1f}MB")


def create_s3_client():
    """Create S3 client with proper configuration"""
    try:
        return boto3.client(
            "s3",
            region_name=S3_REGION,
            aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
            aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
            config=boto3.session.Config(
                retries={'max_attempts': 3, 'mode': 'adaptive'},
                max_pool_connections=10
            )
        )
    except Exception as e:
        raise VideoProcessingError(f"Failed to create S3 client: {str(e)}")


def upload_to_s3_multipart(s3_client, file_path: str, s3_key: str) -> None:
    """Upload large files using S3 multipart upload for better reliability"""
    try:
        # Use S3 client's upload_file method which automatically handles multipart for large files
        s3_client.upload_file(
            file_path,
            BUCKET_NAME,
            s3_key,
            ExtraArgs={
                'ContentType': 'video/mp4',
                'ServerSideEncryption': 'AES256'
            }
        )
        logger.info(f"Successfully uploaded to S3: {s3_key}")
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        raise VideoProcessingError(f"S3 upload failed ({error_code}): {str(e)}")
    except Exception as e:
        raise VideoProcessingError(f"Unexpected error during S3 upload: {str(e)}")


def upload_with_presigned_url(file_path: str, s3_key: str) -> None:
    """Fallback method using presigned URL with robust session"""
    s3_client = create_s3_client()
    
    try:
        # Generate presigned URL with longer expiration
        presigned_url = s3_client.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": BUCKET_NAME,
                "Key": s3_key,
                "ContentType": "video/mp4"
            },
            ExpiresIn=7200  # 2 hours
        )
        
        session = create_robust_session()
        
        with open(file_path, "rb") as f:
            headers = {
                "Content-Type": "video/mp4",
                "User-Agent": "ytdl-microservice/1.0"
            }
            
            logger.info("Starting upload via presigned URL")
            response = session.put(
                presigned_url,
                data=f,
                headers=headers,
                timeout=(60, 600)  # 10 minutes for upload
            )
            
            response.raise_for_status()
            logger.info("Upload completed successfully via presigned URL")
            
    except requests.exceptions.SSLError as e:
        raise VideoProcessingError(f"SSL error during upload: {str(e)}")
    except requests.exceptions.Timeout as e:
        raise VideoProcessingError(f"Upload timed out: {str(e)}")
    except requests.exceptions.RequestException as e:
        raise VideoProcessingError(f"Upload failed: {str(e)}")


def cleanup_temp_file(file_path: str) -> None:
    """Safely cleanup temporary files"""
    try:
        if os.path.exists(file_path):
            os.remove(file_path)
            logger.info(f"Cleaned up temporary file: {file_path}")
    except Exception as e:
        logger.warning(f"Failed to cleanup {file_path}: {str(e)}")


def process_and_upload(url: str) -> str:
    """
    Main function to download YouTube video and upload to S3
    
    Args:
        url: YouTube video URL
        
    Returns:
        S3 key of uploaded file
        
    Raises:
        VideoProcessingError: If any step fails
    """
    validate_environment()
    
    folder_uuid = str(uuid.uuid4())
    s3_key = f"{folder_uuid}/original.mp4"
    
    # Use a more secure temporary directory
    with tempfile.TemporaryDirectory() as temp_dir:
        tmp_output = os.path.join(temp_dir, f"{folder_uuid}.mp4")
        
        try:
            # Step 1: Download video
            download_video(url, tmp_output)
            
            # Step 2: Validate file
            validate_file(tmp_output)
            
            # Step 3: Upload to S3 (try multipart first, fallback to presigned URL)
            s3_client = create_s3_client()
            
            try:
                upload_to_s3_multipart(s3_client, tmp_output, s3_key)
            except VideoProcessingError as e:
                logger.warning(f"Multipart upload failed: {str(e)}")
                logger.info("Falling back to presigned URL upload")
                upload_with_presigned_url(tmp_output, s3_key)
            
            logger.info(f"Process completed successfully. S3 key: {s3_key}")
            return s3_key
            
        except VideoProcessingError:
            raise
        except Exception as e:
            logger.error(f"Unexpected error: {str(e)}")
            raise VideoProcessingError(f"Unexpected error: {str(e)}")