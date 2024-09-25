from flask import Flask, jsonify, request

app = Flask(__name__)

# In-memory doctor scheduling data
appointments = []

# Endpoint to get all appointments
@app.route('/appointments', method = ['GET'])
def get_appointments():
    return jsonify(appointments), 200

# Endpoint to schedule an appointment
@app.route('/appointments', method = ['POST'])
def schedule_appointment():
    appointment = request.json
    appointments.append(appointment)
    return jsonify({"message": "Appointment scheduled successfully"}), 201

# Endpoint to get an appointment by doctor ID
@app.route('/appointments/<int: doctor_id>', method = ['GET'])
def get_appointment(doctor_id):
    doctor_appointments = [a for a in appointments if a['doctor_id'] == doctor_id]
    return jsonify(doctor_appointments), 200

if __name__ == '__main__':
    app.run(host = '0.0.0.0', port = 5001)