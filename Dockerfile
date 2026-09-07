FROM python:3.12-slim

WORKDIR /app

COPY app.py test_app.py server.py ./

EXPOSE 8080

CMD ["python3", "server.py"]
