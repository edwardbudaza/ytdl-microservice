# � YouTube Downloader Microservice

<div align="center">
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI">
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white" alt="AWS">
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python">
</div>

A secure, token-authenticated microservice that downloads YouTube videos using `yt-dlp`, and uploads them to an AWS S3 bucket. Built with FastAPI and ready for production deployment using Docker.

---

## 📦 Table of Contents
- [Folder Structure](#-folder-structure)
- [Configuration](#-configuration)
- [Security Features](#-security-features)
- [Usage](#-usage)
- [API Reference](#-api-reference)
- [Rate Limiting](#-rate-limiting)
- [Requirements](#-requirements)
- [Production Tips](#-production-tips)

---

## 📁 Folder Structure

```plaintext
.
├── Dockerfile                 # Docker container configuration
├── README.md                  # Project documentation
├── app/
│   ├── __init__.py
│   ├── auth.py                # API key verification
│   ├── downloader.py          # yt-dlp download logic
│   └── main.py                # FastAPI route handler
├── cookies/
│   └── youtube_cookies.txt    # YouTube cookies file
├── docker-compose.yml         # Docker Compose setup
├── logs/                      # Application logs
├── requirements.txt           # Python dependencies
└── scripts/
    └── generate_key.py        # Secure API key generator
```

> ⚠️ You **must** place your YouTube cookies file at `cookies/youtube_cookies.txt` for successful downloads, especially from age-restricted or private videos. Export cookies using [this extension](https://chrome.google.com/webstore/detail/cookies-txt/lpcaedmchfhocbbapmcbpinfpgnhiddi).

---

## ⚙️ Configuration

Create an `.env` file using the example below:

### `.env.example`

```env
# AWS Configuration
AWS_BUCKET_NAME=your-s3-bucket-name
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key-id
AWS_SECRET_ACCESS_KEY=your-secret-access-key

# Authentication
# Generate this using: python scripts/generate_key.py
API_KEY=your-secure-api-key

# Optional: Multiple keys
API_KEY_1=another-api-key
API_KEY_2=another-key-2
API_KEYS=comma,separated,keys

# Rate limiting (optional)
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=3600
```
# 🔐 Security Features
✅ Bearer Token Authentication
✅ Secure SHA-256 Hashed API Keys
✅ Optional Multiple API Key Support
✅ Built-in Rate Limiting
✅ No Public Access Without Token
✅ Input Validation for URLs

# 🔧 Usage
1. ✅ Generate API Key
```bash
python scripts/generate_key.py
```

2. 🔐 Set API Key
Update your .env file with the generated key:
```bash
cp .env.example .env
# Then edit .env to include your real values
```

3. 🚀 Run with Docker Compose
```bash
docker-compose up -d
```

# 🧪 Test Authentication
A simple test script is provided:

```scripts/test_auth.py```
```python
#!/usr/bin/env python3
"""
Script to test authentication for the YouTube downloader microservice
"""

import requests
import argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--api-key", required=True)
    parser.add_argument("--url", default="http://localhost:8000/download")
    parser.add_argument("--youtube-url", default="https://youtube.com/watch?v=dQw4w9WgXcQ")
    args = parser.parse_args()

    headers = {
        "Authorization": f"Bearer {args.api_key}",
        "Content-Type": "application/json"
    }

    response = requests.post(args.url, json={"youtube_url": args.youtube_url}, headers=headers)
    print("Status:", response.status_code)
    print("Response:", response.text)

if __name__ == "__main__":
    main()
```
Run it like:
```bash
python scripts/test_auth.py --api-key your-api-key
```

# 🛠️ API Reference
🔍 Health Check (No Auth)
```bash
 GET /health
```
⬇️ Download Endpoint (Requires Token)
```bash
POST /download
```
Request Body (JSON)
```json
{
  "youtube_url": "https://youtube.com/watch?v=..."
}
```
Headers
```pgsql
Authorization: Bearer your-api-key
Content-Type: application/json
```
Response
Returns the S3 key (not full URL):
```json
{
  "s3_key": "downloads/your_video_filename.mp4"
}
```
# 🛡️ Rate Limiting
Default:
<ul>
    <li>100 requests per API key</li>
    <li>3600 seconds (1 hour) window</li>
</ul>
Customizable using:
```env
RATE_LIMIT_REQUESTS=200
RATE_LIMIT_WINDOW=1800
```

# ✅ Requirements
```makefile
fastapi==0.104.1
uvicorn[standard]==0.24.0
boto3==1.34.0
botocore==1.34.0
requests==2.31.0
urllib3==2.1.0
pydantic==2.5.0
yt-dlp==2023.12.30
python-multipart==0.0.6
python-jose[cryptography]==3.3.0
```

# 📦 Production Tips
<ul>
    <li>Mount persistent volume for /logs and cookies/</li>
    <li>Use a secrets manager for .env injection</li>
    <li>Enforce HTTPS and CORS at a reverse proxy level (e.g., Traefik or Nginx)</li>
</ul>

# 👨‍💻 Author
Built with ❤️ by Edward Budaza






