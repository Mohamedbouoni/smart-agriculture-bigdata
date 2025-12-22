# Setting Up the Project (For Teammates)

This guide explains how to get the Smart Agriculture infrastructure running on your local machine exactly as it is configured now.

## 1. Prerequisites
Ensure you have the following installed:
*   **Docker Desktop** (Make sure it's running)
*   **Git**

## 2. Installation
1.  **Clone the repository**:
    ```bash
    git clone https://github.com/Mohamedbouoni/smart-agriculture-bigdata.git
    cd smart-agriculture-bigdata
    ```

## 3. Build & Deploy Infrastructure
We use standard Docker images, so there is no need to manually build anything. Run this single command to download the images (HDFS, Mongo, Postgres) and start the containers:

```bash
docker-compose up -d
```
*Note: The first time you run this, it may take 5-10 minutes to download the large Hadoop images.*

## 4. Configuration (Schemas)
The database tables and collections are **automatically created** when the containers start for the first time, using the scripts in the `./scripts/` folder.

### **If you need to re-run or manually apply the configuration:**
Run these commands in your terminal:

**PostgreSQL (Metadata)**
```bash
# 1. Create Fields
docker exec postgres psql -U admin -d smart_agri -c "CREATE TABLE IF NOT EXISTS fields (field_id VARCHAR(50) PRIMARY KEY, name VARCHAR(100) NOT NULL, location_lat DECIMAL(10, 7), location_lon DECIMAL(10, 7), area_hectares DECIMAL(10, 2), soil_type VARCHAR(50), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

# 2. Create Sensors
docker exec postgres psql -U admin -d smart_agri -c "CREATE TABLE IF NOT EXISTS sensors (sensor_id VARCHAR(50) PRIMARY KEY, field_id VARCHAR(50) REFERENCES fields(field_id), sensor_type VARCHAR(20) NOT NULL, status VARCHAR(20) DEFAULT 'active', last_maintenance DATE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

# 3. Create Users
docker exec postgres psql -U admin -d smart_agri -c "CREATE TABLE IF NOT EXISTS users (user_id SERIAL PRIMARY KEY, username VARCHAR(50) UNIQUE NOT NULL, email VARCHAR(100), role VARCHAR(20) CHECK (role IN ('farmer', 'researcher', 'admin')) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

# 4. Create Crops
docker exec postgres psql -U admin -d smart_agri -c "CREATE TABLE IF NOT EXISTS crops (crop_id SERIAL PRIMARY KEY, name VARCHAR(50) NOT NULL, optimal_temp_min DECIMAL(5,2), optimal_temp_max DECIMAL(5,2), optimal_humidity_min DECIMAL(5,2), optimal_humidity_max DECIMAL(5,2), description TEXT);"

# 5. Create Field-Crop Relations
docker exec postgres psql -U admin -d smart_agri -c "CREATE TABLE IF NOT EXISTS field_crops (id SERIAL PRIMARY KEY, field_id VARCHAR(50) REFERENCES fields(field_id), crop_id INTEGER REFERENCES crops(crop_id), planting_date DATE, harvest_date DATE, status VARCHAR(20) DEFAULT 'active', created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
```

**MongoDB (Sensor Data)**
```bash
# Initialize Collections & Indexes
docker exec mongodb mongosh smart_agri --eval "db.createCollection('sensor_data'); db.sensor_data.createIndex({ 'timestamp': -1 }); db.sensor_data.createIndex({ 'sensor_id': 1 }); db.createCollection('alerts'); db.createCollection('disease_records');"
```

## 5. Verification
Check that everything is running:
```bash
docker ps
```
You should see:
*   `namenode` (HDFS Master)
*   `datanode1`, `datanode2`, `datanode3` (HDFS Slaves)
*   `mongodb` (NoSQL Database)
*   `postgres` (SQL Database)
