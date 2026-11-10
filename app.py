import os

import pymysql
from flask import Flask

app = Flask(__name__)


def check_db_connection():
    """Return True when the database answers."""
    try:
        connection = pymysql.connect(
            host=os.environ.get("DB_HOST", "localhost"),
            user=os.environ.get("DB_USER", "root"),
            password=os.environ.get("DB_PASSWORD", ""),
            database=os.environ.get("DB_NAME", "test"),
            connect_timeout=3,
        )
        connection.close()
        return True
    except Exception as e:
        print("Failed to connect to database:", e)
        return False


@app.route("/")
def index():
    if check_db_connection():
        return "Database Connection Status: Connected"
    return "Database Connection Status: Disconnected"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)