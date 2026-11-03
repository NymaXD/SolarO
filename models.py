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
    
    nombre: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    
    potencia_watts: Mapped[int] = mapped_column(Integer, nullable=False)


class ProgresoLeccion(db.Model):
    """Modelo de la tabla 'progreso_lecciones'
    
    Atributos:
        - id (PK): int
        - usuario_id (FK a usuarios): int
        - nivel: int
        - leccion: int
        - completado: bool
    """
    __tablename__ = "progreso_lecciones"
 
    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(
        db.Integer,
        db.ForeignKey("usuarios.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    nivel = db.Column(db.Integer, nullable=False)

    leccion = db.Column(db.Integer, nullable=False)
    
    completado = db.Column(db.Boolean, nullable=False, default=True)
 
    __table_args__ = (
        db.UniqueConstraint("usuario_id", "nivel", "leccion", name="uq_progreso_usuario_nivel_leccion"),
        db.CheckConstraint("nivel BETWEEN 1 AND 3", name="ck_progreso_nivel"),
        db.CheckConstraint("leccion >= 1", name="ck_progreso_leccion"),
    )


class SolicitudPQRS(db.Model):
    """Modelo de la tabla 'pqrs'

    Atributos:
        - id (PK): int
        - numero_radicado: str
        - usuario_id (FK a usuarios): int
        - tipo: str
        - asunto: str (max 30 caracteres)
        - descripcion: str (max 1000 caracteres)
        - fecha: datetime
    """
    __tablename__ = "pqrs"
 
    id = db.Column(db.Integer, primary_key=True)
    numero_radicado = db.Column(db.String(50), unique=True, nullable=False)
    usuario_id = db.Column(
        db.Integer,
        db.ForeignKey("usuarios.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    tipo = db.Column(db.String(10), nullable=False)
    asunto = db.Column(db.String(30), nullable=False)
    descripcion = db.Column(db.String(1000), nullable=False)
    fecha = db.Column(
        db.DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
 
    __table_args__ = (
        db.CheckConstraint(
            "tipo IN ('peticion', 'queja', 'reclamo', 'sugerencia')",
            name="ck_pqrs_tipo",
        ),
    )

