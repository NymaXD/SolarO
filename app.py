"""Módulo que incializa la API de SolarO"""

import os

from flask import Flask
from dotenv import load_dotenv

from extensions import db, bcrypt, jwt, mail
from auth.routes import auth
import models

from datetime import timedelta

load_dotenv()

app = Flask(__name__)

# === CONFIGURACION PARA ORM ===
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ["DATABASE_URL"]
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

# === CONFIGURACION JWT ===
app.config["JWT_SECRET_KEY"] = os.environ["JWT_SECRET_KEY"]
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(minutes=15)

# === CONFIGURACION MAIL ===
app.config["MAIL_SERVER"] = os.environ.get("MAIL_SERVER", "smtp.gmail.com")
app.config["MAIL_PORT"] = int(os.environ.get("MAIL_PORT", "587"))
app.config["MAIL_USE_TLS"] = True
app.config["MAIL_USE_SSL"] = False
app.config["MAIL_USERNAME"] = os.environ["MAIL_USERNAME"]
app.config["MAIL_PASSWORD"] = os.environ["MAIL_PASSWORD"]
app.config["MAIL_DEFAULT_SENDER"] = os.environ["MAIL_USERNAME"]
app.config["FRONTEND_URL"] = os.environ["FRONTEND_URL"]

db.init_app(app)
bcrypt.init_app(app)
jwt.init_app(app)
mail.init_app(app)


# === BLUEPRINTS ===
# Rutas a los diferentes módulos de la API

app.register_blueprint(auth)


if __name__ == "__main__":
    app.run(debug=True)