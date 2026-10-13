"""Modelos de base de datos utilizando ORM"""

from extensions import db

from datetime import datetime
from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

class Usuario(db.Model):
    """Modelo de la tabla 'usuarios'

    Atributos:
        - nombre: str
        - correo: str
        - contrasena_hash: str
        - fecha_registro: str
    """

    __tablename__ = "usuarios" 

    id_usuario: Mapped[int] = mapped_column(
        primary_key=True
    )

    nombre: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    email: Mapped[str] = mapped_column(
        String(255),
        unique=True,
        nullable=False
    )

    contrasena_hash: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    fecha_registro = db.Column(
        db.DateTime, 
        default=datetime.utcnow,
        )