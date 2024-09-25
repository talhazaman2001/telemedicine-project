from flask import Flask, jsonify, request

app = Flask(__name__)

# In-memory patient data store (simulating a database)
patients = []

# Endpoint to get all patients
@app.route('/patients', methods = ['GET'])
def get_patients():
    return jsonify(patients), 200

# Endpoint to add a new patient
@app.route('/patients', methods = ['POST'])
def add_patient():
    patient = request.json
    patients.append(patient)
    return jsonify({"message": "Patient added successfully"}), 201

# Endpoint to get a patient by ID
@app.route('/patients/<int:patient_id>', methods = ['GET'])
def get_patient(patient_id):
    patient = next((p for p in patients if p['id'] == patient_id), None)
    if patient:
        return jsonify(patient), 200
    return jsonify({"message": "Patient not found"}), 404

if __name__ == '__main__':
    app.run(host = '0.0.0.0', port = 5000)