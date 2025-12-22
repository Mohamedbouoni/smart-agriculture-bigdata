CREATE TABLE IF NOT EXISTS fields (
    field_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location_lat DECIMAL(10, 7),
    location_lon DECIMAL(10, 7),
    area_hectares DECIMAL(10, 2),
    soil_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sensors (
    sensor_id VARCHAR(50) PRIMARY KEY,
    field_id VARCHAR(50) REFERENCES fields(field_id),
    sensor_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    last_maintenance DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS batch_jobs (
    job_id SERIAL PRIMARY KEY,
    job_name VARCHAR(100) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    status VARCHAR(20) DEFAULT 'running',
    records_processed INTEGER,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS analytics_summary (
    id SERIAL PRIMARY KEY,
    analysis_date DATE NOT NULL,
    field_id VARCHAR(50),
    total_readings INTEGER,
    avg_temperature DECIMAL(5, 2),
    avg_moisture DECIMAL(5, 2),
    disease_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- [NEW] Users Table for Role Management
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100),
    role VARCHAR(20) CHECK (role IN ('farmer', 'researcher', 'admin')) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- [NEW] Crops Table for Agricultural Metadata
CREATE TABLE IF NOT EXISTS crops (
    crop_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    optimal_temp_min DECIMAL(5,2),
    optimal_temp_max DECIMAL(5,2),
    optimal_humidity_min DECIMAL(5,2),
    optimal_humidity_max DECIMAL(5,2),
    description TEXT
);

-- [NEW] Field-Crop Association (History of what was planted where)
CREATE TABLE IF NOT EXISTS field_crops (
    id SERIAL PRIMARY KEY,
    field_id VARCHAR(50) REFERENCES fields(field_id),
    crop_id INTEGER REFERENCES crops(crop_id),
    planting_date DATE,
    harvest_date DATE,
    status VARCHAR(20) DEFAULT 'active', -- active, harvested
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample fields
INSERT INTO fields (field_id, name, location_lat, location_lon, area_hectares, soil_type)
VALUES 
    ('FIELD_A', 'North Field', 36.8065, 10.1815, 5.5, 'clay_loam'),
    ('FIELD_B', 'South Field', 36.8045, 10.1825, 4.2, 'sandy_loam'),
    ('FIELD_C', 'East Field', 36.8055, 10.1835, 6.8, 'silt_loam')
ON CONFLICT (field_id) DO NOTHING;

-- Insert sample users
INSERT INTO users (username, email, role) VALUES 
('farmer_joe', 'joe@farm.com', 'farmer'),
('dr_smith', 'smith@agri-research.org', 'researcher')
ON CONFLICT (username) DO NOTHING;

-- Insert sample crops
INSERT INTO crops (name, optimal_temp_min, optimal_temp_max, optimal_humidity_min, optimal_humidity_max) VALUES
('Tomato', 18.0, 29.0, 60.0, 85.0),
('Potato', 15.0, 25.0, 70.0, 90.0),
('Corn', 20.0, 30.0, 50.0, 70.0);

-- Assign crops to fields
INSERT INTO field_crops (field_id, crop_id, planting_date, status) VALUES
('FIELD_A', 1, '2025-01-15', 'active'), -- Tomato in Field A
('FIELD_B', 2, '2025-02-01', 'active'); -- Potato in Field B

-- Create indexes
CREATE INDEX idx_batch_jobs_created ON batch_jobs(created_at);
CREATE INDEX idx_analytics_date ON analytics_summary(analysis_date);
CREATE INDEX idx_sensors_field ON sensors(field_id);
