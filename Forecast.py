import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import AdaBoostClassifier
from sklearn.metrics import accuracy_score
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import RandomForestClassifier



# Reload the file to ensure we're working with the correct data
file_path = '/Users/bert/Documents/Documents - Bert’s MacBook Pro/Imperial/Data to Product/CW/LDN - EDI/Final Data Sources/to_forecast_from.csv'
forecast_df = pd.read_csv(file_path)

# Convert non-numeric columns to numeric using label encoding
label_encoder = LabelEncoder()
non_numeric_columns = forecast_df.select_dtypes(include=['object']).columns
for column in non_numeric_columns:
    forecast_df[column] = label_encoder.fit_transform(forecast_df[column].astype(str))

# Remove rows where 'delay_length' is NaN and make a copy to avoid the warning
#forecast_df_cleaned = forecast_df.dropna(subset=['delay_length']).copy()

#Change rows where 'delay_length is NaN to 0
forecast_df['delay_length'].fillna(0, inplace=True)

# For weather-related columns ('tempmax', 'tempmin', 'precip', 'snow', 'windgust'), replacing Nan with medium
#weather_columns = ['tempmax', 'tempmin', 'precip', 'snow', 'windgust']
weather_columns = ['tempmin', 'snow', 'windgust']
forecast_df[weather_columns] = forecast_df[weather_columns].fillna(forecast_df[weather_columns].median())

# Because of pervious naming
forecast_df_cleaned = forecast_df

# Transform 'delay_length' into intervals of 10
bins = range(int(forecast_df_cleaned['delay_length'].min()), int(forecast_df_cleaned['delay_length'].max()) + 10, 10)
labels = [f'{i}-{i+9}' for i in range(int(forecast_df_cleaned['delay_length'].min()), int(forecast_df_cleaned['delay_length'].max()), 10)]
forecast_df_cleaned['delay_length'] = pd.cut(forecast_df_cleaned['delay_length'], bins=bins, labels=labels, right=False)

# Exclude the 'date_of_service' column from the features
X = forecast_df_cleaned.drop(['delay_length', 'date_of_service'], axis=1)  # features
y = forecast_df_cleaned['delay_length']  # target

# Splitting the data into train and test sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Initialize the base classifier
base_clf = DecisionTreeClassifier()

# Initialize the AdaBoost classifier with the base classifier
ada_clf = AdaBoostClassifier(base_estimator=base_clf, n_estimators=50, random_state=42)

# Fit the AdaBoost classifier on the training data
ada_clf.fit(X_train, y_train)

# Make predictions on the test set
y_pred = ada_clf.predict(X_test)

# Calculate the accuracy
accuracy = accuracy_score(y_test, y_pred)
print(accuracy)
print('Y-pred = ', y_pred)

# Add a new column to see values predicted
X_test['predicted values'] = y_pred
X_test['real values'] = y_test

#saving as csv to check
output_file_path = '/Users/bert/Documents/Documents - Bert’s MacBook Pro/Imperial/Data to Product/CW/LDN - EDI/Final Data Sources/check_forecast.csv' 

# Save the sorted DataFrame to a new CSV file
X_test.to_csv(output_file_path, index=False)

#////////////////////
# Code for prediction

