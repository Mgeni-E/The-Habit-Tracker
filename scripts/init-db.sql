-- =============================================================================
-- Habit Tracker Database Initialization Script
-- =============================================================================

-- Create database if it doesn't exist (this is handled by POSTGRES_DB env var)
-- CREATE DATABASE IF NOT EXISTS habit_tracker;

-- Connect to the habit_tracker database
\c habit_tracker;

-- Create extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Set timezone
SET timezone = 'UTC';

-- Create a simple health check function
CREATE OR REPLACE FUNCTION health_check()
RETURNS TEXT AS $$
BEGIN
    RETURN 'Database is healthy at ' || NOW();
END;
$$ LANGUAGE plpgsql;

-- Grant permissions to the application user
GRANT ALL PRIVILEGES ON DATABASE habit_tracker TO habitadmin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO habitadmin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO habitadmin;

-- Note: Application tables will be created by Flask-Migrate
-- This script only sets up the basic database structure and permissions
