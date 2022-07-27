#!/usr/bin/python
import os, psycopg2
database = os.environ.get('PG_DATABASE', "kong, keycloak")
user = os.environ.get('PG_USER', "postgres")
password = os.environ.get('PG_PASSWORD', "password")
host = os.environ.get('PG_HOST', "postgresql")
port = os.environ.get('PG_PORT', "5432")
database = database.strip()
database = database.split(",")
conn = psycopg2.connect(database="postgres", user=user, password=password, host=host, port=port)
conn.autocommit = True
for db in database:
    try:
      sql = "CREATE database " + db.strip() + ";"
      cursor = conn.cursor()
      cursor.execute(sql)
      print("Database " + db.strip() + " created successfully")
    except psycopg2.errors.DuplicateDatabase:
      print ("Database " + db.strip() + " already exists")
conn.close()