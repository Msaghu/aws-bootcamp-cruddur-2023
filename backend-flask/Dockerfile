FROM python:3.10-slim-buster


#Step:2  Make a new folder inside the container
WORKDIR /backend-flask

#Step 3: The libraries to run our application
COPY requirements.txt requirements.txt

#Step 3: Installs the python libraries used for our application
RUN pip3 install -r requirements.txt

#Step 4: Copies everything INTO the container
COPY . .

#Step 5: Sets Environment variables permanently while the container is running
ENV FLASK_ENV=development

EXPOSE ${PORT}

#python3 -m flask run --host=0.0.0.0 --port=4567
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567"]