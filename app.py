"""Módulo que incializa la API de SolarO"""

import os

from flask import Flask
from flask_cors import CORS
from dotenv import load_dotenv

from extensions import db, bcrypt, jwt
from auth.routes import auth
import models

from datetime import timedelta
from werkzeug.middleware.proxy_fix import ProxyFix

load_dotenv()

app = Flask(__name__)

# === CONFIGURACION PARA ORM ===
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get("DATABASE_URL")
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

# === CONFIGURACION JWT ===
app.config["JWT_SECRET_KEY"] = os.environ.get("JWT_SECRET_KEY")
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(minutes=15)

# === CONFIGURACION MAIL ===
app.config["BREVO_API_URL"] = os.environ.get("BREVO_API_URL")
app.config["BREVO_API_KEY"] = os.environ.get("BREVO_API_KEY")
app.config["BREVO_SENDER_EMAIL"] = os.environ.get("BREVO_SENDER_EMAIL")
app.config["FRONTEND_URL"] = os.environ.get("FRONTEND_URL")

# === CONFIGURACION CORS ===
app.config["CORS_ORIGINS"] = os.environ["FRONTEND_URL"]

# === INCIALIZACION SERVICIOS ===
db.init_app(app)
bcrypt.init_app(app)
jwt.init_app(app)
CORS(app)

app.wsgi_app = ProxyFix(app.wsgi_app, x_for=3)


# === BLUEPRINTS ===
# Rutas a los diferentes módulos de la API

app.register_blueprint(auth)


if __name__ == "__main__":
    app.run(debug=True)