from flask import Blueprint, render_template, redirect, url_for, flash
from ..models.habit import Habit, Completion, db
from ..forms.habit_form import HabitForm
from datetime import date, datetime

main_bp = Blueprint("main", __name__)


@main_bp.route("/")
def index():
    """Homepage - list all habits with progress summary"""
    habits = Habit.query.all()

    # Calculate overall statistics
    total_habits = len(habits)
    completed_today = sum(1 for habit in habits if habit.is_completed_today())

    return render_template(
        "index.html",
        habits=habits,
        total_habits=total_habits,
        completed_today=completed_today,
    )


@main_bp.route("/habit/new", methods=["GET", "POST"])
def new_habit():
    """Create a new habit"""
    form = HabitForm()

    if form.validate_on_submit():
        habit = Habit(
            name=form.name.data,
            frequency=form.frequency.data,
            start_date=form.start_date.data,
        )
        db.session.add(habit)
        db.session.commit()
        flash("Habit created successfully!", "success")
        return redirect(url_for("main.index"))

    return render_template("habit_form.html", form=form, title="New Habit")


@main_bp.route("/habit/<int:habit_id>")
def habit_detail(habit_id):
    """View habit details"""
    habit = Habit.query.get_or_404(habit_id)
    completion_dates = habit.get_completion_dates()

    return render_template(
        "habit_detail.html", habit=habit, completion_dates=completion_dates
    )


@main_bp.route("/habit/<int:habit_id>/complete", methods=["POST"])
def complete_habit(habit_id):
    """Mark habit as completed for today"""
    today = date.today()

    # Check if already completed today
    existing_completion = Completion.query.filter_by(
        habit_id=habit_id, date_completed=today
    ).first()

    if existing_completion:
        flash("Habit already completed today!", "info")
    else:
        completion = Completion(habit_id=habit_id, date_completed=today)
        db.session.add(completion)
        db.session.commit()
        flash("Habit marked as completed!", "success")

    return redirect(url_for("main.habit_detail", habit_id=habit_id))


@main_bp.route("/habit/<int:habit_id>/edit", methods=["GET", "POST"])
def edit_habit(habit_id):
    """Edit an existing habit"""
    habit = Habit.query.get_or_404(habit_id)
    form = HabitForm(obj=habit)

    if form.validate_on_submit():
        habit.name = form.name.data
        habit.frequency = form.frequency.data
        habit.start_date = form.start_date.data
        db.session.commit()
        flash("Habit updated successfully!", "success")
        return redirect(url_for("main.habit_detail", habit_id=habit_id))

    return render_template(
        "habit_form.html", form=form, habit=habit, title="Edit Habit"
    )


@main_bp.route("/habit/<int:habit_id>/delete", methods=["POST"])
def delete_habit(habit_id):
    """Delete a habit"""
    habit = Habit.query.get_or_404(habit_id)
    db.session.delete(habit)
    db.session.commit()
    flash("Habit deleted successfully!", "success")
    return redirect(url_for("main.index"))


@main_bp.route("/habit/<int:habit_id>/uncomplete/<date_str>", methods=["POST"])
def uncomplete_habit(habit_id, date_str):
    """Remove a completion for a specific date"""
    try:
        completion_date = datetime.strptime(date_str, "%Y-%m-%d").date()
        completion = Completion.query.filter_by(
            habit_id=habit_id, date_completed=completion_date
        ).first()

        if completion:
            db.session.delete(completion)
            db.session.commit()
            flash("Completion removed!", "success")
        else:
            flash("Completion not found!", "error")

    except ValueError:
        flash("Invalid date format!", "error")

    return redirect(url_for("main.habit_detail", habit_id=habit_id))
