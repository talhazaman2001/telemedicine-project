from flask import Flask, jsonify, request

app = Flask(__name__)

# In-memory store for health data (e.g. heart rate, blood pressure)
health_data = []

# Endpoint to get all health metrics
@app.route('/health-data', methods = ['GET'])
def get_health_data():
    return jsonify(health_data), 200

# Endpoint to add new health metrics (e.g. from IoT devices)
@app.route('/health-data', methods = ['POST'])
def add_health_data():
    data = request.json
    health_data.append(data)
    return jsonify({"message": "Health Data added successfully"})

# Endpoint to get health metrics by patient ID
@app.route('/health-data/<int: patient_id>', methods = ['GET'])
def get_health_data(patient_id):
    patient_data = [d for d in health_data if d['patient_id'] == patient_id]
    return jsonify(patient_data), 200

if __name__ == '__main__':
    app.run(host = '0.0.0.0', port = 5002)