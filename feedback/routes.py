from flask import Blueprint, jsonify, request

from auth import sesion_requerida
from service import enviar_comentario, ComentarioInvalido, LimiteExcedido, EnvioFallido

feedback = Blueprint("feedback", __name__, url_prefix="/feedback")


@feedback.route("", methods=["POST"])
@sesion_requerida
def enviar_comentario(usuario):

    datos = request.get_json(silent=True)

    try:
        enviar_comentario(usuario, datos)

    except ComentarioInvalido as e:
        return jsonify({"message": str(e)}), 422
    
    except LimiteExcedido as e:
        return jsonify({"message": str(e)}), 429
    
    except EnvioFallido:
        return jsonify({"message": "No se pudo enviar el comentario. Intenta de nuevo más tarde"}), 502
    
    return jsonify({"enviado": True}), 200
