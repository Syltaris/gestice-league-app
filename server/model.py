# Importing the libraries
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
import pickle
import requests
import json

SAMPLING_FREQ = 30.0
columns = ['aX', 'aY', 'aZ', 'gX', 'gY', 'gZ']
# Importing the dataset
x = pd.read_csv('training_files/0.txt', index_col=False, header=None, names=columns)

x.columns.name = 'time'
time = np.arange(0, len(x)).reshape([-1, 1])
time = time / SAMPLING_FREQ 
x.index = time

X =x.dropna()
print(x)
# # Splitting the dataset into the Training set and Test set
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size = 1/3, random_state = 0)
# # Fitting Simple Linear Regression to the Training set
# regressor = LinearRegression()
# regressor.fit(X_train, y_train)
# # Predicting the Test set results
# y_pred = regressor.predict(X_test)
# # Saving model to disk
# pickle.dump(regressor, open('model.pkl','wb'))
# # Loading model to compare the results
# model = pickle.load(open('model.pkl','rb'))
# print(model.predict([[1.8]]))