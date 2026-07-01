# Small, production-style image. Slim base keeps the ECR footprint low.
FROM python:3.12-slim

WORKDIR /app

# Install deps first so Docker layer caching speeds up rebuilds.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY index.html .

# Run as a non-root user (least privilege inside the container).
RUN useradd --create-home appuser
USER appuser

ENV PORT=8080
EXPOSE 8080

# gunicorn with 2 workers — right-sized for a 0.25 vCPU Fargate task.
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
