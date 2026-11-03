from flask import Blueprint, jsonify, request

from auth import sesion_requerida
from service import marcar_completada, obtener_progreso, LeccionInvalida


learn = Blueprint("learn", __name__, url_prefix="/learn")


@learn.route("/progress", methods=["POST"])
@sesion_requerida
def marcar_progreso(usuario):
    datos = request.get_json(silent=True)

    try:
        resultado, creado = marcar_completada(usuario.id, datos)

    except LeccionInvalida as e:
        return jsonify({"message": str(e)}), 422
    
    return jsonify(resultado), 201 if creado else 200


@learn.route("/progress", methods=["GET"])
@sesion_requerida
def obtener_progreso(usuario):
    return jsonify(obtener_progreso(usuario.id)), 200
