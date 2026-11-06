"""Modulo para excepciones del sistema"""

class ContrasenaInsegura(Exception):
    """Excepción para evitar que el usuario registre una contraseña insegura"""

    def __init__(self):
        super().__init__("La contraseña no cumple con los requerimientos de seguridad.")
        self.__notes__ = []


    def is_valid_to_raise(self):
        """Retorna un booleano que indica si la excepción se puede lanzar o no"""
        return len(self.__notes__) > 0

    
    def show_notes(self):
        """Retorna la lista de notas añadidas a la excepción.
            Cada nota representa una característica insegura dentro de la contraseña ingresada."""
        return self.__notes__