#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset



if [ -z "${POSTGRES_USER}" ]; then
    base_postgres_image_default_user='postgres'
    export POSTGRES_USER="${base_postgres_image_default_user}"
fi
export DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"

python << END
import sys
import os
import time

import psycopg2
from psycopg2 import sql

suggest_unrecoverable_after = 30
start = time.time()

while True:
    try:
        conn = psycopg2.connect(
            dbname="postgres",
            user="${POSTGRES_USER}",
            password="${POSTGRES_PASSWORD}",
            host="${POSTGRES_HOST}",
            port="${POSTGRES_PORT}",
        )
        

        conn.autocommit = True
        cursor = conn.cursor()

        db_name = "${POSTGRES_DB}"

        check_database_query = sql.SQL("SELECT 1 FROM pg_database WHERE datname = '{}'").format(sql.Identifier(db_name))

        cursor.execute(check_database_query)
        database_exists = cursor.fetchone()

        if not database_exists:
            try:
                cursor.execute(f"CREATE DATABASE {db_name};")
                sys.stderr.write("Database created...\n")
            except psycopg2.errors.DuplicateDatabase as error:
                sys.stderr.write("Database already exist...\n")
        else:
            sys.stderr.write("Database already exist...\n")

        cursor.close()
        conn.close()

        
        break
    except psycopg2.OperationalError as error:
        sys.stderr.write("Waiting for PostgreSQL to become available...\n")
        print(">>>>\n")
        print(os.environ.get("DATABASE_URL"))
        print(">>>>\n")

        if time.time() - start > suggest_unrecoverable_after:
            sys.stderr.write("  This is taking longer than expected. The following exception may be indicative of an unrecoverable error: '{}'\n".format(error))

    time.sleep(1)
END

>&2 echo 'PostgreSQL is available'

exec "$@"

