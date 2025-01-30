# just an example for now
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY fetch_data.py .
CMD ["python", "fetch_data.py"]