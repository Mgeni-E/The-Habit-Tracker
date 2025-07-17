from flask import Flask
from flask_wtf.csrf import CSRFProtect
from .models.habit import db
from .config import config
import os

csrf = CSRFProtect()


def create_app(config_name=None, test_config=None):
    app = Flask(__name__)

    # Load configuration
    if config_name is None:
        config_name = os.environ.get("FLASK_ENV", "development")

    app.config.from_object(config[config_name])
    if test_config:
        app.config.update(test_config)

    # Initialize extensions
    db.init_app(app)
    csrf.init_app(app)

    # Initialize database tables
    with app.app_context():
        from .init_db_helper import init_database_tables
        init_database_tables()

    # Register blueprints
    from .routes.habit_routes import main_bp

    app.register_blueprint(main_bp)

    return app
