import logging
import os
import re
from datetime import datetime, timedelta, timezone
from flask import current_app

import requests
from sqlalchemy.exc import IntegrityError

from models import SolicitudPQRS, Usuario
from extensions import db

logger = logging.getLogger(__name__)

TIPOS = {
    "peticion": "petición",
    "queja": "queja",
    "reclamo": "reclamo",
    "sugerencia": "sugerencia",
}

MAX_RADICADO = 50
MAX_NOMBRE = 100
MAX_EMAIL = 254
MAX_ASUNTO = 30
MAX_DESCRIPCION = 1000

LIMITE_SOLICITUDES = 3       # solicitudes permitidas por usuario...
VENTANA = timedelta(hours=1)  # ...en esta ventana

TIMEOUT_SEGUNDOS = 10

# El radicado lo genera el frontend: se trata como dato no confiable.
# Ajustar el patrón al formato real de los radicados.
RADICADO_RE = re.compile(r"^[A-Za-z0-9_-]+$")
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class SolicitudInvalida(ValueError):
    """El cuerpo no cumple las reglas de validación."""


class RadicadoDuplicado(Exception):
    """El número de radicado ya existe."""


class LimiteExcedido(Exception):
    """El usuario superó el número de solicitudes permitidas en la ventana."""


class EnvioFallido(Exception):
    """El proveedor de correo no pudo entregar el correo."""


# ---------------------------------------------------------------- validación

def _texto(datos: dict, campo: str, maximo: int, una_linea: bool = False) -> str:
    """Valida un campo de texto: obligatorio, tipo, longitud y saltos de línea.

    Args:
        datos (dict): El cuerpo JSON de la solicitud.
        campo (str): El nombre del campo a validar.
        maximo (int): La longitud máxima del campo.
        una_linea (bool, optional): Si se debe validar que el campo no contenga saltos de línea. Defaults to False.

    Raises:
        SolicitudInvalida: Si el campo no cumple con las reglas de validación.

    Returns:
        str: El valor validado del campo.
    """

    valor = datos.get(campo)

    if not isinstance(valor, str):
        raise SolicitudInvalida(f"'{campo}' es obligatorio y debe ser texto")
    
    valor = valor.strip()

    if not valor:
        raise SolicitudInvalida(f"'{campo}' no puede estar vacío")
    
    if len(valor) > maximo:
        raise SolicitudInvalida(f"'{campo}' no puede superar {maximo} caracteres")
    
    if una_linea and ("\n" in valor or "\r" in valor):
        raise SolicitudInvalida(f"'{campo}' no puede contener saltos de línea")
    
    return valor


def _validar(datos: dict) -> dict:
    """Valida el cuerpo JSON de la solicitud PQRS.

    Args:
        datos (dict): El cuerpo JSON de la solicitud.

    Raises:
        SolicitudInvalida: Si el cuerpo no cumple con las reglas de validación.

    Returns:
        dict: Un diccionario con los campos validados.
    """
    if not isinstance(datos, dict):
        raise SolicitudInvalida("El cuerpo debe ser un objeto JSON")

    tipo = datos.get("tipo")
    tipo = tipo.strip().lower() if isinstance(tipo, str) else None

    if tipo not in TIPOS:
        raise SolicitudInvalida("'tipo' debe ser uno de: " + ", ".join(TIPOS))

    radicado = _texto(datos, "numero_radicado", MAX_RADICADO, una_linea=True)
    if not RADICADO_RE.match(radicado):
        raise SolicitudInvalida(
            "'numero_radicado' solo puede contener letras, números, guiones y guiones bajos"
        )

    nombre = _texto(datos, "nombre", MAX_NOMBRE, una_linea=True)

    email = _texto(datos, "email", MAX_EMAIL, una_linea=True)
    if not EMAIL_RE.match(email):
        raise SolicitudInvalida("'email' no tiene un formato válido")

    asunto = _texto(datos, "asunto", MAX_ASUNTO, una_linea=True)
    descripcion = _texto(datos, "descripcion", MAX_DESCRIPCION)

    calificacion = datos.get("calificacion")
    if calificacion is not None:
        # bool es subclase de int en Python: se rechaza de forma explícita.
        if isinstance(calificacion, bool) or not isinstance(calificacion, int) or not 1 <= calificacion <= 5:
            raise SolicitudInvalida("'calificacion' debe ser un entero entre 1 y 5")

    return {
        "tipo": tipo,
        "numero_radicado": radicado,
        "nombre": nombre,
        "email": email,
        "asunto": asunto,
        "descripcion": descripcion,
        "calificacion": calificacion,
    }


# -------------------------------------------------------------- límite de uso

def _verificar_limite(usuario_id: str):
    """Límite por usuario calculado sobre la base de datos: vale con varios workers.
    
    Args:
        usuario_id (str): El ID del usuario.
    """
    desde = datetime.now(timezone.utc) - VENTANA
    cantidad = SolicitudPQRS.query.filter(
        SolicitudPQRS.usuario_id == usuario_id,
        SolicitudPQRS.fecha >= desde,
    ).count()

    if cantidad >= LIMITE_SOLICITUDES:
        raise LimiteExcedido("Has enviado demasiadas solicitudes. Intenta de nuevo más tarde")


# --------------------------------------------------------------------- correo

def enviar_correo(destinatario: str, asunto: str, cuerpo: str, reply_to=None):
    """Envía un correo usando Brevo.

    Args:
        destinatario (str): El correo del destinatario.
        asunto (str): El asunto del correo.
        cuerpo (str): El cuerpo del correo.
        reply_to (str, optional): El correo para respuestas. Defaults to None.

    Raises:
        EnvioFallido: Si el envío del correo falla.
    """
    api_key = current_app.config.get("BREVO_API_KEY")
    remitente = current_app.config.get("BREVO_SENDER_EMAIL")

    if not (api_key and remitente):
        logger.error("Faltan variables de entorno de Brevo")
        raise EnvioFallido()

    payload = {
        "sender": {"name": "SolarO", "email": remitente},
        "to": [destinatario],
        "subject": asunto,
        "textContent": cuerpo,  # texto plano: sin riesgo de inyección de HTML
    }
    if reply_to:
        payload["replyTo"] = reply_to

    try:
        respuesta = requests.post(
            current_app.config.get("BREVO_API_URL"),
            json=payload,
            headers={"api-key": api_key, "accept": "application/json"},
            timeout=TIMEOUT_SEGUNDOS,
        )
        respuesta.raise_for_status()

    except requests.RequestException as e:
        # Nunca se registra el contenido ni los datos personales.
        estado = getattr(e.response, "status_code", None)
        logger.error("Fallo al enviar correo por Brevo (%s, estado=%s)", type(e).__name__, estado)
        raise EnvioFallido() from e


def cuerpo_notificacion(d: dict) -> str:
    calificacion = d["calificacion"] if d["calificacion"] is not None else "No indicada"
    return "\n".join([
        "Nueva PQRS recibida",
        "",
        f"Radicado: {d['numero_radicado']}",
        f"Tipo: {TIPOS[d['tipo']]}",
        f"Nombre: {d['nombre']}",
        f"Email: {d['email']}",
        f"Asunto: {d['asunto']}",
        f"Calificación: {calificacion}",
        "",
        "Descripción:",
        d["descripcion"],
    ])


def _cuerpo_confirmacion(d: dict) -> str:
    return "\n".join([
        f"Hola {d['nombre']},",
        "",
        f"Hemos recibido tu {TIPOS[d['tipo']]} y quedó radicada con el número {d['numero_radicado']}.",
        "",
        f"Asunto: {d['asunto']}",
        "",
        "Te daremos respuesta de forma personal a este mismo correo electrónico.",
        "Conserva tu número de radicado para cualquier consulta.",
        "",
        "Equipo SolarO",
    ])


# ----------------------------------------------------------------- operación

def radicar_pqrs(usuario: Usuario, datos: dict) -> dict:
    """Registra una PQRS y envía los dos correos.

    Orden: validar -> límite -> insertar (flush) -> correo al desarrollador ->
    commit -> correo de confirmación. Así, toda PQRS guardada ya fue notificada
    al desarrollador; solo la confirmación al usuario es de mejor esfuerzo.

    Args:
        usuario (Usuario): El usuario que envía la PQRS.
        datos (dict): El cuerpo JSON de la solicitud.

    Raises:
        SolicitudInvalida: Si el cuerpo no cumple con las reglas de validación.
        RadicadoDuplicado: Si el número de radicado ya existe.
        LimiteExcedido: Si el usuario superó el límite de solicitudes.
        EnvioFallido: Si el proveedor de correo no pudo entregar el correo.
    """
    d = _validar(datos)
    _verificar_limite(usuario.id_usuario)

    db.session.add(
        SolicitudPQRS(
            numero_radicado=d["numero_radicado"],
            usuario_id=usuario.id_usuario,
            tipo=d["tipo"],
            asunto=d["asunto"],
            descripcion=d["descripcion"],
        )
    )
    try:
        db.session.flush()
        
    except IntegrityError:
        db.session.rollback()
        raise RadicadoDuplicado("El número de radicado ya existe")

    destino = current_app.config.get("PQRS_DESTINO_EMAIL")

    if not destino:
        db.session.rollback()
        logger.error("Falta la variable de entorno PQRS_DESTINO_EMAIL")
        raise EnvioFallido()

    try:
        enviar_correo(
            {"email": destino},
            f"Nueva PQRS ({TIPOS[d['tipo']]}) - {d['numero_radicado']}",
            cuerpo_notificacion(d),
            reply_to={"email": d["email"], "name": d["nombre"]},
        )
        
    except EnvioFallido:
        db.session.rollback() 
        raise

    db.session.commit()

    try:
        enviar_correo(
            {"email": d["email"], "name": d["nombre"]},
            f"Confirmación de radicación - {d['numero_radicado']}",
            _cuerpo_confirmacion(d),
        )
        confirmacion = True

    except EnvioFallido:
        logger.warning("Confirmación no enviada para el radicado %s", d["numero_radicado"])
        confirmacion = False

    return {"radicado": d["numero_radicado"], "confirmacion_enviada": confirmacion}


def _fecha_iso(fecha):
    """Fecha y hora en ISO 8601 y UTC (se asume UTC si el valor llega sin zona)."""
    if fecha.tzinfo is None:
        fecha = fecha.replace(tzinfo=timezone.utc)

    return fecha.astimezone(timezone.utc).isoformat()


def listar_pqrs(usuario_id: str) -> dict:
    """Devuelve las PQRS de un usuario, ordenadas por fecha descendente.

    Args:
        usuario_id (str): El ID del usuario.

    Returns:
        dict: Un diccionario con la lista de PQRS.
    """
    filas = (
        SolicitudPQRS.query.filter_by(usuario_id=usuario_id)
        .order_by(SolicitudPQRS.fecha.desc(), SolicitudPQRS.id.desc())
        .all()
    )

    return {
        "pqrs": [
            {
                "numero_radicado": f.numero_radicado,
                "tipo": f.tipo,
                "asunto": f.asunto,
                "fecha": _fecha_iso(f.fecha),
            }
            for f in filas
        ]
    }