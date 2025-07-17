from datetime import datetime, date, timedelta
from flask_sqlalchemy import SQLAlchemy
from dateutil.relativedelta import relativedelta

db = SQLAlchemy()

class Habit(db.Model):
    __tablename__ = 'habits'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    frequency = db.Column(db.String(20), nullable=False)  # 'daily' or 'weekly'
    start_date = db.Column(db.Date, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationship
    completions = db.relationship('Completion', backref='habit', lazy=True, cascade='all, delete-orphan')
    
    def __repr__(self):
        return f'<Habit {self.name}>'
    
    def get_completion_dates(self):
        """Get all completion dates for this habit"""
        return [comp.date_completed for comp in self.completions]
    
    def is_completed_today(self):
        """Check if habit is completed today"""
        today = date.today()
        return any(comp.date_completed == today for comp in self.completions)
    
    def get_current_streak(self):
        """Calculate current streak"""
        if not self.completions:
            return 0
        
        completion_dates = sorted([comp.date_completed for comp in self.completions], reverse=True)
        today = date.today()
        
        # If no completion today and yesterday, streak is 0
        if completion_dates[0] < today - timedelta(days=1):
            return 0
        
        streak = 0
        current_date = today
        
        while current_date in completion_dates:
            streak += 1
            current_date -= timedelta(days=1)
        
        return streak
    
    def get_longest_streak(self):
        """Calculate longest streak"""
        if not self.completions:
            return 0
        
        completion_dates = sorted([comp.date_completed for comp in self.completions])
        if not completion_dates:
            return 0
        
        longest_streak = 1
        current_streak = 1
        
        for i in range(1, len(completion_dates)):
            if (completion_dates[i] - completion_dates[i-1]).days == 1:
                current_streak += 1
                longest_streak = max(longest_streak, current_streak)
            else:
                current_streak = 1
        
        return longest_streak
    
    def get_completion_percentage(self):
        """Calculate completion percentage since start date"""
        if not self.completions:
            return 0.0
        
        today = date.today()
        days_since_start = (today - self.start_date).days + 1
        
        if days_since_start <= 0:
            return 0.0
        
        completion_count = len(self.completions)
        percentage = (completion_count / days_since_start) * 100
        
        return round(percentage, 1)

class Completion(db.Model):
    __tablename__ = 'completions'
    
    id = db.Column(db.Integer, primary_key=True)
    habit_id = db.Column(db.Integer, db.ForeignKey('habits.id'), nullable=False)
    date_completed = db.Column(db.Date, nullable=False, default=date.today)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<Completion {self.habit_id} on {self.date_completed}>' 