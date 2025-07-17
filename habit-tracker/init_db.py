import os
import sys
from sqlalchemy import inspect
from app import create_app
from app.models.habit import db

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


def init_database():
    """Initialize the database with all tables."""
    app = create_app()

    with app.app_context():
        print("Creating database tables...")
        db.create_all()
        print("Database tables created successfully!")

        inspector = inspect(db.engine)
        print(f"Habit table exists: {inspector.has_table('habits')}")
        print(f"Completion table exists: {inspector.has_table('completions')}")


if __name__ == "__main__":
    init_database()
