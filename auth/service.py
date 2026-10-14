"""Lógica de validaciones del módulo de autenticación"""

import re, os, requests
from typing import Literal
from flask import jsonify, current_app
#from flask_mail import Message

from auth.exceptions import ContrasenaInsegura
from models import Usuario
from extensions import db, bcrypt


def validar_contrasena(contrasena: str):
    """Realiza verificaciones de seguridad a la contraseña ingresada

        Excepciones:
         - ContrasenaInsegura: Indica que la contraseña no cumple con los requerimientos de seguridad.
    """

    cont_numeros = 0
    cont_mayus = 0
    cont_minus = 0

    for i in contrasena:

        if i.isdigit():
            cont_numeros += 1
        elif i.isupper():
            cont_mayus += 1
        elif i.islower():
            cont_minus += 1

    error = ContrasenaInsegura()

    if cont_numeros == 0:
        error.add_note("La contraseña debe tener al menos un número.")
    if cont_mayus == 0:
        error.add_note("La contraseña debe tener al menos una mayúscula.")
    if cont_minus == 0:
        error.add_note("La contraseña debe tener al menos una minúscula.")
    if len(contrasena) < 8:
        error.add_note("La contraseña debe tener al menos 8 caracteres.")

    if error.is_valid_to_raise():
        raise error


def validar_email(email: str) -> bool:
    """Valida que el email ingresado tenga un formato válido."""

    patron = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    
    if re.match(patron, email):
        return True

    return False


def buscar_email_existente(email: str) -> Usuario | None:
    """Busca en la base de datos si el email ingresado ya existe."""
    user = db.session.execute(
        db.select(Usuario).where(Usuario.email == email)
    ).scalar_one_or_none()

    return user


def hashear_contrasena(contrasena: str) -> str:
    """Hashea la contraseña utilizando Bcrypt"""
    return bcrypt.generate_password_hash(contrasena).decode('utf-8')


def verificar_contrasena(usuario: Usuario, contrasena: str) -> bool:
    """Verifica si la contraseña ingresada coincide con el hash almacenado en la BBDD"""
    return bcrypt.check_password_hash(usuario.contrasena_hash, contrasena)


def crear_usuario(nombre: str, email: str, contrasena_hash: str):
    """Inserta un usuario en la base de datos"""
    user = Usuario(
        nombre=nombre,
        email=email,
        contrasena_hash= contrasena_hash
    )

    try:
        db.session.add(user)
        db.session.commit()
    
    except:
        db.session.rollback()
        raise


def actualizar_contrasena(usuario: Usuario, nueva_contrasena: str):
    """Actualiza la contraseña de un usuario"""
    try:
        usuario.contrasena_hash = hashear_contrasena(nueva_contrasena)
        db.session.commit()
    except:
        db.session.rollback()
        raise


def enviar_correo_smtp(email: str, token: str) -> None:
    """Función archivada. Usa SMTP. Puerto bloqueado por el PaaS utilizado.
    
    Envía un email de recuperación de contraseña al email introducido."""

    enlace = (
        f"{current_app.config['FRONTEND_URL']}"
        f"/reset-password?t={token}"
    )

    mensaje = Message(
        subject="Recuperación de contraseña - SolarO",
        recipients=[email],
        body=(
            "Hola,\n\n"
            "Recibimos una solicitud para restablecer la contraseña de tu cuenta de SolarO.\n\n"
            f"Abre el siguiente enlace para continuar:\n{enlace}\n\n"
            "Este enlace vence en 15 minutos. "
            "Si no solicitaste este cambio, ignora este mensaje."
        )
    )

    mail.send(mensaje)


def enviar_correo_recuperacion(destinatario: str, token: str):
    """Envía un email de recuperación de contraseña al email introducido."""

    enlace = (
        f"{current_app.config['FRONTEND_URL']}"
        f"/reset-password?t={token}"
    )

    respuesta = requests.post(
        current_app.config["BREVO_API_URL"],
        headers={
            "api-key": os.environ["BREVO_API_KEY"],
            "Content-Type": "application/json",
        },
        json={
            "sender": {"name": "SolarO", "email": os.environ["BREVO_SENDER_EMAIL"]},
            "to": [{"email": destinatario}],
            "subject": "Recupera tu contraseña de SolarO",
            "htmlContent": f'<p>Usa este enlace para restablecer tu contraseña:</p><p><a href="{enlace}">{enlace}</a></p>',
        },
        timeout=10,
    )
    respuesta.raise_for_status()