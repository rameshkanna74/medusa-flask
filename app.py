import os
from flask import Flask, render_template, request, redirect
from flask_sqlalchemy import SQLAlchemy
import pyodbc

app = Flask(__name__)

# Configure your MSSQL database URI
# Replace the placeholders with your actual MSSQL database credentials
app.config["SQLALCHEMY_DATABASE_URI"] = (
    "mssql+pyodbc://<username>:<password>@<server>/<database>?driver=ODBC+Driver+17+for+SQL+Server"
)

# Disable tracking modifications to improve performance
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db = SQLAlchemy(app)


class database_model(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.String(200), nullable=False)

    def __init__(self, title, description):
        self.title = title
        self.description = description

    def __repr__(self):
        return (
            f"Id:{self.id}, Title is {self.title}, Descriptions is {self.description}"
        )


# Function to connect to the database and execute a sample query
def dbConnect():
    conn_str = """Driver={ODBC Driver 18 for SQL Server};Server=tcp:aurexdb.database.windows.net;Database=AUREXDB1;Uid=db_su;Pwd={=!Aurexus21!=};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"""
    cnxn = pyodbc.connect(conn_str)
    if cnxn:
        cursor = cnxn.cursor()
        cursor.execute("SELECT top(1) * FROM HUB_TEST")
        rows = cursor.fetchall()
        for row in rows:
            return str(row)
    else:
        print("Problem in Connection...")
    # Close the cursor and connection
    cursor.close()
    cnxn.close()


@app.route("/")
def hello_world():
    # Execute the dbConnect function to fetch data from MSSQL database
    db_result = dbConnect()
    print(db_result)
    return render_template("view.html", db_result=db_result)


# Your other routes remain the same...

if __name__ == "__main__":
    # Create all tables
    db.create_all()
    app.run(debug=True)
