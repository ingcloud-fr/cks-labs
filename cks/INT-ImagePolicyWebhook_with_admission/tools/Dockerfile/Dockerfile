# Dockerfile
FROM python:3.9-slim

RUN pip install flask

COPY server.py /app/server-validating.py
WORKDIR /app

CMD ["python", "-u", "server-validating.py"]