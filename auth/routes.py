"""Endpoints del módulo de autenticación"""

import hmac

from flask import Blueprint, jsonify, request, current_app
from flask_jwt_extended import create_access_token
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity
from sqlalchemy.exc import IntegrityError, OperationalError

from auth.service import *
from auth.exceptions import ContrasenaInsegura

from extensions import db
from models import Usuario

from datetime import timedelta

# Registrar blueprint 'auth'
auth = Blueprint("auth", __name__)


# === ENDPOINTS ===

@auth.route("/auth/register", methods=["POST"])
def register():
    
    data = request.get_json(silent=True)
    
    # --- Validación de datos ---

    # Request válida
    if not isinstance(data, dict):
        return jsonify({
            "message": "Se requiere un objeto JSON válido."
        }), 400

    # Datos requeridos
    campos_requeridos = {"nombre", "email", "contrasena"}

    if set(data.keys()) != campos_requeridos:
        return jsonify({
            "message": "Se requieren nombre, email y contrasena."
        }), 422

    # Datos en formato válido (str)
    if not all(isinstance(valor, str) for valor in data.values()):
        return jsonify({
            "message": "Todos los campos deben ser cadenas de texto."
        }), 422

    # Nombre vacío
    if not data["nombre"].strip():
        return jsonify({
            "message": "El nombre no puede estar vacío."
        }), 422

    # Nombre válido
    if data["nombre"].isnumeric():
        return jsonify({
            "message": "El nombre es inválido"
        }), 422

    if len(data["nombre"].strip()) < 3:
        return jsonify({
            "message": "El nombre debe tener al menos 3 caracteres."
        }), 422

    # Normalizar datos
    nombre = data["nombre"].strip()
    email = data["email"].strip().lower()
    contrasena = data["contrasena"]

    # Contraseña segura
    """
    Debe contener al menos:
    - 8 caracteres
    - 1 mayúscula
    - 1 minúscula
    - 1 número
    """

    try:
        validar_contrasena(contrasena)

    except ContrasenaInsegura as e:
        return jsonify({
            "message": str(e),
            "notes": e.show_notes()
        }), 422

    # Email en formato correcto
    if not validar_email(email):
        return jsonify({
            "message": "Email inválido"
        }), 422

    # --- Comprobar si el email ya existe ---

    try:
        usuario_existente = buscar_email_existente(email)
    
    except OperationalError:
        current_app.logger.exception("Error de conexión a la base de datos.")
        return jsonify({
            "message": "Error de conexión. Intente nuevamente."
        }), 500
    
    if usuario_existente:
        return jsonify({
            "message": "El correo electrónico ya está registrado.",
            "field": "email"
        }), 409
    
    # --- Hashear contraseña ---
    contrasena_hash = hashear_contrasena(contrasena)

    # --- Crear usuario ---

    try:
        crear_usuario(nombre, email, contrasena_hash)

    except IntegrityError:
        return jsonify({
            "message": "El correo electrónico ya se encuentra registrado." 
        }), 409

    except Exception:
        current_app.logger.exception("Error al crear el usuario")
        return jsonify({
            "message": "Error al crear el usuario. Intente nuevamente."
        }), 500

    else:
        return jsonify({
            "message": "Usuario creado correctamente."
        }), 201


@auth.route("/auth/login", methods=["POST"])
def login():
    
    data = request.get_json(silent=True)
    
    # --- Validación de datos ---

    # Request válida
    if not isinstance(data, dict):
        return jsonify({
            "message": "Se requiere un objeto JSON válido."
        }), 400

    # Datos requeridos
    campos_requeridos = {"email", "contrasena"}

    if set(data.keys()) != campos_requeridos:
        return jsonify({
            "message": "Se requieren email y contraseña."
        }), 422

    # Datos en formato válido (str)
    if not all(isinstance(valor, str) for valor in data.values()):
        return jsonify({
            "message": "Todos los campos deben ser cadenas de texto."
        }), 422

    # Datos vacíos
    if not data["email"].strip() or not data["contrasena"].strip():
        return jsonify({
            "message": "Los campos no pueden estar vacíos."
        }), 422

    # --- Buscar usuario ---
    email = data["email"].strip().lower()
    
    try:
        usuario = buscar_email_existente(email)
    
    except OperationalError:
        current_app.logger.exception("Error de conexión a la base de datos.")
        return jsonify({
            "message": "Error de conexión. Intente nuevamente."
        }), 500

    if not usuario:
        return jsonify({
            "message": "Datos incorrectos. Verifique nuevamente."
        }), 401

    # --- Verificar contraseña ---
    contrasena_correcta = verificar_contrasena(usuario, data["contrasena"])

    if not contrasena_correcta:
        return jsonify({
            "message": "Datos incorrectos. Verifique nuevamente."
        }), 401

    # --- Generar token ---
    access_token = create_access_token(identity=str(usuario.id_usuario))

    return jsonify({
        "message": "Inicio de sesión exitoso.",
        "access_token": access_token,
        "user": {
            "id_usuario": usuario.id_usuario,
            "nombre": usuario.nombre,
            "email": usuario.email
        }
    }), 200


@auth.route("/auth/forgot-password", methods=["POST"])
def forgot_password():

    data = request.get_json(silent=True)

    # --- Validación de datos ---

    # Request válida
    if not isinstance(data, dict):
        return jsonify({
            "message": "Se requiere un objeto JSON válido."
        }), 400

    # Datos requeridos
    campos_requeridos = {"email"}

    if set(data.keys()) != campos_requeridos:
        return jsonify({
            "message": "Se requiere un email"
        }), 422

    # Datos en formato válido (str)
    if not all(isinstance(valor, str) for valor in data.values()):
        return jsonify({
            "message": "El email debe ser una cadena de texto."
        }), 422

    # Email vacío
    if not data["email"].strip():
        return jsonify({
            "message": "El email no puede estar vacío."
        }), 422

    # --- Buscar usuario ---
    try:
        usuario = buscar_email_existente(data["email"].strip().lower())
    
    except OperationalError:
        current_app.logger.exception("Error de conexión a la base de datos.")
        return jsonify({
            
            "message": "Error de conexión. Intente nuevamente."
        }), 500

    # --- Generar token de recuperación ---
    if usuario:
        
        token = create_access_token(
            identity=str(usuario.id_usuario),
            additional_claims={"purpose": "password_reset"},
            expires_delta=timedelta(minutes=15),
        )

        try:
            enviar_correo_recuperacion(usuario.email, token)

        except Exception:
            current_app.logger.exception("No se pudo enviar el correo de recuperación.")
            return jsonify({
                "message": "Error al enviar el correo de recuperación. Intente nuevamente"
            }), 500

        else:
            return jsonify({
                "message": "Si el correo está registrado, recibirás instrucciones para recuperar tu contraseña."
                }), 200

    else:
        return jsonify({
                "message": "Si el correo está registrado, recibirás instrucciones para recuperar tu contraseña."
                }), 200


@auth.route("/auth/reset-password", methods=["POST"])
@jwt_required()
def reset_password():

    # --- Validar token ---

    claims = get_jwt()
    
    if claims.get("purpose") != "password_reset":
        return jsonify({
            "message": "No tiene permiso para realizar esta operación."
            }), 403

    # --- Buscar usuario ---
    identidad = get_jwt_identity()
    usuario = db.session.get(Usuario, int(identidad))

    if usuario is None:
        return jsonify({"message": "Usuario no encontrado."}), 404

    # --- Validar que el token no haya sido usado ---
    if not hmac.compare_digest(claims.get("pwd", ""), huella_contrasena(usuario)):
        return jsonify({"message": "El enlace ya fue utilizado o no es válido."}), 401

    # --- Validar datos ---
    data = request.get_json()

    # Request válida
    if not isinstance(data, dict):
        return jsonify({
            "message": "Se requiere un objeto JSON válido."
        }), 400

    # Datos requeridos
    if set(data.keys()) != {"contrasena"}:
        return jsonify({
            "message": "Se requiere una contraseña"
        }), 422

    # Datos en formato válido (str)
    if not all(isinstance(valor, str) for valor in data.values()):
        return jsonify({
            "message": "La contraseña debe ser una cadena de texto."
        }), 422

    # Campo vacío
    if not data["contrasena"].strip():
        return jsonify({
            "message": "La contraseña no puede estar vacía."
        }), 422

    # Realizar verficaciones de seguridad a la contraseña
    try:
        validar_contrasena(data["contrasena"])

    except ContrasenaInsegura as e:
        return jsonify({
            "message": str(e),
            "notes": e.show_notes()
        }), 422

    # --- Actualizar contraseña ---
    try:
        actualizar_contrasena(usuario, data["contrasena"])

    except Exception:
        current_app.logger.exception("Error al actualizar contraseña")
        return jsonify({
            "message": "Error al actualizar la contraseña. Intente nuevamente."
        }), 500

    else:

        try:
            enviar_correo_contrasena_cambiada(
                usuario.email,
                request.remote_addr or "desconocida",
                describir_dispositivo(request.headers.get("User-Agent", "")),
            )

        except Exception:
            current_app.logger.exception("No se pudo enviar el aviso de cambio de contraseña.")

        return jsonify({
            "message": "Contraseña actualizada correctamente. Ahora puede iniciar sesión."
        }), 200


@auth.route("/auth/me", methods=["GET"])
@jwt_required()
def obtener_perfil():

    # --- Validar que el token no sea de recuperación ---
    if get_jwt().get("purpose") == "password_reset":

        return jsonify({
            "message": "No tiene permiso para realizar esta operación."
            }), 403

    identidad = get_jwt_identity()
    usuario = db.session.get(Usuario, int(identidad))

    if usuario is None:
        return jsonify({
            "message": "Usuario no encontrado."
        }), 404

    return jsonify({
        "id_usuario": usuario.id_usuario,
        "nombre": usuario.nombre,
        "email": usuario.email
    }), 200 