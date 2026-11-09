# ☀️ SolarO

> Plataforma de aprendizaje y simulación de energía solar para monitorear el consumo energético doméstico.

[![Web](https://img.shields.io/badge/Web-Disponible-FFC107?style=for-the-badge)](https://solaro-black.vercel.app)
[![APK](https://img.shields.io/badge/Android-APK-0052CC?style=for-the-badge)](<ENLACE_APK>)
![Estado](https://img.shields.io/badge/estado-finalizado-success?style=for-the-badge)

---

## 📌 Tabla de contenido

- [Descripción](#-descripción)
- [Funcionalidades](#-funcionalidades)
- [Tecnologías](#-tecnologías)
- [Arquitectura](#-arquitectura)
- [Despliegue](#-despliegue)
- [Documentación de la API](#-documentación-de-la-api)
- [Descargar la app](#-descargar-la-app)
- [Equipo](#-equipo)
- [Licencia](#-licencia)

---

## 📖 Descripción

SolarO busca acercar la energía solar a los hogares. Permite entender cuánto consume cada electrodoméstico, estimar su impacto mensual en kWh y aprender los fundamentos de la energía solar a través de módulos educativos con seguimiento de progreso.

El producto está disponible en la web y en Android, listo para que los usuarios lo utilicen.

## ✨ Funcionalidades

- **Autenticación segura:** registro, inicio de sesión, recuperación y cambio de contraseña, con sesiones deslizantes mediante JWT.
- **Gestión de electrodomésticos:** alta, edición y eliminación de equipos. El consumo mensual se calcula a partir de la potencia, las horas de uso diario, los días por semana y la cantidad.
- **Catálogo de potencias:** lista desplegable de electrodomésticos con su potencia nominal.
- **Monitoreo de consumo:** tarjeta de consumo y gráfico mensual interactivo.
- **Aprendizaje solar:** tres niveles de lecciones con barra de progreso y marcado de lecciones completadas.
- **PQRS:** peticiones, quejas, reclamos y sugerencias con número de radicado, notificación por correo y consulta del historial.

## 🛠️ Tecnologías

### Backend
![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=flat-square&logo=flask&logoColor=white)
![SQLAlchemy](https://img.shields.io/badge/SQLAlchemy-D71F00?style=flat-square)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![JWT](https://img.shields.io/badge/JWT-000000?style=flat-square&logo=jsonwebtokens&logoColor=white)
![Brevo](https://img.shields.io/badge/Brevo-0B996E?style=flat-square)

### Frontend
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)

### Infraestructura
![Render](https://img.shields.io/badge/Render-46E3B7?style=flat-square&logo=render&logoColor=black)
![Vercel](https://img.shields.io/badge/Vercel-000000?style=flat-square&logo=vercel&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat-square&logo=github&logoColor=white)

## 🏗️ Arquitectura

SolarO sigue una arquitectura **cliente-servidor desacoplada**: los clientes (web y móvil) consumen una API REST que concentra la lógica de negocio y el acceso a datos.

```
┌────────────────────┐        HTTPS / JSON        ┌─────────────────────┐        ┌──────────────┐
│  Web (Vercel)      │  ───────────────────────►  │   API Flask (Render)│  ───►  │  PostgreSQL  │
│  Flutter (Dart)    │   Authorization: Bearer    │   Blueprints        │        └──────────────┘
├────────────────────┤                            │   Services          │
│  App móvil Flutter │  ───────────────────────►  │   Models (ORM)      │  ───►  Brevo (correos)
│  (Dart)            │                            └─────────────────────┘
└────────────────────┘
```

### Backend
- **Flask** organizado por *blueprints*: `auth`, `users`, `appliances`, `learn` y `feedback`.
- Separación por capas: **routes** (HTTP y validación), **service** (lógica de negocio) y **models** (SQLAlchemy).
- **Autenticación JWT** con refresh token; el token de recuperación de contraseña es de un solo uso (vinculado a la huella del hash actual).
- Configuración por **variables de entorno** (`DATABASE_URL`, `JWT_SECRET_KEY`, `BREVO_API_KEY`, `FRONTEND_URL`, entre otras).
- Errores de dominio propios (por ejemplo, `PotenciaInvalida`) traducidos a códigos HTTP.

### Frontend
- **Aplicación Flutter** desarrollada 100% en **Dart**, compilada tanto para web como para Android, con una única base de código que consume la misma API.

### Modelo de datos (resumen)
- `usuarios`, `electrodomesticos`, `info_electrodomesticos` (catálogo de potencias), progreso de lecciones y registros PQRS.

## 🚀 Despliegue

| Componente | Plataforma | Enlace |
|---|---|---|
| Frontend web | Vercel | [solaro-black.vercel.app](https://solaro-black.vercel.app) |
| Aplicación Android | APK | `Próximamente` |

## 📚 Documentación de la API

El contrato completo de los endpoints está en la carpeta [`docs/`](https://github.com/NymaXD/SolarO/tree/main/docs) (`api-contract.md`, `auth.md`, `users.md`, `appliances.md`).

## 📱 Descargar la app

**Android:** Próximamente.

**Web:** accede desde [solaro-black.vercel.app](https://solaro-black.vercel.app) sin instalar nada.

## 👥 Equipo

| Integrante | Rol | Módulos |
|---|---|---|
| `Niray Muñoz` | Backend | Autenticación, usuarios, despliegue de API |
| `Juan Laguna` | Frontend | Electrodomésticos, Simulador, PQRS, Interfaz Flutter |
| `Michael Mora` | Base de Datos | Diseño y Administración de Base de Datos |

## 📄 Licencia

© 2026 Equipo del proyecto SolarO. Todos los derechos reservados.

El código fuente de este repositorio es de uso privado de sus autores. No se autoriza copiar, modificar, distribuir ni utilizar este software, total o parcialmente, sin autorización previa y por escrito de los titulares de los derechos.
