from sqlalchemy import inspect
from .models.habit import db


def init_database_tables():
    """Initialize the database with all tables."""
    inspector = inspect(db.engine)

    # Check existing tables before creation
    habits_exists = inspector.has_table('habits')
    completions_exists = inspector.has_table('completions')

    if habits_exists and completions_exists:
        print("✅ Database tables already exist - no changes needed")
    else:
        print("🔧 Creating missing database tables...")
        db.create_all()
        print("✅ Database tables created successfully!")

    # Verify final state
    inspector = inspect(db.engine)
    habits_final = inspector.has_table('habits')
    completions_final = inspector.has_table('completions')

    print(f"📋 Final state:")
    print(f"   - Habits table: {'✅ EXISTS' if habits_final else '❌ MISSING'}")
    print(f"   - Completions table: {'✅ EXISTS' if completions_final else '❌ MISSING'}")

    if not (habits_final and completions_final):
        raise Exception("Database initialization failed - missing tables")

    print("🎉 Database initialization completed successfully!")
