# Importing the libraries
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.neighbors import KNeighborsClassifier
import pickle
import requests
import json
import glob

SAMPLING_FREQ = 30.0
columns = ['aX', 'aY', 'aZ', 'gX', 'gY', 'gZ']
# Importing the dataset

training_files = glob.glob('training_files/*.txt')
frames = []
labels = []


for file in training_files:
    label = int(file[len('training_files/')])

    x = pd.read_csv(file, index_col=False, header=None, names=columns)
    x.columns.name = 'time'
    x = x.dropna()

    samples = int(len(x) / SAMPLING_FREQ)
    for i in range(0, samples):
        y = x.iloc[i*30:(i+1)*30]

        if len(y) < int(SAMPLING_FREQ) : break

        # time = np.arange(0, int(SAMPLING_FREQ)).reshape([-1, 1])
        # time = time / SAMPLING_FREQ 
        # y.index = time

        frames.append(y.values.flatten())
        labels.append(label)

# print(frames)
# print(labels)

# # Splitting the dataset into the Training set and Test set
X_train, X_test, y_train, y_test = train_test_split(frames, labels, test_size = 0.3, random_state = 21, stratify=labels)

knn = KNeighborsClassifier(n_neighbors=8)
knn.fit(X_train, y_train)

prediction = knn.predict(X_test)

print(prediction == y_test)



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