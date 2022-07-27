#!/usr/bin/python
import os, psycopg2
database = os.environ.get('PG_DATABASE', "postgres")
user = os.environ.get('PG_USER', "kong, keycloak")
password = os.environ.get('PG_PASSWORD', "password")
host = os.environ.get('PG_HOST', "postgresql")
port = os.environ.get('PG_PORT', "5432")
user = user.split(",")
conn = psycopg2.connect(database=database, user="postgres", password=password, host=host, port=port)
conn.autocommit = True
for u in user:
    try:
      sql = "CREATE USER " + u.strip() + " WITH PASSWORD '" + password + "';"
      grant = "GRANT ALL ON DATABASE " + u.strip() + " TO " + u.strip();
      cursor = conn.cursor()
      cursor.execute(sql)
      cursor.execute(grant)
      print("User " + u.strip() + " created successfully")
    except psycopg2.errors.DuplicateObject:
      print ("User " + u.strip() + " already exists")
for u in user:
      grant = "GRANT ALL ON DATABASE " + u.strip() + " TO " + u.strip();
      cursor = conn.cursor()
      cursor.execute(grant)
      print("User " + u.strip() + " granted access on database " + u.strip())
conn.close()