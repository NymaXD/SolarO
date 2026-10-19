"""Decoradores para manejo de sesion."""

from functools import wraps
from flask import jsonify
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity
from extensions import db
from models import Usuario


def sesion_requerida(fn):

    @wraps(fn)
    @jwt_required()
    def wrapper(fn, *args, **kwargs):
        
        # --- Validar que el token sea de sesión ---
        if get_jwt().get("purpose") != "session":
            return jsonify({
                "message": "No tiene permiso para realizar esta operación."
                }), 403
        
        # --- Obtener usuario ---
        usuario = db.session.get(Usuario, int(get_jwt_identity()))

        if usuario is None:
            return jsonify({
                "message": "Usuario no encontrado."
                }), 401

        return fn(usuario, *args, **kwargs)

    return wrapper