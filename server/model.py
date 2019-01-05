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
import sqlite3

SAMPLING_FREQ = 60.0
SAMPLING_RATE = int(SAMPLING_FREQ)
columns = ['aX', 'aY', 'aZ', 'gX', 'gY', 'gZ']
# Importing the dataset

training_files = glob.glob('training_files/*.txt')
frames = []
labels = []

conn = sqlite3.connect('training_data.db')
cur = conn.execute("select tbl_name from sqlite_master where type='table'")
tables = cur.fetchall()

for table in tables:
    # label = int(file[len('training_files/')])
    # x = pd.read_csv(file, index_col=False, header=None, names=columns)
    # x.columns.name = 'time'
    # x = x.dropna()

    label = int(table[0][-1:])
    query = "SELECT ax, ay, az, gx, gy, gz FROM {}".format(table[0])
    print(query)
    x = pd.read_sql_query(query, conn)
    print(x)

    samples = int(len(x) / SAMPLING_FREQ)
    for i in range(0, samples):
        y = x.iloc[i*SAMPLING_RATE:(i+1)*SAMPLING_RATE]

        if len(y) < int(SAMPLING_FREQ) : break

        # time = np.arange(0, int(SAMPLING_FREQ)).reshape([-1, 1])
        # time = time / SAMPLING_FREQ 
        # y.index = time

        frames.append(y.values.flatten())
        labels.append(label)

def train_knn():
    # # Splitting the dataset into the Training set and Test set
    X_train, X_test, y_train, y_test = train_test_split(frames, labels, test_size = 0.3, random_state = 21, stratify=labels)

    knn = KNeighborsClassifier(n_neighbors=8)
    knn.fit(X_train, y_train)

    prediction = knn.predict(X_test)

    pickle.dump(knn, open('model.pkl','wb'))

    print(prediction == y_test)

if __name__ == '__main__':
    train_knn()

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