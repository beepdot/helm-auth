FROM python:2.7.18
RUN pip install retry PyJWT
COPY kong-api-scripts /kong-api-scripts
CMD ["python", "/kong-api-scripts/kong_consumers.py", "/kong_consumers.json", "--kong-admin-api-url=http://kong:8001"]
