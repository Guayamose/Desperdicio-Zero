# Frontend .NET MAUI - Desperdicio Zero

Este directorio contiene el nuevo cliente móvil/escritorio en `.NET MAUI` para reemplazar el frontend web, manteniendo el backend en Ruby on Rails.

## Ubicación

- Proyecto MAUI: `frontend-maui/DesperdicioZero.Maui`
- Backend API (Ruby): raíz del repo (`/api/v1/...`)

## Funcionalidades cubiertas

- Login por sesión y selección de tenant activo.
- Portal público de comedores + menú del día.
- Dashboard tenant.
- Inventario (alta, edición, borrado, búsqueda y consulta por código de barras).
- Alertas de caducidad.
- Menús (listado, generación IA, edición manual, publicación y borrado).
- Empleados (alta, cambio de rol, baja).
- Perfil (actualización de datos, contraseña, switch de tenant, logout).
- Consola admin (métricas, tenants CRUD, usuarios create/block/anonymize/export, audit logs).

## Configuración base URL

En la pantalla de login o perfil puedes configurar la URL del backend.

- Android Emulator: `http://10.0.2.2:3000`
- iOS/Windows/macOS local: `http://localhost:3000`

## Comandos esperados (en entorno con .NET + workload MAUI)

```bash
cd frontend-maui/DesperdicioZero.Maui
dotnet workload install maui
# Android
 dotnet build -f net8.0-android
# Windows
 dotnet build -f net8.0-windows10.0.19041.0
```

## Nota

El backend Rails fue ampliado con endpoints JSON adicionales para garantizar paridad funcional con el nuevo frontend MAUI.
