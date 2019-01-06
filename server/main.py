# Import libraries
from ast import literal_eval
import numpy as np
import pandas as pd
from flask import Flask, flash, request, redirect, url_for, jsonify
from flask_sockets import Sockets
import pickle
import os
from os.path import join, dirname, realpath
from werkzeug.utils import secure_filename
import sqlite3
from model import train_knn


APP_ROOT = os.path.dirname(os.path.abspath(__file__))#"/mnt/c/Github_Repos/zex-flutter-makerthon/server/"
UPLOAD_FOLDER = "training_files/"
ALLOWED_EXTENSIONS = set(['txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif'])
columns = ['aX', 'aY', 'aZ', 'gX', 'gY', 'gZ']

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
sockets = Sockets(app)

model = pickle.load(open('model.pkl','rb'))# Load the model

@sockets.route('/')
def test_socket(ws):
    while not ws.closed:
        data = ws.receive()
        data = np.array(literal_eval(data))

        #data =request.get_json()
        #if len(data) < 30: return '300'
        data = data.flatten()
        # # Make prediction using model loaded from disk as per the data.
        prediction = model.predict([data])
        # Take the first value of prediction
        output = prediction[0]
        ws.send(str(output))
        print(output)

@app.route('/api/predict',methods=['POST'])
def predict():
    # # Get the data from the POST request.
    data = request.get_json()
    if len(data) < 30: return '300'
    print(len(data))
    data = np.array(data)
    data = data.flatten()
    # # Make prediction using model loaded from disk as per the data.
    prediction = model.predict([data])
    # Take the first value of prediction
    output = prediction[0]
    print(output)
    return jsonify(output)
    return '200'

def allowed_file(filename):
    return '.' in filename and \
        filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/api/upload', methods=['POST'])
def upload():
    conn = sqlite3.connect('training_data.db')

    if request.method == 'POST':
        # check if the post request has the file part
        if 'file' not in request.files:
            flash('No file part')
            return redirect(request.url)
        file = request.files['file']
        # if user does not select file, browser also
        # submit an empty part without filename
        if file.filename == '':
            flash('No selected file')
            return redirect(request.url)
        if file and allowed_file(file.filename):
            x = pd.read_csv(file, index_col=False, header=None, names=columns)
            x.columns.name = 'time'
            x = x.dropna()

            data = x.values#np.loadtxt(file, delimiter=',', dtype=str)
            #data = data.flatten()
            print(data)

            tablename = "file"+file.filename[0]
            conn.execute("DROP TABLE IF EXISTS {}".format(tablename))
            conn.execute("CREATE TABLE IF NOT EXISTS {}(id INTEGER PRIMARY KEY, ax, ay, az, gx, gy, gz)".format(tablename))
            for row in data[:]:
                cur = conn.execute("INSERT into {} (ax, ay, az, gx, gy, gz) values ({}, {}, {}, {}, {}, {})".format(tablename,row[0], row[1], row[2], row[3], row[4], row[5]))
            conn.commit()
            cur = conn.execute("select count(*) from {}".format(tablename))
            print(str(cur.fetchone()[0]) + " datapoints inserted")
            conn.close()

            model = None
            train_knn()
            model = pickle.load(open('model.pkl','rb'))# Load the model
           
            # filename = secure_filename(file.filename)
            # file.save(os.path.join(APP_ROOT, app.config['UPLOAD_FOLDER'], filename))
            return 'uploaded'
    return 'ok'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)