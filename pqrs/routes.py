from flask import Blueprint, jsonify, request


from users.decorators import sesion_requerida
from . import service

pqrs = Blueprint("pqrs", __name__, url_prefix="/pqrs")


@pqrs.post("")
@sesion_requerida
def radicar(usuario):
    datos = request.get_json(silent=True)
    try:
        resultado = service.radicar_pqrs(usuario, datos)

    except service.SolicitudInvalida as e:
        return jsonify({"message": str(e)}), 422
    
    except service.RadicadoDuplicado as e:
        return jsonify({"message": str(e)}), 409
    
    except service.LimiteExcedido as e:
        return jsonify({"message": str(e)}), 429
    
    except service.EnvioFallido:
        return jsonify({"message": "No se pudo radicar la solicitud. Intenta de nuevo más tarde"}), 502
    
    return jsonify(resultado), 201


@pqrs.get("")
@sesion_requerida
def listar(usuario):
    return jsonify(service.listar_pqrs(usuario.id)), 200

