"""Endpoints Gestión de electrodomésticos"""

from flask import Blueprint, jsonify, request, current_app
from sqlalchemy.exc import OperationalError

from models import Electrodomestico, InfoElectrodomestico
from extensions import db
from appliances.service import *
from users.decorators import sesion_requerida

# Registrar blueprint 'appliances'
appliances = Blueprint("appliances", __name__)

# === ENDPOINTS ===

@appliances.route("/appliances", methods=["GET"])
@sesion_requerida
def obtener_electrodomesticos(usuario):
    
    resultados = db.session.execute(
        db.select(Electrodomestico).where(Electrodomestico.id_usuario == usuario.id_usuario)
    ).scalars().all()

    respuesta = []

    for el in resultados:
        respuesta.append(serializar_electrodomestico(
            el.nombre, el.tipo, el.horas_dia, el.dias_semana, el.cantidad
        ))
        
    return jsonify(respuesta), 200


@appliances.route("/appliances", methods=["POST"])
@sesion_requerida
def nuevo_electrodomestico(usuario):
    
    data = request.get_json(silent=True)

    # JSON válido
    if not isinstance(data, dict):
        return jsonify({"message": "Se requiere un objeto JSON válido."}), 400

    # Campos requeridos
    campos_requeridos = {"nombre", "tipo", "horas_dia", "dias_semana", "cantidad"}

    if set(data.keys()) != campos_requeridos:
        return jsonify({"message": "Se requieren todos los campos."}), 422

    # Datos en formato correcto
    campos_string = (data["nombre"], data["tipo"])
    campos_int = (data["dias_semana"], data["cantidad"])

    if not all(isinstance(campo, str) for campo in campos_string):
        return jsonify({"message": "Datos inválidos. Revise nuevamente."}), 422

    if not all(isinstance(campo, int) for campo in campos_int):
        return jsonify({"message": "Datos inválidos. Revise nuevamente."}), 422

    if not isinstance(data["horas_dia"], (int, float)):
        return jsonify({"message": "Datos inválidos. Revise nuevamente."}), 422

    # Datos vacíos
    if not all(campo.strip() for campo in campos_string):
        return jsonify({"message": "Los datos no pueden estar vacíos."}), 422

    # Datos válidos
    nombre = data["nombre"].strip()
    tipo = data["tipo"]
    horas_dia = float(data["horas_dia"])
    dias_semana = int(data["dias_semana"])
    cantidad = int(data["cantidad"])

    if (not 0 < horas_dia <= 24) or (not 1 <= dias_semana <= 7) or cantidad < 1:
        return jsonify({"message": "Datos inválidos. Revise nuevamente."}), 422

    # Crear electrodoméstico
    try:
        electro = anadir_electrodomestico(usuario.id_usuario, nombre, tipo, horas_dia, dias_semana, cantidad)
    
    except OperationalError:
        current_app.logger.exception(f"Error al conectar con la base de datos.")
        return jsonify({"message": "Error de conexión"}), 500

    except Exception:
        current_app.logger.exception(f"Error al crear el electrodoméstico")
        return jsonify({"message": "Error al crear el electrodoméstico. Intente nuevamente"}), 500

    else:
        return jsonify({
            "message": "Electrodoméstico añadido correctamente",
            "item": electro
        }), 201


@appliances.route("/appliances/<int:id_>", methods=["PUT"])
@sesion_requerida
def editar_electrodomestico(id_, usuario):
    
    data = request.get_json(silent=True)

    # JSON válido
    if not isinstance(data, dict):
        return jsonify({"message": "Se requiere un objeto JSON válido."}), 400

    # Campos requeridos
    campos_requeridos = {"nombre", "tipo", "horas_dia", "dias_semana", "cantidad"}

    if set(data.keys()) != campos_requeridos:
        return jsonify({"message": "Se requieren todos los campos."}), 422

    # Datos en formato correcto
    campos_string = (data["nombre"], data["tipo"])
    campos_int = (data["dias_semana"], data["cantidad"])

    if not all(isinstance(campo, str) for campo in campos_string):
        return jsonify({"message": "Datos inválidos. Revise nuevamente."}), 422

    if not all(isinstance(campo, int) for campo in campos_int):
        return jsonify({"message": "Datos inválidos. Revise nuevamente."}), 422

    if not isinstance(data["horas_dia"], (int, float)):
        return jsonify({"message": "Datos inválidos. Revise nuevamente."}), 422

    # Datos vacíos
    if not all(campo.strip() for campo in campos_string):
        return jsonify({"message": "Los datos no pueden estar vacíos."}), 422

    # Datos válidos
    nombre = data["nombre"].strip()
    tipo = data["tipo"]
    horas_dia = float(data["horas_dia"])
    dias_semana = int(data["dias_semana"])
    cantidad = int(data["cantidad"])

    if (not 0 < horas_dia <= 24) or (not 1 <= dias_semana <= 7) or cantidad < 1:
        return jsonify({"message": "Datos inválidos. Revise nuevamente."}), 422

    # Obtener electrodoméstico a modificar
    electrodomestico = db.session.get(Electrodomestico, id_)
    
    if not electrodomestico or electrodomestico.id_usuario != usuario.id_usuario:
        return jsonify({"message": "Electrodoméstico no encontrado"}), 404

    # Modificar datos de electrodoméstico
    try:
        actualizar_datos_electrodomestico(
            electrodomestico=electrodomestico,
            nombre=nombre,
            tipo=tipo,
            horas_dia=float(horas_dia),
            dias_semana=int(dias_semana),
            cantidad=int(cantidad)
        )
    
    except OperationalError:
        current_app.logger.exception(f"Error al conectar con la base de datos.")
        return jsonify({"message": "Error de conexión"}), 500
        
    except Exception:
        current_app.logger.exception(f"Error al actualizar el electrodoméstico {electrodomestico.id_electrodomestico}")
        return jsonify({"message": "Error al actualizar el electrodoméstico. Intente nuevamente"}), 500

    else:
        return "", 204


@appliances.route("/appliances/<int:id_>", methods=["DELETE"])
@sesion_requerida
def eliminar_electrodomestico(id_, usuario):
    
    # Obtener electrodoméstico a eliminar
    electrodomestico = db.session.get(Electrodomestico, id_)
    
    if not electrodomestico or electrodomestico.id_usuario != usuario.id_usuario:
        return jsonify({"message": "Electrodoméstico no encontrado"}), 404

    try:
        db.session.delete(electrodomestico)
        db.session.commit()

    except Exception:
        db.session.rollback()
        current_app.logger.exception(f"Error al eliminar el electrodoméstico {id_}")
        return jsonify({"message": "Error al eliminar el electrodoméstico. Intente nuevamente."}), 500

    else:
        return "", 204


@appliances.route("/appliances/<int:id_>", methods=["GET"])
@sesion_requerida
def obtener_electrodomestico_id(id_, usuario):
    
    # Obtener electrodoméstico a mostrar
    electro = db.session.get(Electrodomestico, id_)
    
    if not electro or electro.id_usuario != usuario.id_usuario:
        return jsonify({"message": "Electrodoméstico no encontrado"}), 404

    return jsonify(serializar_electrodomestico(
            electro.nombre, electro.tipo, electro.horas_dia, electro.dias_semana, electro.cantidad
        )), 200


@appliances.route("/appliances/info", methods=["GET"])
@sesion_requerida
def obtener_catalogo_electrodomesticos():
    
    response = obtener_electrodomesticos_disponibles()
    return jsonify(response), 200
