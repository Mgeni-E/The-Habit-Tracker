#!/usr/bin/env python3
"""
Entry point for running the Habit Tracker application.
This script can be used for both development and production.
"""

import os
import sys
from dotenv import load_dotenv

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Load environment variables
load_dotenv()

# Import and create the Flask app
from app import create_app

app = create_app()

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000) 