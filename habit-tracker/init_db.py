#!/usr/bin/env python3
"""
Database initialization script for Habit Tracker.
This script creates the database tables and can be used for initial setup.
"""

import os
import sys
from sqlalchemy import inspect

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from app.models.habit import db

def init_database():
    """Initialize the database with all tables."""
    app = create_app()
    
    with app.app_context():
        print("Creating database tables...")
        db.create_all()
        print("Database tables created successfully!")
        
        # Check if tables were created using the correct SQLAlchemy API
        inspector = inspect(db.engine)
        print(f"Habit table exists: {inspector.has_table('habits')}")
        print(f"Completion table exists: {inspector.has_table('completions')}")

if __name__ == '__main__':
    init_database() 