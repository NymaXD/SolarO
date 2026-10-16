"""Endpoints Gestión de usuarios"""

from flask import Blueprint, jsonify, request, current_app
from sqlalchemy.exc import IntegrityError, OperationalError
from flask_jwt_extended import create_refresh_token

from auth.exceptions import ContrasenaInsegura
from auth.service import actualizar_contrasena, validar_contrasena, validar_email, buscar_email_existente, verificar_contrasena, enviar_correo_contrasena_cambiada, describir_dispositivo, huella_contrasena

from users.service import actualizar_datos_usuario
from users.decorators import sesion_requerida

# Registrar blueprint 'users'
users = Blueprint("users", __name__, url_prefix="/users")

# === ENDPOINTS ===

@users.route("/me", methods=["GET"])
@sesion_requerida
def obtener_perfil(usuario):

    return jsonify({
        "id_usuario": usuario.id_usuario,
        "nombre": usuario.nombre,
        "email": usuario.email
    }), 200 


@users.route("/me", methods=["PUT"])
@sesion_requerida
def actualizar_usuario(usuario):
    
    data = request.get_json(silent=True)
    
    # --- Validación de datos ---

    # Request válida
    if not isinstance(data, dict):
        return jsonify({
            "message": "Se requiere un objeto JSON válido."
        }), 400

    # Datos requeridos
    campos_requeridos = {"nombre", "email"}

    if set(data.keys()) != campos_requeridos:
        return jsonify({
            "message": "Se requieren nombre y email."
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

    # Email en formato correcto
    if not validar_email(email):
        return jsonify({
            "message": "Email inválido"
        }), 422

    # --- Comprobar si el email ya existe ---

    try:
        email_existente = buscar_email_existente(email)
    
    except OperationalError:
        current_app.logger.exception("Error de conexión a la base de datos.")
        return jsonify({
            "message": "Error de conexión. Intente nuevamente."
        }), 500
    
    if email_existente and email_existente.id_usuario != usuario.id_usuario:
        return jsonify({
            "message": "El correo electrónico ya está registrado.",
            "field": "email"
        }), 409

    # --- Actualizar datos del usuario ---

    try:
        actualizar_datos_usuario(usuario, nombre, email)

    except IntegrityError:
        return jsonify({
            "message": "El correo electrónico ya se encuentra registrado." 
        }), 409

    except Exception:
        current_app.logger.exception("Error al modificar datos de usuario.")
        return jsonify({
            "message": "Error al modificar datos de usuario. Intente nuevamente."
        }), 500

    else:
        return "", 204


@users.route("/me/password", methods=["PUT"])
@sesion_requerida
def actualizar_contrasena_usuario(usuario):

    data = request.get_json(silent=True)
    
    # --- Validación de datos ---

    # Request válida
    if not isinstance(data, dict):
        return jsonify({
            "message": "Se requiere un objeto JSON válido."
        }), 400

    # Datos requeridos
    campos_requeridos = {"contrasena_antigua", "contrasena_nueva"}

    if set(data.keys()) != campos_requeridos:
        return jsonify({
            "message": "Se requieren contraseña antigua y contraseña nueva."
        }), 422

    # Datos en formato válido (str)
    if not all(isinstance(valor, str) for valor in data.values()):
        return jsonify({
            "message": "Todos los campos deben ser cadenas de texto."
        }), 422
    
    # Contraseñas vacías
    if not all(c.strip() for c in data.values()):
        return jsonify({
            "message": "Los campos no pueden estar vacíos."
        }), 422


    contrasena_antigua = data["contrasena_antigua"]
    contrasena_nueva = data["contrasena_nueva"]

    # --- Contraseña segura ---
    try:
        validar_contrasena(contrasena_nueva)

    except ContrasenaInsegura as e:
        return jsonify({
            "message": str(e),
            "notes": e.show_notes()
        }), 422

    # --- Comprobar contraseña antigua ---
    contrasena_correcta = verificar_contrasena(usuario, contrasena_antigua)

    if not contrasena_correcta:
        return jsonify({
            "message": "Datos incorrectos. Verifique nuevamente.",
            "field": "contrasena_antigua"
        }), 422

    # --- Actualizar contraseña ---
    try:
        actualizar_contrasena(usuario, contrasena_nueva)

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

        refresh_token = create_refresh_token(
            identity=str(usuario.id_usuario),
            additional_claims={"pwd": huella_contrasena(usuario)},
        )
        
        return jsonify({
            "message": "Contraseña actualizada correctamente.",
            "refresh_token": refresh_token,
        }), 200
