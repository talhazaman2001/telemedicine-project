# Train the Model
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix

# DataFrame with Glucose Levels and Anomaly Flags
glucose_data = pd.DataFrame({
    'glucose_level': [80, 90, 150, 200, 180],
    'anomaly_flag': [0, 0, 0, 1, 1]    # O = normal, 1 = anomalous
})

X = glucose_data['glucose_level'].values.reshape(-1,1)
y = glucose_data['anomaly_flag']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size = 0.2)

model = RandomForestClassifier(n_estimators = 100)
model.fit(X_train, y_train)

predictions = model.predict(X_test)
accuracy = accuracy_score(y_test, predictions)

print(f"Model Accuracy: {accuracy *100}%")

import sagemaker
from sagemaker.sklearn import SKLearnModel

# Save the model artifact
model.save("model.tar.gz")

# Deploy the Model

role = "${aws_iam_role.sagemaker_execution_role.arn}"

sklearn_model = SKLearnModel(model_data='s3://sagemaker-bucket/model.tar.gz',
                             role = role,
                             entry_point = 'predictor.py')

predictor = sklearn_model.deploy(initial_instance_count =1, instance_type = 'm1.m5.large')

result = predictor.predict({"glucose_level": 120})
print(result)

