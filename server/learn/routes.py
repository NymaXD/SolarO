from flask import Blueprint, jsonify, request

from users.decorators import sesion_requerida
from . import service
from models import Usuario

learn = Blueprint("learn", __name__, url_prefix="/learn")


@learn.post("/progress")
@sesion_requerida
def marcar_progreso(usuario: Usuario):
    datos = request.get_json(silent=True)

    try:
        resultado, creado = service.marcar_completada(usuario.id_usuario, datos)

    except service.LeccionInvalida as e:
        return jsonify({"error": str(e)}), 422
    
    return jsonify(resultado), 201 if creado else 200


@learn.delete("/progress/<int:nivel>/<int:leccion>")
@sesion_requerida
def desmarcar_progreso(usuario: Usuario, nivel: int, leccion: int):
    try:
        resultado = service.desmarcar_completada(usuario.id_usuario, nivel, leccion)

    except service.LeccionInvalida as e:
        return jsonify({"error": str(e)}), 422
    
    return jsonify(resultado), 200


@learn.get("/progress")
@sesion_requerida
def obtener_progreso(usuario: Usuario):
    return jsonify(service.obtener_progreso(usuario.id_usuario)), 200
