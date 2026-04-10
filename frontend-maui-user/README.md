# Frontend .NET MAUI Usuario - Desperdicio Zero

Este directorio contiene una app `.NET MAUI` separada del cliente interno, enfocada solo en la experiencia publica del usuario.

## Ubicacion

- Proyecto MAUI: `frontend-maui-user/DesperdicioZero.User.Maui`
- Backend API (Rails): `/api/v1/public/...`

## Funcionalidades

- Directorio publico de comedores.
- Busqueda por nombre, ciudad, region o pais.
- Ficha de cada comedor con ubicacion, contacto y horario.
- Consulta del menu publicado para hoy.
- Ajuste manual de la URL del backend.

## URL base por defecto

- Android Emulator: `http://10.0.2.2:3000`
- Windows, macOS, iOS simulator y desktop local: `http://localhost:3000`

## Comandos habituales

```bash
cd frontend-maui-user/DesperdicioZero.User.Maui
dotnet build -f net8.0-android
```
