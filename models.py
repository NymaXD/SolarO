"""Modelos de base de datos utilizando ORM"""

from extensions import db

from datetime import datetime, timezone
from sqlalchemy import String, Integer, Float, ForeignKey, DateTime
from sqlalchemy.orm import Mapped, mapped_column


class Usuario(db.Model):
    """Modelo de la tabla 'usuarios'

    Atributos:
        - id_usuario (PK): int
        - nombre: str
        - email: str
        - contrasena_hash: str
        - fecha_registro: str
    """

    __tablename__ = "usuarios" 

    id_usuario: Mapped[int] = mapped_column(primary_key=True)

    nombre: Mapped[str] = mapped_column(String(100), nullable=False)

    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)

    contrasena_hash: Mapped[str] = mapped_column(String(255), nullable=False)

    fecha_registro: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))


class Electrodomestico(db.Model):
    """Modelo de la tabla 'electrodomesticos'
    
    Atributos:
        - id_electrodomestico (PK): int
        - id_usuario (FK a usuarios): int
        - nombre: str
        - tipo: str
        - potencia_w: int
        - horas_dia: float
        - dias_semana: int
        - cantidad: int
    """

    __tablename__ = "electrodomesticos"

    id_electrodomestico: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    
    id_usuario: Mapped[int] = mapped_column(Integer, ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    
    nombre: Mapped[str] = mapped_column(String(255), nullable=False)
    
    tipo: Mapped[str] = mapped_column(String(100), nullable=False)
    
    potencia_w: Mapped[int] = mapped_column(Integer, nullable=False)
    
    horas_dia: Mapped[float] = mapped_column(Float, nullable=False)
    
    dias_semana: Mapped[int] = mapped_column(Integer, nullable=False)
    
    cantidad: Mapped[int] = mapped_column(Integer, nullable=False, default=1)


class InfoElectrodomestico(db.Model):
    """Modelo de la tabla 'info_electrodomesticos'
    
    Atributos:
        - id (PK): int
        - nombre: str
        - potencia_watts: int
    """
    __tablename__ = "info_electrodomesticos"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    
    nombre: Mapped[str] = mapped_column(String(255), nullable=False)
    
    potencia_watts: Mapped[int] = mapped_column(Integer, nullable=False)
