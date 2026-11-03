from flask import Blueprint, jsonify, request

# Ajustar la ruta de importación a la de tu proyecto.
from auth import sesion_requerida
from . import service

learn = Blueprint("learn", __name__, url_prefix="/learn")


@learn.post("/progress")
@sesion_requerida
def marcar_progreso(usuario):
    datos = request.get_json(silent=True)
    try:
        resultado, creado = service.marcar_completada(usuario.id, datos)
    except service.LeccionInvalida as e:
        return jsonify({"error": str(e)}), 422
    return jsonify(resultado), 201 if creado else 200


@learn.delete("/progress/<int:nivel>/<int:leccion>")
@sesion_requerida
def desmarcar_progreso(usuario, nivel, leccion):
    try:
        resultado = service.desmarcar_completada(usuario.id, nivel, leccion)
    except service.LeccionInvalida as e:
        return jsonify({"error": str(e)}), 422
    return jsonify(resultado), 200


@learn.get("/progress")
@sesion_requerida
def obtener_progreso(usuario):
    return jsonify(service.obtener_progreso(usuario.id)), 200
