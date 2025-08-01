import pytest
from datetime import date
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


class TestIndexRoute:
    def test_index_empty(self, client):
        """Test homepage with no habits."""
        response = client.get("/")
        assert response.status_code == 200
        assert b"No habits yet!" in response.data

    def test_index_with_habits(self, client, app):
        """Test homepage with existing habits."""
        with app.app_context():
            habit = Habit(
                name="Test Habit", frequency="daily", start_date=date.today()
            )
            db.session.add(habit)
            db.session.commit()

        response = client.get("/")
        assert response.status_code == 200
        assert b"Test Habit" in response.data
        assert b"Total Habits" in response.data


class TestNewHabitRoute:
    def test_new_habit_get(self, client):
        """Test GET request to new habit form."""
        response = client.get("/habit/new")
        assert response.status_code == 200
        assert b"New Habit" in response.data
        assert b"name" in response.data

    def test_new_habit_post_valid(self, client):
        """Test POST request with valid data."""
        data = {
            "name": "Exercise",
            "frequency": "daily",
            "start_date": date.today().strftime("%Y-%m-%d"),
        }
        response = client.post("/habit/new", data=data, follow_redirects=True)
        assert response.status_code == 200
        assert b"Exercise" in response.data


class TestHabitDetailRoute:
    def test_habit_detail_existing(self, client, app):
        """Test viewing an existing habit."""
        with app.app_context():
            habit = Habit(
                name="Test Habit", frequency="daily", start_date=date.today()
            )
            db.session.add(habit)
            db.session.commit()
            habit_id = habit.id

        response = client.get(f"/habit/{habit_id}")
        assert response.status_code == 200
        assert b"Test Habit" in response.data
        assert b"Current Streak" in response.data

    def test_habit_detail_nonexistent(self, client):
        """Test viewing a non-existent habit."""
        response = client.get("/habit/999")
        assert response.status_code == 404


class TestCompleteHabitRoute:
    def test_complete_habit_success(self, client, app):
        """Test marking a habit as completed."""
        with app.app_context():
            habit = Habit(
                name="Test Habit", frequency="daily", start_date=date.today()
            )
            db.session.add(habit)
            db.session.commit()
            habit_id = habit.id

        response = client.post(
            f"/habit/{habit_id}/complete", follow_redirects=True
        )
        assert response.status_code == 200
        assert b"completed" in response.data.lower()

    def test_complete_habit_already_completed(self, client, app):
        """Test completing a habit that's already completed today."""
        with app.app_context():
            habit = Habit(
                name="Test Habit", frequency="daily", start_date=date.today()
            )
            db.session.add(habit)
            db.session.commit()
            habit_id = habit.id

            # First completion
            completion = Completion(
                habit_id=habit_id, date_completed=date.today()
            )
            db.session.add(completion)
            db.session.commit()

        # Try to complete again
        response = client.post(
            f"/habit/{habit_id}/complete", follow_redirects=True
        )
        assert response.status_code == 200
        assert b"already completed" in response.data.lower()


class TestEditHabitRoute:
    def test_edit_habit_get(self, client, app):
        """Test GET request to edit habit form."""
        with app.app_context():
            habit = Habit(
                name="Test Habit", frequency="daily", start_date=date.today()
            )
            db.session.add(habit)
            db.session.commit()
            habit_id = habit.id

        response = client.get(f"/habit/{habit_id}/edit")
        assert response.status_code == 200
        assert b"Edit Habit" in response.data
        assert b"Test Habit" in response.data

    def test_edit_habit_post_valid(self, client, app):
        """Test POST request with valid data."""
        with app.app_context():
            habit = Habit(
                name="Test Habit", frequency="daily", start_date=date.today()
            )
            db.session.add(habit)
            db.session.commit()
            habit_id = habit.id

        data = {
            "name": "Updated Habit",
            "frequency": "weekly",
            "start_date": date.today().strftime("%Y-%m-%d"),
        }
        response = client.post(
            f"/habit/{habit_id}/edit", data=data, follow_redirects=True
        )
        assert response.status_code == 200
        assert b"Updated Habit" in response.data


class TestDeleteHabitRoute:
    def test_delete_habit_success(self, client, app):
        """Test deleting a habit."""
        with app.app_context():
            habit = Habit(
                name="Test Habit", frequency="daily", start_date=date.today()
            )
            db.session.add(habit)
            db.session.commit()
            habit_id = habit.id

        response = client.post(
            f"/habit/{habit_id}/delete", follow_redirects=True
        )
        assert response.status_code == 200
        assert b"deleted successfully" in response.data.lower()
