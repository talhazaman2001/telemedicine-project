import boto3

# Initialise DynamoDB Client
dynamodb = boto3.resource('dynamodb', region_name = 'eu-west-2')
table = dynamodb.Table('GlucoseLevels')

# Fetch the data from DynamoDB
response = table.scan()
glucose_data = response['Items']

print(glucose_data)

import psycopg2

# RDS PostgreSQL credentials
rds_host = "<your-rds-endpoint>" # Placeholder for the endpoint
name = "admin"
password = "password123"
db_name = "telemedicinedb"

# Connect to RDS instance
connection = psycopg2.connect(
    host = rds_host,
    user = name,
    password = password,
    dbname = db_name
)

# Query data from RDS 
with connection.cursor() as cursor:
    cursor.execute("SELECT * FROM patient_records;")
    result = cursor.fetchall()

print(result)
