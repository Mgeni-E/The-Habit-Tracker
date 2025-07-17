from flask_wtf import FlaskForm
from wtforms import StringField, SelectField, DateField, SubmitField
from wtforms.validators import DataRequired, Length
from datetime import date

class HabitForm(FlaskForm):
    name = StringField('Habit Name', validators=[
        DataRequired(message='Habit name is required'),
        Length(min=1, max=100, message='Habit name must be between 1 and 100 characters')
    ])
    
    frequency = SelectField('Frequency', choices=[
        ('daily', 'Daily'),
        ('weekly', 'Weekly')
    ], validators=[DataRequired(message='Please select a frequency')])
    
    start_date = DateField('Start Date', validators=[
        DataRequired(message='Start date is required')
    ], default=date.today)
    
    submit = SubmitField('Save Habit') 