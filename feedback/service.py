import logging
import os
import threading
import time
from collections import defaultdict, deque
from flask import current_app

import requests

logger = logging.getLogger(__name__)

MAX_CARACTERES = 1000
LIMITE_ENVIOS = 3            # comentarios permitidos por usuario...
VENTANA_SEGUNDOS = 3600      # ...en esta ventana (1 hora)
TIMEOUT_SEGUNDOS = 10
ASUNTO = "Nuevo comentario de un usuario de SolarO"  # fijo: nunca incluye texto del usuario


class ComentarioInvalido(ValueError):
    """El cuerpo no cumple las reglas de validación."""


class LimiteExcedido(Exception):
    """El usuario superó el número de comentarios permitidos en la ventana."""


class EnvioFallido(Exception):
    """El proveedor de correo no pudo entregar el comentario."""


# Límite por usuario en memoria: es por proceso y se reinicia con cada despliegue.
# Con varios workers el límite efectivo se multiplica; para escalar, usar Flask-Limiter con Redis.
_envios = defaultdict(deque)
_lock = threading.Lock()


def _validar(datos):
    if not isinstance(datos, dict):
        raise ComentarioInvalido("El cuerpo debe ser un objeto JSON")

    mensaje = datos.get("mensaje")
    if not isinstance(mensaje, str):
        raise ComentarioInvalido("'mensaje' es obligatorio y debe ser texto")
    mensaje = mensaje.strip()
    if not mensaje:
        raise ComentarioInvalido("'mensaje' no puede estar vacío")
    if len(mensaje) > MAX_CARACTERES:
        raise ComentarioInvalido(f"'mensaje' no puede superar {MAX_CARACTERES} caracteres")

    compartir = datos.get("compartir_datos", False)
    # Booleano estricto: la cadena "false" sería verdadera en Python.
    if not isinstance(compartir, bool):
        raise ComentarioInvalido("'compartir_datos' debe ser un booleano")

    return mensaje, compartir


def _reservar_cupo(usuario_id):
    ahora = time.monotonic()
    with _lock:
        cola = _envios[usuario_id]
        while cola and ahora - cola[0] > VENTANA_SEGUNDOS:
            cola.popleft()
        if len(cola) >= LIMITE_ENVIOS:
            raise LimiteExcedido("Has enviado demasiados comentarios. Intenta de nuevo más tarde")
        cola.append(ahora)
    return ahora


def _liberar_cupo(usuario_id, marca):
    with _lock:
        try:
            _envios[usuario_id].remove(marca)
        except ValueError:
            pass


def _construir_cuerpo(mensaje, nombre, email):
    if email:
        datos = f"Nombre: {nombre}\nEmail: {email}"
    else:
        datos = "Usuario anónimo (no compartió sus datos)"
    return f"{datos}\n\n---\n{mensaje}"


def _enviar_a_brevo(cuerpo, reply_to):
    # Si ya tienes un helper de Brevo para la recuperación de contraseña,
    # reemplaza esta función por una llamada a él.
    api_key = os.getenv("BREVO_API_KEY")
    remitente = os.getenv("BREVO_SENDER_EMAIL")
    destino = os.getenv("FEEDBACK_DESTINO")
    if not (api_key and remitente and destino):
        logger.error("Faltan variables de entorno para el envío de comentarios")
        raise EnvioFallido()

    payload = {
        "sender": {"name": "SolarO", "email": remitente},
        "to": [{"email": destino}],
        "subject": ASUNTO,
        "textContent": cuerpo,  # texto plano: sin riesgo de inyección de HTML
    }
    if reply_to:
        payload["replyTo"] = reply_to

    try:
        respuesta = requests.post(
            current_app.config["BREVO_API_URL"],
            json=payload,
            headers={"api-key": api_key, "accept": "application/json"},
            timeout=TIMEOUT_SEGUNDOS,
        )
        respuesta.raise_for_status()

    except requests.RequestException as e:
        # Nunca se registra el contenido del mensaje ni los datos del usuario.
        estado = getattr(e.response, "status_code", None)
        logger.error("Fallo al enviar comentario por Brevo (%s, estado=%s)", type(e).__name__, estado)
        raise EnvioFallido() from e


def enviar_comentario(usuario, datos):
    
    mensaje, compartir = _validar(datos)
    marca = _reservar_cupo(usuario.id)  # tras validar, para que un 422 no consuma cupo

    if compartir:
        nombre, email = usuario.nombre, usuario.email
        reply_to = {"email": email, "name": nombre}

    else:
        nombre = email = reply_to = None

    try:
        _enviar_a_brevo(_construir_cuerpo(mensaje, nombre, email), reply_to)

    except EnvioFallido:
        _liberar_cupo(usuario.id, marca)  # un fallo del proveedor no penaliza al usuario
        raise