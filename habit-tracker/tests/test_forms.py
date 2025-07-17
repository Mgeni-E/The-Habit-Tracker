import pytest
from datetime import date
from app import create_app
from app.forms import HabitForm


@pytest.fixture
def app():
    app = create_app()
    app.config["TESTING"] = True
    app.config["WTF_CSRF_ENABLED"] = False
    return app


class TestHabitForm:
    def test_valid_form(self, app):
        """Test form with valid data."""
        with app.app_context():
            form = HabitForm()
            form.name.data = "Exercise"
            form.frequency.data = "daily"
            form.start_date.data = date.today()

            assert form.validate()
            assert len(form.errors) == 0

    def test_empty_name(self, app):
        """Test form with empty name."""
        with app.app_context():
            form = HabitForm()
            form.name.data = ""
            form.frequency.data = "daily"
            form.start_date.data = date.today()

            assert not form.validate()
            assert "name" in form.errors

    def test_missing_frequency(self, app):
        """Test form with missing frequency."""
        with app.app_context():
            form = HabitForm()
            form.name.data = "Exercise"
            form.frequency.data = ""
            form.start_date.data = date.today()

            assert not form.validate()
            assert "frequency" in form.errors

    def test_missing_start_date(self, app):
        """Test form with missing start date."""
        with app.app_context():
            form = HabitForm()
            form.name.data = "Exercise"
            form.frequency.data = "daily"
            form.start_date.data = None

            assert not form.validate()
            assert "start_date" in form.errors

    def test_name_too_long(self, app):
        """Test form with name too long."""
        with app.app_context():
            form = HabitForm()
            form.name.data = "A" * 101  # 101 characters
            form.frequency.data = "daily"
            form.start_date.data = date.today()

            assert not form.validate()
            assert "name" in form.errors

    def test_frequency_choices(self, app):
        """Test frequency field choices."""
        with app.app_context():
            form = HabitForm()
            choices = [choice[0] for choice in form.frequency.choices]
            assert "daily" in choices
            assert "weekly" in choices

    def test_default_start_date(self, app):
        """Test that start_date defaults to today."""
        with app.app_context():
            form = HabitForm()
            assert form.start_date.data == date.today()
