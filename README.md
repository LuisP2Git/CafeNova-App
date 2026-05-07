# ☕ CafeNova-App

Sistema de gestión para cafeterías desarrollado como proyecto académico del SENA, enfocado en la administración de usuarios, empleados, fincas, cultivos, lotes y reportes mediante una aplicación moderna con Flutter y Node.js.

---

# 📖 Descripción

CafeNova-App es una aplicación desarrollada para optimizar la gestión y administración de procesos relacionados con una cafetería o finca cafetera. El sistema permite centralizar información importante como empleados, cultivos, lotes, usuarios y reportes, facilitando el control y seguimiento de la información desde una interfaz moderna e intuitiva.

El proyecto se encuentra dividido en:
- Frontend desarrollado en Flutter.
- Backend desarrollado con Node.js y Express.
- Base de datos MySQL.

---

# 👥 Integrantes

- Carol Sofia Realpe
- Luis Carlos Latorre Berdugo

---

# 🛠️ Tecnologías utilizadas

## Frontend
- Flutter
- Dart

## Backend
- Node.js
- Express.js

## Base de datos
- MySQL

## Librerías y herramientas
- dotenv
- cors
- nodemon
- mysql2
- express
- flutter/material

---

# 📂 Estructura del proyecto

```bash

CafeNova-App/
│
├── backend/
│   ├── node_modules/
│   ├── src/
│   │   ├── config/
│   │   ├── controllers/
│   │   ├── models/
│   │   └── routes/
│   │
│   ├── app.js
│   ├── index.js
│   ├── .env
│   ├── .gitignore
│   ├── package.json
│   └── package-lock.json
│
├── frontend/
│   ├── android/
│   ├── ios/
│   ├── linux/
│   ├── macos/
│   ├── windows/
│   ├── web/
│   ├── test/
│   │
│   ├── lib/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── utils/
│   │   └── main.dart
│   │
│   ├── build/
│   ├── pubspec.yaml
│   ├── pubspec.lock
│   └── README.md
│
├── database/
│   └── cafenova.sql
│
└── README.md
```

---

# ⚙️ Requisitos previos

Antes de ejecutar el proyecto debes tener instalado lo siguiente:

## Generales
- Git
- Visual Studio Code

## Frontend
- Flutter SDK
- Dart SDK
- Android Studio o Visual Studio Code con extensiones Flutter

## Backend
- Node.js
- npm

## Base de datos
- MySQL Server
- MySQL Workbench

---

# 📥 Instalación

## 1. Clonar el repositorio

```bash
git clone https://github.com/LuisP2Git/CafeNova-App.git
```

---

## 2. Entrar al proyecto

```bash
cd CafeNova-App
```

---

# ▶️ Ejecución local

# 🔹 Backend

## Entrar a la carpeta backend

```bash
cd backend
```

## Instalar dependencias

```bash
npm install
```

## Ejecutar servidor

```bash
npm run dev
```

o

```bash
node index.js
```

---

# 🔹 Frontend

## Entrar a la carpeta frontend

```bash
cd frontend
```

## Instalar dependencias

```bash
flutter pub get
```

## Ejecutar aplicación

```bash
flutter run
```

---

# 🗄️ Base de datos

## Crear la base de datos

```sql
CREATE DATABASE cafenova;
```

---

## Importar el archivo SQL

El archivo se encuentra en:

```bash
/database/cafenova.sql
```

Puedes importarlo desde:
- MySQL Workbench
- phpMyAdmin
- Línea de comandos

---

# 🔐 Variables de entorno

Crear un archivo `.env` dentro de la carpeta backend.

Ejemplo:

```env
PORT=3000

DB_HOST=localhost
DB_USER=root
DB_PASSWORD=tu_contraseña
DB_NAME=cafenova
DB_PORT=3306
```

## Descripción de variables

| Variable | Descripción |
|---|---|
| PORT | Puerto del servidor |
| DB_HOST | Dirección del servidor MySQL |
| DB_USER | Usuario de MySQL |
| DB_PASSWORD | Contraseña de MySQL |
| DB_NAME | Nombre de la base de datos |
| DB_PORT | Puerto de MySQL |

---

# 👤 Usuario de prueba

```txt
Correo:
admin@cafenova.com

Contraseña:
Admin123*
```

---

# 📱 Módulos principales

El sistema cuenta con los siguientes módulos:

- Inicio de sesión
- Registro de usuarios
- Gestión de empleados
- Gestión de cultivos
- Gestión de lotes
- Gestión de fincas
- Reportes
- Perfil de usuario
- Usuarios pendientes
- Módulo IA

---

# 🚀 Despliegue

## Frontend
Plataformas recomendadas:
- Firebase Hosting
- Vercel
- Netlify

## Backend
Plataformas recomendadas:
- Railway
- Render
- Heroku

## Base de datos
- MySQL Server
- PlanetScale

---

# 💡 Recomendaciones

## Backend
- No subir la carpeta `node_modules`.
- Mantener protegido el archivo `.env`.
- Validar correctamente los datos enviados desde el frontend.

## Frontend
- Mantener organizada la estructura de pantallas y servicios.
- Reutilizar widgets y componentes para mejorar mantenimiento.

## Base de datos
- Realizar copias de seguridad periódicas.
- Mantener relaciones correctamente definidas entre tablas.

## GitHub
- Realizar commits organizados.
- Documentar cambios importantes.
- Utilizar ramas para nuevas funcionalidades.

---

# 📸 Evidencias

## 🔐 Inicio de sesión

![Login](assets/login.png)

---

## 🏠 Pantalla principal

![Dashboard](assets/dashboard.png)

---

## 👷 Gestión de empleados

![Empleados](assets/empleados.png)

---

## 🌱 Gestión de cultivos

![Cultivos](assets/cultivos.png)

---

## 🗄️ Base de datos MySQL

![Base de datos](assets/database.png)

---

## ⚙️ Pruebas de API en Insomnia

![Insomnia](assets/insomnia_api.png)

---

# 📌 Estado del proyecto

🚧 Proyecto en desarrollo y mejora continua.

Actualmente el sistema cuenta con:
- Frontend funcional en Flutter.
- Backend API REST con Node.js y Express.
- Integración con base de datos MySQL.
- Módulos principales implementados.

---

# 📄 Licencia

Este proyecto fue desarrollado con fines académicos para el SENA.

Licencia de uso educativo y demostrativo.

© 2026 CafeNova-App
