"""Lógica y validación de datos para gestión de electrodomésticos"""

from models import Electrodomestico, InfoElectrodomestico
from extensions import db

def obtener_potencia(tipo_electrodomestico: str) -> int:
    """Obtiene la potencia en W de un electrodoméstico"""
    potencia = db.session.execute(
        db.select(InfoElectrodomestico.potencia_watts).where(InfoElectrodomestico.nombre == tipo_electrodomestico)
    ).scalar_one_or_none()

    if potencia == None:
        raise ValueError()

    return potencia


def calcular_kwh(potencia_w: int, horas_dia: float, dias_semana: int, cantidad: int) -> float:
    """Calcula el consumo mensual en kWh de un electrodoméstico"""
    return (potencia_w / 1000) * horas_dia * dias_semana * 4.33 * cantidad


def serializar_electrodomestico(electrodomestico: Electrodomestico) -> dict:
    """Serializa un electrodoméstico en un diccionario para posteriormente ser retornado como JSON"""
    consumo = calcular_kwh(electrodomestico.potencia, electrodomestico.horas_dia, electrodomestico.dias_semana, electrodomestico.cantidad)
    return {
        "id": electrodomestico.id_electrodomestico,
        "nombre": electrodomestico.nombre,
        "tipo": electrodomestico.tipo,
        "potencia_w": electrodomestico.potencia_w,
        "consumo_mensual": consumo,
        "horas_dia": electrodomestico.horas_dia,
        "dias_semana": electrodomestico.dias_semana,
        "cantidad": electrodomestico.cantidad
    }


def anadir_electrodomestico(id_usuario: int, nombre: str, tipo: str, horas_dia: float, dias_semana: int, cantidad: int) -> dict:
    """Añade un nuevo electrodoméstico a la base de datos"""

    potencia = obtener_potencia(tipo)

    electrodomestico = Electrodomestico(
        id_usuario=id_usuario,
        nombre=nombre,
        tipo=tipo,
        potencia_w=potencia,
        horas_dia=horas_dia,
        dias_semana=dias_semana,
        cantidad=cantidad
    )

    try:
        db.session.add(electrodomestico)
        db.session.commit()

    except Exception:
        db.session.rollback()
        raise

    else:
        return serializar_electrodomestico(electrodomestico)


def actualizar_datos_electrodomestico(electrodomestico: Electrodomestico, nombre: str, tipo: str, horas_dia: float, dias_semana: int, cantidad: int):
    """Actualiza los datos de un electrodoméstico"""

    potencia = obtener_potencia(tipo)

    try:
        electrodomestico.nombre = nombre
        electrodomestico.tipo = tipo
        electrodomestico.potencia_w = potencia
        electrodomestico.horas_dia = horas_dia
        electrodomestico.dias_semana = dias_semana
        electrodomestico.cantidad = cantidad
        db.session.commit()

    except Exception:
        db.session.rollback()
        raise


def obtener_electrodomesticos_disponibles() -> dict:

    resultados = db.session.execute(
        db.select(InfoElectrodomestico)
    ).scalars().all()

    respuesta = {}

    for tipo in resultados:
        respuesta[tipo.nombre] = tipo.potencia_watts

    return respuesta
