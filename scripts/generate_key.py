#!/usr/bin/env python3
"""
Script to generate API keys for the YouTube downloader microservice
"""

import secrets
import sys
import argparse

def generate_api_key(length: int = 32) -> str:
    """Generate a secure API key"""
    return secrets.token_urlsafe(length)

def main():
    parser = argparse.ArgumentParser(description="Generate API keys for ytdl-microservice")
    parser.add_argument(
        "--length", 
        type=int, 
        default=32, 
        help="Length of the API key (default: 32)"
    )
    parser.add_argument(
        "--count", 
        type=int, 
        default=1, 
        help="Number of keys to generate (default: 1)"
    )
    
    args = parser.parse_args()
    
    if args.length < 16:
        print("Warning: Key length should be at least 16 characters for security", file=sys.stderr)
    
    print("Generated API Key(s):")
    print("=" * 50)
    
    for i in range(args.count):
        key = generate_api_key(args.length)
        print(f"Key {i+1}: {key}")
    
    print("=" * 50)
    print("\nUsage:")
    print("1. Set as environment variable:")
    print("   export API_KEY='<your_key_here>'")
    print("\n2. Use in HTTP requests:")
    print("   curl -H 'Authorization: Bearer <your_key_here>' \\")
    print("        -H 'Content-Type: application/json' \\")
    print("        -d '{\"youtube_url\": \"https://youtube.com/watch?v=...\"}' \\")
    print("        http://localhost:8000/download")
    print("\n3. For multiple keys, use:")
    print("   export API_KEY_1='<key1>'")
    print("   export API_KEY_2='<key2>'")
    print("   # or")
    print("   export API_KEYS='<key1>,<key2>,<key3>'")

if __name__ == "__main__":
    main()