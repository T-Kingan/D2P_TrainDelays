import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import AdaBoostClassifier
from sklearn.metrics import accuracy_score


file_path = '/Users/bert/Documents/Documents - Bert’s MacBook Pro/Imperial/Data to Product/CW/LDN - EDI/Final Data Sources/to_forecast_from.csv'
forecast_df = pd.read_csv(file_path)


#Change rows where 'delay_length is NaN to 0
forecast_df['delay_length'].fillna(0, inplace=True)

# Because of pervious naming
forecast_df_cleaned = forecast_df

#//////////////////// Split into bins

# Define new bin edges
bins = [-np.inf, 0, np.inf]

# Define new labels
labels = ['x<=0', 'x>0']

# Bin the 'delay_length' data with the updated bins and labels
forecast_df_cleaned['delay_length'] = pd.cut(forecast_df_cleaned['delay_length'], bins=bins, labels=labels)

#////////////////////////////

# Exclude the 'date_of_service' & 'flattened_delay_reasons' column from the features
X = forecast_df_cleaned.drop(['delay_length', 'date_of_service', 'flattened_delay_reasons', 'day_type'], axis=1)  # features
y = forecast_df_cleaned['delay_length']  # target

# Splitting the data into train and test sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

#//////////////////////// testing differnt implementation of ABC
# Create adaboost classifer object
abc = AdaBoostClassifier(n_estimators=50, learning_rate=1, random_state=0)

# Train Adaboost Classifer
model1 = abc.fit(X_train, y_train)

#Predict the response for test dataset
y_pred = model1.predict(X_test)

# calculate and print model accuracy
print("AdaBoost Classifier Model Accuracy:", accuracy_score(y_test, y_pred))


#////////////////////
# Code for prediction

# load file to predict from
file_path2 = '/Users/bert/Documents/Documents - Bert’s MacBook Pro/Imperial/Data to Product/CW/LDN - EDI/Future Data/predict_from_this.csv'
predict_from_df = pd.read_csv(file_path2)

# drop 'date_of_service' column ()
predict_from_df_less_date = predict_from_df.drop(['date_of_service'], axis=1)

# Do the predicting
y_pred2 = model1.predict(predict_from_df_less_date)

# Get the probability estimates
probabilities = model1.predict_proba(predict_from_df_less_date)

predict_from_df['low']=0
predict_from_df['medium']=0
predict_from_df['high']=0

# Add the array with delay probabilitues as new columns
predict_from_df['prob_not_late'] = [item[0] for item in probabilities]
predict_from_df['prob_late'] = [item[1] for item in probabilities]

# Iterates through rows in data frame if probability of being late is above a cetrain risk threshold then a 1 is added to the column to indicate delay likely for that given level of risk
for index, row in predict_from_df.iterrows():
    if row['prob_late'] >= 0.4960 and row['prob_late'] < 0.4968:
        predict_from_df.loc[index, 'high'] = 1
    elif row['prob_late'] >= 0.4968 and row['prob_late'] < 0.4982:
        predict_from_df.loc[index, 'medium'] = 1
        predict_from_df.loc[index, 'high'] = 1
    elif row['prob_late'] >= 0.4982:
        predict_from_df.loc[index, 'low'] = 1 
        predict_from_df.loc[index, 'medium'] = 1
        predict_from_df.loc[index, 'high'] = 1       


# Add the forecasted delays onto the future schedule
predict_from_df['predicted delay'] = y_pred2


#saving as csv to check
output_file_path = '/Users/bert/Documents/Documents - Bert’s MacBook Pro/Imperial/Data to Product/CW/LDN - EDI/Final Data Sources/lookup_table.csv' 

# Save the sorted DataFrame to a new CSV file
predict_from_df.to_csv(output_file_path, index=False)
