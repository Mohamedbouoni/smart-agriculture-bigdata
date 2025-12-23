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
docker-compose up -d --build
```
*Note: The `--build` flag ensures that if we add custom Dockerfiles later (e.g., for Spark or Gateway), they are built. For now, it pulls the standard images.*

## 4. Architecture & Docker Images
We use the following official and stable images:
*   **Hadoop NameNode**: `bde2020/hadoop-namenode:2.0.0-hadoop3.2.1-java8`
*   **Hadoop DataNodes**: `bde2020/hadoop-datanode:2.0.0-hadoop3.2.1-java8`
*   **MongoDB**: `mongo:latest`
*   **PostgreSQL**: `postgres:13`

## 5. Generating Data (Necessary Step)
To test the system, you need data. We have a script to generate synthetic sensor readings and disease logs.

### Requirements
*   Python 3.x
*   `pymongo` library

### Run the Generator
```bash
# 1. Install dependency
pip install pymongo

# 2. Run the script
python scripts/generate_data.py
```
This will:
*   Generate `sensor_readings.json` and `disease_logs.json` in `./data_simulation/`.
*   Directly insert sample data into **MongoDB** (collection: `sensor_data`).

## 6. Configuration (Schemas)
The database tables and collections are **automatically created** when the containers start for the first time, using the scripts in the `./scripts/` folder.

### **If you need to re-run or manually apply the configuration:**
Run these commands in your terminal:

## 7. Backup & Recovery
We provide PowerShell scripts in the `scripts/` folder to manage data backups.

### **Backup**
Creates a timestamped backup of both Postgres and MongoDB in the `./backups` folder.
```powershell
./scripts/backup.ps1
```

### **Restore**
Restores database from a specific timestamp (WARNING: Overwrites current data).
```powershell
./scripts/restore.ps1 -Timestamp "20251223_120000"
```

---

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
