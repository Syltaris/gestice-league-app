# Import libraries
import numpy as np
from flask import Flask, flash, request, redirect, url_for, jsonify
import pickle
import os
from os.path import join, dirname, realpath
from werkzeug.utils import secure_filename

APP_ROOT = ''
UPLOAD_FOLDER = "/mnt/c/Github_Repos/zex-flutter-makerthon/server/training_files/"
ALLOWED_EXTENSIONS = set(['txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif'])

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

model = pickle.load(open('model.pkl','rb'))

# Load the model
@app.route('/api/predict',methods=['POST'])
def predict():
    # # Get the data from the POST request.
    data =request.get_json()

    if len(data) < 30: return '300'

    print(len(data))
    data = np.array(data)
    data = data.flatten()
    # # Make prediction using model loaded from disk as per the data.
    prediction = model.predict([data])
    # Take the first value of prediction
    output = prediction[0]
    return jsonify(output)
    return '200'

def allowed_file(filename):
    return '.' in filename and \
        filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/api/upload', methods=['POST'])
def upload():
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
            filename = secure_filename(file.filename)
            file.save(os.path.join(APP_ROOT, app.config['UPLOAD_FOLDER'], filename))
            return 'uploaded'
    return 'ok'

if __name__ == '__main__':
    app.run(port=5000, debug=True)