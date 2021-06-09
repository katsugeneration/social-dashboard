# Python image to use.
FROM python:3.9

# Set the working directory to /app
WORKDIR /app

# Copy the rest of the working directory contents into the container at /app
COPY pyproject.toml poetry.lock ./

RUN pip install poetry && poetry export -f requirements.txt --without-hashes --output requirements.txt && pip install -r requirements.txt

COPY . .

ENTRYPOINT ["uvicorn"]
CMD ["main:app", "--host", "0.0.0.0", "--port", "8080"]
