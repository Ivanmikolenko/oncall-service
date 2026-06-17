FROM python:3.11-slim

RUN mkdir -p /var/log/oncall-service

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/healthz')" || exit 1

CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:8080", "--timeout", "30", "wsgi:app"]
