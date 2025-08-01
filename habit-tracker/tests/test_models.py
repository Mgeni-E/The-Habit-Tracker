import pytest
from datetime import date, timedelta
from app import create_app, db
from app.models import Habit, Completion


@pytest.fixture
def app():
    test_config = {
        "TESTING": True,
        "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:",
        "WTF_CSRF_ENABLED": False,
        "SECRET_KEY": "test-secret-key",
    }
    app = create_app(test_config=test_config)
    with app.app_context():
        db.create_all()
        yield app
        db.session.remove()
        db.drop_all()


@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture
def sample_habit(app):
    with app.app_context():
        habit = Habit(
            name="Test Habit",
            frequency="daily",
            start_date=date.today() - timedelta(days=7),
        )
        db.session.add(habit)
        db.session.commit()
        return habit


class TestHabitModel:
    def test_habit_creation(self, app):
        with app.app_context():
            habit = Habit(
                name="Exercise", frequency="daily", start_date=date.today()
            )
            db.session.add(habit)
            db.session.commit()

            assert habit.id is not None
            assert habit.name == "Exercise"
            assert habit.frequency == "daily"

    def test_is_completed_today_no_completions(self, app):
        with app.app_context():
            habit = Habit(
                name="Test Habit", frequency="daily", start_date=date.today()
            )
            db.session.add(habit)
            db.session.commit()

            assert not habit.is_completed_today()

    def test_is_completed_today_with_completion(self, app):
        with app.app_context():
            habit = Habit(
                name="Test Habit", frequency="daily", start_date=date.today()
            )
            db.session.add(habit)
            db.session.commit()

            completion = Completion(
                habit_id=habit.id, date_completed=date.today()
            )
            db.session.add(completion)
            db.session.commit()

            assert habit.is_completed_today()

    def test_get_current_streak_no_completions(self, app):
        with app.app_context():
            habit = Habit(
                name="Test Habit", frequency="daily", start_date=date.today()
            )
            db.session.add(habit)
            db.session.commit()

            assert habit.get_current_streak() == 0

    def test_get_current_streak_with_completions(self, app):
        with app.app_context():
            habit = Habit(
                name="Test Habit", frequency="daily", start_date=date.today()
            )
            db.session.add(habit)
            db.session.commit()

            today = date.today()
            yesterday = today - timedelta(days=1)

            for d in [yesterday, today]:
                completion = Completion(habit_id=habit.id, date_completed=d)
                db.session.add(completion)
            db.session.commit()

            assert habit.get_current_streak() == 2

    def test_get_longest_streak_no_completions(self, app):
        with app.app_context():
            habit = Habit(
                name="Test Habit", frequency="daily", start_date=date.today()
            )
            db.session.add(habit)
            db.session.commit()

            assert habit.get_longest_streak() == 0

    def test_get_longest_streak_with_completions(self, app):
        with app.app_context():
            habit = Habit(
                name="Test Habit", frequency="daily", start_date=date.today()
            )
            db.session.add(habit)
            db.session.commit()

            today = date.today()
            dates = [
                today,
                today - timedelta(days=1),
                today - timedelta(days=2),
            ]

            for d in dates:
                completion = Completion(habit_id=habit.id, date_completed=d)
                db.session.add(completion)
            db.session.commit()

            assert habit.get_longest_streak() == 3

    def test_get_completion_percentage_no_completions(self, app):
        with app.app_context():
            habit = Habit(
                name="Test Habit", frequency="daily", start_date=date.today()
            )
            db.session.add(habit)
            db.session.commit()

            assert habit.get_completion_percentage() == 0.0

    def test_get_completion_percentage_with_completions(self, app):
        with app.app_context():
            habit = Habit(
                name="Test Habit",
                frequency="daily",
                start_date=date.today() - timedelta(days=7),
            )
            db.session.add(habit)
            db.session.commit()

            today = date.today()
            dates = [
                today,
                today - timedelta(days=1),
                today - timedelta(days=2),
            ]

            for d in dates:
                completion = Completion(habit_id=habit.id, date_completed=d)
                db.session.add(completion)
            db.session.commit()

            percentage = habit.get_completion_percentage()
            assert percentage > 0
