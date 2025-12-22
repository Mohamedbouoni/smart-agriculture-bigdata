# Smart Agriculture Big Data Infrastructure

This project sets up a comprehensive Big Data architecture for Smart Agriculture using Docker. It includes a Hadoop HDFS cluster, MongoDB for NoSQL storage, and PostgreSQL for metadata management.

## Prerequisites

*   Docker
*   Docker Compose
*   Git (optional, for cloning)

## 🚀 Quick Start

1.  **Start the Infrastructure**
    Run the following command to download images and start all services (HDFS, MongoDB, Postgres):
    ```bash
    docker-compose up -d
    ```
    *Note: The first run may take a few minutes to pull the Docker images.*

2.  **Verify Running Services**
    Check if all containers are healthy:
    ```bash
    docker ps
    ```
    You should see: `namenode`, `datanode1-3`, `mongodb`, and `postgres`.

3.  **Stop the Infrastructure**
    To stop the containers:
    ```bash
    docker-compose stop
    ```
    To stop and **remove** containers (data is preserved in volumes):
    ```bash
    docker-compose down
    ```
    To stop and **delete all data** (clean start):
    ```bash
    docker-compose down -v
    ```

---

## 🛠 Configuration & Schemas

The database schemas are automatically applied on the first run using the scripts in the `./scripts` folder.

### PostgreSQL (Metadata)
*   **Connection**: `localhost:5432`
*   **User/Pass**: `admin` / `admin`
*   **Database**: `smart_agri`
*   **File**: `scripts/init_postgres.sql`

**Manual access via CLI:**
```bash
docker exec -it postgres psql -U admin -d smart_agri
```
**List tables command:**
```sql
\dt
```

### MongoDB (Sensor Data & Logs)
*   **Connection**: `localhost:27017`
*   **Database**: `smart_agri`
*   **File**: `scripts/init_mongo.js`

**Manual access via CLI:**
```bash
docker exec -it mongodb mongosh smart_agri
```
**List collections command:**
```javascript
show collections
```

### Hadoop HDFS (File Storage)
*   **NameNode UI**: [http://localhost:9870](http://localhost:9870)
*   **File Browser**: [http://localhost:9870/explorer.html](http://localhost:9870/explorer.html)

**Check DataNodes status:**
```bash
docker exec -it namenode hdfs dfsadmin -report
```

---

## 🧠 How It Works: Auto-Initialization

You might wonder how the tables and collections are created automatically without running manual commands.

1.  **Volume Mapping**: In `docker-compose.yml`, we mount our local scripts to a special directory inside the containers:
    ```yaml
    # Postgres Example
    volumes:
      - ./scripts/init_postgres.sql:/docker-entrypoint-initdb.d/init_postgres.sql
    ```

2.  **Docker Magic**:
    *   **Postgres Image**: Automatically executes `*.sql` files found in `/docker-entrypoint-initdb.d/` when the container starts for the first time.
    *   **Mongo Image**: Automatically executes `*.js` files found in `/docker-entrypoint-initdb.d/` when the container starts for the first time.

3.  **Persistence**: This only happens if the database volume (`pg_data` or `mongo_data`) is **empty**. Once initialized, the data persists. If you change the scripts, you must delete the volumes (`docker-compose down -v`) to re-trigger this process.

---

## 📂 Project Structure

```
├── docker-compose.yml       # Service orchestration
├── hadoop.env               # Hadoop environment variables
├── scripts/
│   ├── init_mongo.js        # MongoDB schema script
│   ├── init_postgres.sql    # PostgreSQL schema script
│   └── generate_data.py     # Python script to generate synthetic data
└── data_simulation/         # Output folder for generated data
```

---

## 🛠 Manual Schema Creation Commands

If you prefer to run the commands manually (or need to re-apply them), here are the exact `docker exec` one-liners.

### PostgreSQL Tables

**1. Fields Table**
```bash
docker exec postgres psql -U admin -d smart_agri -c "CREATE TABLE IF NOT EXISTS fields (field_id VARCHAR(50) PRIMARY KEY, name VARCHAR(100) NOT NULL, location_lat DECIMAL(10, 7), location_lon DECIMAL(10, 7), area_hectares DECIMAL(10, 2), soil_type VARCHAR(50), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
```

**2. Sensors Table**
```bash
docker exec postgres psql -U admin -d smart_agri -c "CREATE TABLE IF NOT EXISTS sensors (sensor_id VARCHAR(50) PRIMARY KEY, field_id VARCHAR(50) REFERENCES fields(field_id), sensor_type VARCHAR(20) NOT NULL, status VARCHAR(20) DEFAULT 'active', last_maintenance DATE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
```

**3. Batch Jobs Table**
```bash
docker exec postgres psql -U admin -d smart_agri -c "CREATE TABLE IF NOT EXISTS batch_jobs (job_id SERIAL PRIMARY KEY, job_name VARCHAR(100) NOT NULL, start_time TIMESTAMP NOT NULL, end_time TIMESTAMP, status VARCHAR(20) DEFAULT 'running', records_processed INTEGER, error_message TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
```

**4. Analytics Summary Table**
```bash
docker exec postgres psql -U admin -d smart_agri -c "CREATE TABLE IF NOT EXISTS analytics_summary (id SERIAL PRIMARY KEY, analysis_date DATE NOT NULL, field_id VARCHAR(50), total_readings INTEGER, avg_temperature DECIMAL(5, 2), avg_moisture DECIMAL(5, 2), disease_count INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
```

**5. Users Table**
```bash
docker exec postgres psql -U admin -d smart_agri -c "CREATE TABLE IF NOT EXISTS users (user_id SERIAL PRIMARY KEY, username VARCHAR(50) UNIQUE NOT NULL, email VARCHAR(100), role VARCHAR(20) CHECK (role IN ('farmer', 'researcher', 'admin')) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
```

**6. Crops Table**
```bash
docker exec postgres psql -U admin -d smart_agri -c "CREATE TABLE IF NOT EXISTS crops (crop_id SERIAL PRIMARY KEY, name VARCHAR(50) NOT NULL, optimal_temp_min DECIMAL(5,2), optimal_temp_max DECIMAL(5,2), optimal_humidity_min DECIMAL(5,2), optimal_humidity_max DECIMAL(5,2), description TEXT);"
```

**7. Field-Crops Association Table**
```bash
docker exec postgres psql -U admin -d smart_agri -c "CREATE TABLE IF NOT EXISTS field_crops (id SERIAL PRIMARY KEY, field_id VARCHAR(50) REFERENCES fields(field_id), crop_id INTEGER REFERENCES crops(crop_id), planting_date DATE, harvest_date DATE, status VARCHAR(20) DEFAULT 'active', created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
```

### MongoDB Collections & Indexes

**1. Sensor Data**
```bash
docker exec mongodb mongosh smart_agri --eval "db.createCollection('sensor_data'); db.sensor_data.createIndex({ 'timestamp': -1 }); db.sensor_data.createIndex({ 'sensor_id': 1, 'timestamp': -1 }); db.sensor_data.createIndex({ 'location.field_id': 1 }); db.sensor_data.createIndex({ 'sensor_type': 1 });"
```

**2. Disease Records**
```bash
docker exec mongodb mongosh smart_agri --eval "db.createCollection('disease_records'); db.disease_records.createIndex({ 'detection_date': -1 }); db.disease_records.createIndex({ 'field_id': 1 }); db.disease_records.createIndex({ 'plant_type': 1 }); db.disease_records.createIndex({ 'disease': 1 }); db.disease_records.createIndex({ 'severity': 1 });"
```

**3. Alerts**
```bash
docker exec mongodb mongosh smart_agri --eval "db.createCollection('alerts'); db.alerts.createIndex({ 'created_at': -1 }); db.alerts.createIndex({ 'status': 1 }); db.alerts.createIndex({ 'field_id': 1 });"
```

**4. Other Collections**
```bash
docker exec mongodb mongosh smart_agri --eval "db.createCollection('weather_data'); db.createCollection('analytics_results');"
```
