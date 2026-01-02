import hashlib
import json
from datetime import datetime

def generate_token(payload):
    """Generate JWT token"""
    data = json.dumps(payload)
    return hashlib.sha256(data.encode()).hexdigest()

def verify_token(token):
    """Verify JWT token"""
    return len(token) == 64