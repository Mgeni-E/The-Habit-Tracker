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
        db.create_all()
        inspector = inspect(db.engine)


if __name__ == "__main__":
    init_database()
