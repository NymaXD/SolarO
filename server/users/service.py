"""Lógica y validación de datos para gestión de usuarios"""

from models import Usuario
from extensions import db

def actualizar_datos_usuario(usuario: Usuario, nombre: str, email: str):
    """Actualiza los datos principales (nombre y email) de un usuario"""

    try:
        usuario.nombre = nombre
        usuario.email = email
        db.session.commit()

    except:
        db.session.rollback()
        raise
