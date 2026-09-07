FROM python:3.12-slim

WORKDIR /app

COPY app.py test_app.py ./

CMD ["python3", "-m", "unittest", "-v", "test_app.py"]
