# Frontend .NET MAUI Publico - Desperdicio Zero

Este directorio contiene la app `.NET MAUI` publica para usuarios finales.

## Ubicacion

- Proyecto MAUI: `frontend-maui-user/DesperdicioZero.User.Maui`
- Backend API (Rails): `/api/v1/public/...`

## Funcionalidades

- Directorio publico de comedores.
- Busqueda por nombre, ciudad, region o pais.
- Filtros rapidos por favoritos, menu publicado y disponibilidad de contacto.
- Favoritos persistidos en el dispositivo.
- Ficha de cada comedor con ubicacion, contacto y horario.
- Consulta del menu publicado para hoy.
- Acciones rapidas para llamar, enviar email o abrir la ubicacion.
- Ajuste manual de la URL del backend.
- Prueba de conexion desde la pantalla de ajustes.

## URL base por defecto

- Android Emulator: `http://10.0.2.2:3000`
- Windows, macOS, iOS simulator y desktop local: `http://localhost:3000`

## Comandos habituales

```bash
cd frontend-maui-user/DesperdicioZero.User.Maui
dotnet build -f net8.0-android
```

Tambien puedes usar el script del repo para levantar backend, emulador e instalar la app:

```bash
./scripts/run-all-maui.sh
```
