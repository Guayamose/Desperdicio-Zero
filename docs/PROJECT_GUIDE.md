# PROJECT GUIDE - Desperdicio Zero (Social Kitchen Dashboard)

## Project Inventory (obligatorio)

Este inventario está basado **solo** en lo encontrado en el repositorio.

- Repo: `desperdicio-zero`
- Tipo: aplicación Ruby on Rails monolítica SSR + API JSON
- Ruby: `3.3.5` (`.ruby-version`, `Gemfile`, `Gemfile.lock`)
- Rails: `7.1.6` (`Gemfile`)
- Bundler: `2.6.9` (`Gemfile.lock`)
- DB engine: PostgreSQL (`config/database.yml`, gem `pg`)
- AuthN: Devise (`gem 'devise'`, `app/models/user.rb`)
- AuthZ: Pundit (`gem 'pundit'`, `app/policies/*.rb`)
- Jobs: Sidekiq + Redis (`gem 'sidekiq'`, `gem 'redis'`, `config/initializers/sidekiq.rb`)
- Frontend: Rails views ERB + Turbo + Stimulus + Importmap (`app/views`, `app/javascript`, `config/importmap.rb`)
- CSS: stylesheet manual en `app/assets/stylesheets/application.css` (no Tailwind/Bootstrap)
- API: namespace `api/v1` con controllers JSON (`app/controllers/api/v1/*`)
- Multi-tenant: por `Tenant` + `Membership` + `Current.tenant`
- Integraciones externas reales:
  - OpenFoodFacts: `app/services/integrations/open_food_facts_client.rb`
  - OpenAI: `app/services/integrations/open_ai_client.rb`
- Auditoría: `AuditLog` + `AuditLogger`
- Seed de demo completo: `db/seeds.rb`
- Tests: Minitest (integración + servicios), no RSpec
- Despliegue: `Procfile` (web + worker) y `Dockerfile`
- Variables de entorno encontradas en `.env`:
  - `OPENAI_API_KEY`
  - `OPENAI_MODEL`
  - `REDIS_URL`
  - `APP_HOST`
- Hallazgos de "No encontrado en el repo":
  - `.env.example` (README lo menciona, pero no existe)
  - Mailers funcionales de negocio (solo existe `ApplicationMailer` base)
  - ActionCable channels personalizados (solo skeleton)
  - ActiveStorage attachments en modelos (no hay `has_one_attached` / `has_many_attached`)
  - Rake tasks custom en `lib/tasks` (solo `.keep`)
  - Views API con Jbuilder (responses JSON construidas en controllers)
  - Service objects de pagos, facturación, notificaciones push, etc.

## Tabla de contenido

- [0. TL;DR para el hackathon (1 página)](#0-tldr-para-el-hackathon-1-página)
- [1. Qué es este proyecto (en lenguaje simple)](#1-qué-es-este-proyecto-en-lenguaje-simple)
- [2. Cómo funciona Rails (explicación didáctica)](#2-cómo-funciona-rails-explicación-didáctica)
- [3. Mapa del repositorio (estructura real)](#3-mapa-del-repositorio-estructura-real)
- [4. Configuración y dependencias](#4-configuración-y-dependencias)
- [5. Base de datos y modelos (MUY importante)](#5-base-de-datos-y-modelos-muy-importante)
- [6. Rutas y controladores (Cómo navega la app)](#6-rutas-y-controladores-cómo-navega-la-app)
- [7. Vistas, UI y Frontend](#7-vistas-ui-y-frontend)
- [8. Servicios, helpers, concerns y lib (si existen)](#8-servicios-helpers-concerns-y-lib-si-existen)
- [9. Jobs, mailers, integraciones externas (si existen)](#9-jobs-mailers-integraciones-externas-si-existen)
- [10. Testing y calidad (si hay tests)](#10-testing-y-calidad-si-hay-tests)
- [11. Cómo ejecutar y desarrollar en local (paso a paso)](#11-cómo-ejecutar-y-desarrollar-en-local-paso-a-paso)
- [12. Playbook de cambios (GUÍA PARA NO PROGRAMADORES)](#12-playbook-de-cambios-guía-para-no-programadores)
- [13. “Prompts” listos para usar con IA (copiar/pegar)](#13-prompts-listos-para-usar-con-ia-copiarpegar)
- [14. Checklist final para el hackathon](#14-checklist-final-para-el-hackathon)

---

## 0. TL;DR para el hackathon (1 página)

### Qué tocar rápido según objetivo

- Diseño global:
  - `app/assets/stylesheets/application.css`
  - `app/views/layouts/application.html.erb`
- Textos UI:
  - Vistas en `app/views/public/*`, `app/views/tenant_portal/*`, `app/views/admin/*`
- Pantallas nuevas:
  - `config/routes.rb` + controller nuevo en `app/controllers/...` + vista en `app/views/...`
- Lógica negocio:
  - `app/services/*`
  - `app/controllers/*`
  - `app/models/*`
- Base de datos:
  - `db/migrate/*` (nunca editar migraciones viejas en hackathon salvo que sepas exactamente por qué)
  - revisar `db/schema.rb` después de migrar
- Login:
  - Devise en `app/models/user.rb`, `config/initializers/devise.rb`, `app/views/devise/sessions/new.html.erb`
- Permisos:
  - Pundit policies en `app/policies/*`
  - validación en controllers con `authorize` y `policy_scope`

### Qué NO tocar (alto riesgo)

- `config/master.key` (secreto)
- `config/credentials.yml.enc` (encriptado)
- `db/schema.rb` manualmente
- Borrar o alterar en bloque `app/policies/*` sin revisar flujos
- Cambiar `Current.tenant` o lógica de `ApplicationController#current_tenant` sin testear todo
- Borrar enums de modelos (`status`, `role`, etc.) sin migración de datos

### Cómo volver atrás

- Ver cambios:
  - `git status`
  - `git diff`
- Deshacer archivo concreto (si estás seguro):
  - `git restore path/al/archivo`
- Deshacer commit local:
  - `git log --oneline`
  - `git revert <sha>` (seguro para historial compartido)
- Base de datos:
  - rollback 1 migración: `bin/rails db:rollback`
  - rollback N: `bin/rails db:rollback STEP=2`

---

## 1. Qué es este proyecto (en lenguaje simple)

### Qué hace la app

Es una plataforma para comedores sociales que ayuda a:

- Publicar menús del día para público general.
- Gestionar inventario interno por lotes y caducidad.
- Escanear productos por código de barras y autocompletar datos.
- Generar borradores de menú con IA según inventario próximo a vencer.
- Administrar comedores, usuarios y auditoría desde un panel global.

### Para quién es

- Público: consulta comedores y menú del día (`/`, `/comedores`, `/comedores/:slug/menu-today`).
- Equipo del comedor: gestiona inventario, escaneo, menús, alertas (`/tenant/*`).
- Admin global: gestiona tenants, usuarios, métricas y audit logs (`/admin/*`).
- Integraciones/API clients: usan `/api/v1/*`.

### Flujos principales de usuario (paso a paso)

1. Usuario interno inicia sesión en `/users/sign_in`.
2. App selecciona `current_tenant` por membresía activa (`ApplicationController`).
3. Usuario entra a `/tenant/dashboard`.
4. Escanea código en `/tenant/scans/new`.
5. Se consulta OpenFoodFacts y se redirige a nuevo lote pre-rellenado (`/tenant/inventory_lots/new`).
6. Guarda lote, se registra `StockMovement` y `AuditLog`.
7. Abre generador IA en `/tenant/menus/generate`.
8. Selecciona lotes prioritarios, genera menú borrador.
9. Edita y publica menú.
10. Público ve el menú en `/comedores/:slug/menu-today`.

---

## 2. Cómo funciona Rails (explicación didáctica)

### MVC explicado con el flujo de una request

Ejemplo real del repo: `GET /tenant/inventory_lots`

1. `config/routes.rb` decide que va a `TenantPortal::InventoryLotsController#index`.
2. El controller pide datos al modelo: `tenant_scope(InventoryLot)...`.
3. `InventoryLot` (modelo ActiveRecord) consulta PostgreSQL.
4. Controller guarda resultado en `@inventory_lots`.
5. Rails renderiza `app/views/tenant_portal/inventory_lots/index.html.erb`.
6. El layout `app/views/layouts/application.html.erb` envuelve la vista.
7. CSS/JS se aplica desde `application.css` e importmap/stimulus.

### Qué hace `routes.rb`

- Es el mapa URL -> Controller#Acción.
- En este repo también define namespaces:
  - `public` (portal)
  - `tenant_portal` (panel comedor)
  - `admin` (panel global)
  - `api/v1/public`, `api/v1/tenant`, `api/v1/admin`
- También monta Sidekiq Web en desarrollo: `/sidekiq`.

### Qué hace ActiveRecord

- Conecta clases Ruby (`User`, `Tenant`, etc.) con tablas SQL (`users`, `tenants`, ...).
- Maneja validaciones, relaciones, enums y scopes.
- Ejemplo:
  - `InventoryLot.available` usa enum para filtrar status.
  - `Tenant.has_many :inventory_lots` crea relación automática.

### Qué hace la carpeta `app/`

- `app/models`: datos y reglas de dominio.
- `app/controllers`: entrada HTTP y orquestación.
- `app/views`: HTML ERB renderizado en servidor.
- `app/services`: integraciones y lógica compleja reutilizable.
- `app/jobs`: trabajos asíncronos Sidekiq.
- `app/policies`: permisos Pundit.
- `app/javascript/controllers`: Stimulus controllers.
- `app/assets/stylesheets`: CSS global.

### Qué son migrations y schema

- Migration = historial de cambios de BD (`db/migrate/*.rb`).
- `db/schema.rb` = estado actual consolidado.
- Flujo correcto:
  1. crear migration
  2. ejecutar `bin/rails db:migrate`
  3. revisar que `schema.rb` refleje el cambio

### Cómo se renderiza una vista

- Motor encontrado: **ERB** (`*.html.erb`).
- Rails usa `layout` + `yield` + variables `@...` del controller.
- Ejemplo:
  - `TenantPortal::MenusController#show`
  - vista: `app/views/tenant_portal/menus/show.html.erb`
  - layout: `app/views/layouts/application.html.erb`

### Turbo/Hotwire/Stimulus

- Turbo: **sí** (`gem 'turbo-rails'`, `import "@hotwired/turbo-rails"`).
- Stimulus: **sí** (`gem 'stimulus-rails'`, controllers en `app/javascript/controllers`).
- Hotwire práctico en este repo:
  - filtros visuales (`card_filter_controller.js`)
  - escaneo cámara (`barcode_scanner_controller.js`)
  - autocompletar lote por API (`inventory_form_controller.js`)
  - alta/baja dinámica de platos (`menu_items_controller.js`)
- Turbo Streams custom: **No encontrado en el repo**.

---

## 3. Mapa del repositorio (estructura real)

### Árbol de carpetas principales (resumen)

```text
app/
  assets/
  controllers/
    admin/
    api/v1/
    public/
    tenant_portal/
  helpers/
  javascript/controllers/
  jobs/
  mailers/
  models/
  policies/
  services/
  views/
config/
db/
  migrate/
  schema.rb
  seeds.rb
test/
```

### Carpeta por carpeta (qué contiene y ejemplos)

- `app/controllers`
  - Ejemplo admin: `app/controllers/admin/users_controller.rb`
  - Ejemplo tenant: `app/controllers/tenant_portal/inventory_lots_controller.rb`
  - Ejemplo API: `app/controllers/api/v1/tenant/inventory_lots_controller.rb`
- `app/models`
  - Núcleo dominio: `tenant.rb`, `inventory_lot.rb`, `daily_menu.rb`, `menu_generation.rb`
- `app/policies`
  - Autorización Pundit por recurso: `inventory_lot_policy.rb`, `tenant_policy.rb`, etc.
- `app/services`
  - Integraciones API: `integrations/open_food_facts_client.rb`, `integrations/open_ai_client.rb`
  - Caso negocio: `menus/generate_daily_menu_service.rb`
- `app/jobs`
  - Asíncronos Sidekiq: `generate_daily_menu_job.rb`, `sync_product_from_barcode_job.rb`
- `app/views`
  - Público: `app/views/public/*`
  - Tenant: `app/views/tenant_portal/*`
  - Admin: `app/views/admin/*`
- `config`
  - Routing: `config/routes.rb`
  - DB: `config/database.yml`
  - Entornos: `config/environments/*.rb`
  - Sidekiq: `config/sidekiq.yml`, `config/initializers/sidekiq.rb`
- `db`
  - Migraciones reales de dominio: users, tenants, memberships, inventory, menus, audit logs
- `test`
  - Integración: `test/integration/*`
  - Servicios: `test/services/*`

---

## 4. Configuración y dependencias

### Ruby version

- `3.3.5` (`.ruby-version`)

### Rails version

- `7.1.6` (`Gemfile`)

### Gems importantes (y uso real aquí)

- `devise`: autenticación de usuarios internos.
- `pundit`: autorización por policies.
- `sidekiq`: jobs asíncronos en cola.
- `redis`: backend de Sidekiq y cable production.
- `faraday`: cliente HTTP para OpenAI y OpenFoodFacts.
- `rack-attack`: rate limiting de endpoints sensibles.
- `turbo-rails`, `stimulus-rails`, `importmap-rails`: UX frontend sin bundler JS pesado.
- `jbuilder`: instalada, **No encontrado en el repo** su uso en vistas.
- `dotenv-rails`: carga `.env` en desarrollo/test.

### Config de entorno (dotenv, credentials, ENV)

- `.env` existe con claves: `OPENAI_API_KEY`, `OPENAI_MODEL`, `REDIS_URL`, `APP_HOST`.
- `.env.example`: **No encontrado en el repo**.
- `config/master.key`: existe localmente pero está ignorado por git.
- `config/credentials.yml.enc`: existe (encriptado, no legible directamente).

### Configuración de base de datos

- `config/database.yml` usa PostgreSQL para `development`, `test`, `production`.
- DB names:
  - `desperdicio_zero_development`
  - `desperdicio_zero_test`
  - `desperdicio_zero_production`

### Storage

- ActiveStorage configurado a disco local:
  - dev/prod: `:local`
  - test: `:test`
- S3/GCS/Azure: plantillas comentadas, no activas.

### Background jobs

- `config.active_job.queue_adapter = :sidekiq` (en `config/application.rb`).
- Jobs reales implementados con `include Sidekiq::Job`.
- Colas declaradas en `config/sidekiq.yml`:
  - `critical`
  - `default`
  - `low`

### Cache/Redis

- Redis para Sidekiq y ActionCable prod (`config/cable.yml`).
- Cache explícita con Redis: **No encontrado en el repo**.
- `Rails.cache` sí se usa en `OpenFoodFactsClient` (cache por clave de barcode).

### Autenticación

- Devise en `User`: `database_authenticatable`, `recoverable`, `rememberable`, `validatable`.
- Sign out via DELETE (`config/initializers/devise.rb`).
- Usuarios bloqueados no pueden autenticarse (`User#active_for_authentication?`).

---

## 5. Base de datos y modelos (MUY importante)

### Motor BD

- PostgreSQL (`plpgsql` activo en `db/schema.rb`).

### Modelos reales en `app/models`

#### `User`

- Representa: cuenta interna (admin/manager/staff).
- Relaciones:
  - `has_many :memberships`
  - `has_many :tenants, through: :memberships`
  - `has_many :system_roles`
  - relaciones de auditoría y creación (`audit_logs`, `created_daily_menus`, etc.)
- Validaciones:
  - `full_name` presente
- Lógica:
  - `system_admin?`
  - `active_memberships`
  - `in_tenant?`
  - `anonymize_personal_data!`
  - bloqueo auth por `blocked_at`
- Campos relevantes (`users`):
  - `email`, `encrypted_password`, `full_name`, `locale`, `gdpr_consent_at`, `last_seen_at`, `blocked_at`

#### `Tenant`

- Representa: comedor (tenant de negocio).
- Relaciones:
  - `has_many :memberships`, `:users`, `:inventory_lots`, `:daily_menus`, `:menu_generations`, `:audit_logs`, `:stock_movements`
- Validaciones:
  - `name` presente
  - `slug` presente y único
- Enums:
  - `status`: `active`, `inactive`, `suspended`
- Scope:
  - `operational` (solo activos)
- Campos:
  - identidad (`name`, `slug`, `status`)
  - ubicación (`address`, `city`, `region`, `country`, `latitude`, `longitude`)
  - contacto (`contact_email`, `contact_phone`)
  - `operating_hours_json`

#### `Membership`

- Representa: vínculo usuario-tenant.
- Relaciones:
  - `belongs_to :user`, `belongs_to :tenant`
- Enums:
  - `role`: `tenant_manager`, `tenant_staff`
- Validaciones:
  - unicidad `[user_id, tenant_id]`
  - `active` booleano
- Scope:
  - `active`

#### `SystemRole`

- Representa: rol global del sistema.
- Relaciones:
  - `belongs_to :user`
- Enum:
  - `role`: `system_admin`
- Validación:
  - unicidad `[user_id, role]`

#### `Product`

- Representa: catálogo de producto (barcode + metadata).
- Relaciones:
  - `has_many :inventory_lots, dependent: :restrict_with_error`
- Enum:
  - `source`: `openfoodfacts`, `manual`
- Validaciones:
  - `name` presente
  - `barcode` único (permite blank)
- Campos:
  - `barcode`, `name`, `brand`, `category`, `ingredients_text`, `allergens_json`, `nutrition_json`, `source`, `last_synced_at`

#### `InventoryLot`

- Representa: lote físico de stock por tenant.
- Incluye `TenantScoped`.
- Relaciones:
  - `belongs_to :tenant`, `belongs_to :product`
  - `has_many :stock_movements`
- Enums:
  - `unit`: `kg`, `g`, `l`, `ml`, `unit`
  - `status`: `available`, `reserved`, `consumed`, `discarded`, `expired`
  - `source`: `donation`, `purchase`, `other`
- Validaciones:
  - `expires_on`, `quantity` presentes
  - `quantity > 0`
- Scopes:
  - `expiring_by(date)`
  - `critical_expiration` (hoy a +2 días)
- Campos:
  - `tenant_id`, `product_id`, `expires_on`, `quantity`, `unit`, `status`, `received_on`, `source`, `notes`

#### `StockMovement`

- Representa: trazabilidad de movimientos de stock.
- Incluye `TenantScoped`.
- Relaciones:
  - `belongs_to :tenant`, `:inventory_lot`
  - `belongs_to :performed_by, class_name: 'User', optional: true`
- Enum:
  - `movement_type`: `in`, `out`, `adjustment`, `waste` (nombres internos: `inbound`, `outbound`, ...)
- Validaciones:
  - presencia de `movement_type`, `quantity_delta`, `occurred_at`
  - `quantity_delta` numérico
  - tenant del movimiento debe coincidir con tenant del lote
- Callback:
  - `before_validation :set_defaults`

#### `DailyMenu`

- Representa: menú de un día para un tenant.
- Incluye `TenantScoped`.
- Relaciones:
  - `belongs_to :tenant`
  - `belongs_to :created_by, class_name: 'User', optional: true`
  - `has_many :daily_menu_items`
- Enums:
  - `status`: `draft`, `published`, `archived`
  - `generated_by`: `ai`, `manual`
- Validaciones:
  - `menu_date`, `title` presentes
  - unicidad de `menu_date` por tenant
- Scope:
  - `today`
- Nested attributes:
  - acepta `daily_menu_items_attributes`

#### `DailyMenuItem`

- Representa: plato del menú.
- Relaciones:
  - `belongs_to :daily_menu`
- Validaciones:
  - `name` presente
  - `position >= 0`
- Campos:
  - `name`, `description`, `ingredients_json`, `allergens_json`, `position`

#### `MenuGeneration`

- Representa: trazabilidad de una generación IA/manual fallback.
- Incluye `TenantScoped`.
- Relaciones:
  - `belongs_to :tenant`
  - `belongs_to :requested_by, class_name: 'User', optional: true`
- Enum:
  - `status`: `queued`, `running`, `succeeded`, `failed`, `fallback_manual`
- Validaciones:
  - `prompt_version` presente
- Campos:
  - `input_lot_ids_json`, `model`, `prompt_version`, `latency_ms`, `error_code`, `raw_response_encrypted`

#### `AuditLog`

- Representa: evento de auditoría.
- Relaciones:
  - `belongs_to :tenant, optional: true`
  - `belongs_to :actor, class_name: 'User', foreign_key: :actor_user_id, optional: true`
- Validaciones:
  - `action`, `entity_type` presentes
- Scope:
  - `recent`
- Campos:
  - `action`, `entity_type`, `entity_id`, `metadata_json`, `ip_address`

#### `Current`

- `ActiveSupport::CurrentAttributes`: contexto request-local.
- Atributos: `user`, `tenant`, `request_id`.

#### Concern `TenantScoped`

- Añade `belongs_to :tenant`.
- Scopes: `for_tenant`, `for_current_tenant`.
- Autoasigna tenant en create desde `Current.tenant`.
- Valida presencia de `tenant_id`.

### Diagrama textual de relaciones (pseudo-ER)

- `User` 1---N `Membership` N---1 `Tenant`
- `User` 1---N `SystemRole`
- `Tenant` 1---N `InventoryLot` N---1 `Product`
- `InventoryLot` 1---N `StockMovement`
- `Tenant` 1---N `DailyMenu` 1---N `DailyMenuItem`
- `Tenant` 1---N `MenuGeneration`
- `User` 1---N `AuditLog` (actor opcional)
- `Tenant` 1---N `AuditLog`

### Cómo añadir un nuevo campo (ejemplo real)

Ejemplo: añadir `phone_extension` a `tenants`.

1. Generar migration:
   - `bin/rails g migration AddPhoneExtensionToTenants phone_extension:string`
2. Ejecutar:
   - `bin/rails db:migrate`
3. Permitir param en controller:
   - `app/controllers/admin/tenants_controller.rb` (`tenant_params`)
   - `app/controllers/api/v1/admin/tenants_controller.rb` (`tenant_params`)
4. Mostrar/editar en vista:
   - `app/views/admin/tenants/_form.html.erb`
   - `app/views/admin/tenants/show.html.erb`
5. Si aplica, añadir validación en `app/models/tenant.rb`.
6. Verificar en consola:
   - `bin/rails c`
   - `Tenant.last.phone_extension`

---

## 6. Rutas y controladores (Cómo navega la app)

### Rutas principales agrupadas

#### Auth (Devise)

- `/users/sign_in`, `/users/sign_out`, `/users/password/*`

#### Pública

- `GET /` -> `Public::HomeController#show`
- `GET /comedores` -> `Public::TenantsController#index`
- `GET /comedores/:slug` -> `Public::TenantsController#show`
- `GET /comedores/:slug/menu-today` -> `Public::MenusController#today`

#### Tenant portal (`/tenant`)

- Switch tenant: `POST /tenant/switch/:tenant_id`
- Dashboard: `GET /tenant/dashboard`
- Inventory CRUD: `/tenant/inventory_lots`
- Scans: `GET /tenant/scans/new`, `POST /tenant/scans`
- Menus CRUD parcial + publish + generate
- Alerts expirations: `GET /tenant/alerts/expirations`

#### Admin (`/admin`)

- Tenants CRUD completo
- Users: index/show/new/create + `block` + `anonymize` + `export`
- Metrics show
- Audit logs index

#### API v1

- Public tenants + menu_today
- Tenant inventory/scans/alerts/menus
- Admin tenants/users/metrics/audit-logs

### Controladores reales y propósito

#### `ApplicationController`

- Propósito: contexto global + Pundit + tenant actual.
- Filtros:
  - `before_action :set_current_context`
  - `after_action :reset_current_context`
- Métodos clave:
  - `current_tenant`, `switch_current_tenant!`, `require_current_tenant!`, `require_system_admin!`
  - manejo de `Pundit::NotAuthorizedError`

#### `Public::HomeController#show`

- Carga tenants operativos y menús publicados de hoy para landing.
- Vista: `app/views/public/home/show.html.erb`

#### `Public::TenantsController#index/show`

- `index`: listado de comedores operativos + stats.
- `show`: detalle por slug, menú de hoy, menús recientes, nearby.
- Vistas: `app/views/public/tenants/index.html.erb`, `show.html.erb`

#### `Public::MenusController#today`

- Muestra menú publicado hoy por tenant slug.
- Vista: `app/views/public/menus/today.html.erb`

#### `TenantPortal::BaseController`

- Requiere login y tenant activo.
- Helper: `tenant_scope(scope)` = policy_scope + filtro tenant actual.

#### `TenantPortal::DashboardController#show`

- KPIs inventario/menú/generación.
- Vista: `app/views/tenant_portal/dashboard/show.html.erb`

#### `TenantPortal::InventoryLotsController`

- CRUD lotes + lógica producto (barcode/manual) + stock movements + audit.
- Params esperados:
  - `product_id`, `barcode`, `product_name`, `expires_on`, `quantity`, `unit`, `status`, `received_on`, `source`, `notes`
- Vistas:
  - `index`, `show`, `new`, `edit`, `_form`

#### `TenantPortal::ScansController`

- `new`: formulario de escaneo.
- `create`: busca por barcode y redirige a lote nuevo prefill.
- Params:
  - `barcode` (required), `source` (`usb`/`camera`)
- Vista: `app/views/tenant_portal/scans/new.html.erb`

#### `TenantPortal::MenusController`

- CRUD menús + publish + generación IA (GET preview / POST ejecutar).
- Params:
  - `daily_menu[menu_date,title,description,status,allergens_json[],daily_menu_items_attributes...]`
  - `date`, `lot_ids[]` en generate
- Vistas:
  - `index`, `show`, `new`, `edit`, `_form`, `generate`

#### `TenantPortal::AlertsController#expirations`

- Lista lotes por caducidad inminente y vencidos.
- Vista: `app/views/tenant_portal/alerts/expirations.html.erb`

#### `TenantPortal::SessionsController#switch`

- Cambia tenant actual si el usuario pertenece.

#### `Admin::BaseController`

- Requiere login + rol system admin.

#### `Admin::TenantsController`

- CRUD administrativo de tenants.
- Params permitidos incluyen ubicación/contacto/operating_hours_json.
- Vistas: `app/views/admin/tenants/*`

#### `Admin::UsersController`

- Alta usuario con password temporal, opcional membership y/o system role.
- Acciones especiales:
  - `block`, `anonymize`, `export`
- Vistas: `app/views/admin/users/*`

#### `Admin::MetricsController#show`

- Métricas agregadas globales (tenants, users, lots, menus, fallbacks).
- Vista: `app/views/admin/metrics/show.html.erb`

#### `Admin::AuditLogsController#index`

- Últimos 200 logs recientes.
- Vista: `app/views/admin/audit_logs/index.html.erb`

#### API controllers (`app/controllers/api/v1/*`)

- `Api::V1::BaseController`:
  - helpers JSON (`render_resource`, `render_collection`, `render_error`)
  - paginación (`page`, `per_page`)
  - camelCase response
- `Api::V1::Public::TenantsController`: index/show/menu_today
- `Api::V1::Tenant::BaseController`: auth + tenant requerido
- `Api::V1::Tenant::*`:
  - inventory lots CRUD
  - barcode scan
  - alerts expirations
  - menus generate/show/update/publish
- `Api::V1::Admin::BaseController`: auth + system admin requerido
- `Api::V1::Admin::*`:
  - tenants CRUD
  - users create/block/export
  - metrics show
  - audit logs index

### Mapa: pantalla -> ruta -> controlador -> vista -> modelo

- Home pública -> `/` -> `Public::HomeController#show` -> `app/views/public/home/show.html.erb` -> `Tenant`, `DailyMenu`
- Lista comedores -> `/comedores` -> `Public::TenantsController#index` -> `app/views/public/tenants/index.html.erb` -> `Tenant`, `DailyMenu`
- Menú público de un comedor -> `/comedores/:slug/menu-today` -> `Public::MenusController#today` -> `app/views/public/menus/today.html.erb` -> `Tenant`, `DailyMenu`, `DailyMenuItem`
- Dashboard tenant -> `/tenant/dashboard` -> `TenantPortal::DashboardController#show` -> `app/views/tenant_portal/dashboard/show.html.erb` -> `Tenant`, `InventoryLot`, `DailyMenu`, `MenuGeneration`
- Inventario tenant -> `/tenant/inventory_lots` -> `TenantPortal::InventoryLotsController#index` -> `app/views/tenant_portal/inventory_lots/index.html.erb` -> `InventoryLot`, `Product`
- Escaneo -> `/tenant/scans/new` -> `TenantPortal::ScansController#new` -> `app/views/tenant_portal/scans/new.html.erb` -> `Product`
- Menús tenant -> `/tenant/menus` -> `TenantPortal::MenusController#index` -> `app/views/tenant_portal/menus/index.html.erb` -> `DailyMenu`
- Generador IA -> `/tenant/menus/generate` -> `TenantPortal::MenusController#generate` -> `app/views/tenant_portal/menus/generate.html.erb` -> `InventoryLot`, `MenuGeneration`, `DailyMenu`
- Admin tenants -> `/admin/tenants` -> `Admin::TenantsController#index` -> `app/views/admin/tenants/index.html.erb` -> `Tenant`
- Admin users -> `/admin/users` -> `Admin::UsersController#index` -> `app/views/admin/users/index.html.erb` -> `User`, `Membership`, `SystemRole`
- Admin metrics -> `/admin/metrics` -> `Admin::MetricsController#show` -> `app/views/admin/metrics/show.html.erb` -> varios

---

## 7. Vistas, UI y Frontend

### Layout principal

- `app/views/layouts/application.html.erb`
- Incluye:
  - Header con navegación contextual
  - sección de flashes (`data-controller="flash"`)
  - `yield :hero`
  - footer
- Determina área visual por clase body: `app-area-public|tenant|admin`.

### Componentes/partials

- Tenant inventory form: `app/views/tenant_portal/inventory_lots/_form.html.erb`
- Tenant menu form: `app/views/tenant_portal/menus/_form.html.erb`
- Admin tenant form: `app/views/admin/tenants/_form.html.erb`

### Assets: CSS/JS

- CSS global: `app/assets/stylesheets/application.css`
- JS entrypoint: `app/javascript/application.js`
- Stimulus controllers:
  - `barcode_scanner_controller.js`
  - `inventory_form_controller.js`
  - `menu_items_controller.js`
  - `card_filter_controller.js`
  - `nav_controller.js`
  - `flash_controller.js`
  - `hello_controller.js` (demo)

### Cómo cambiar textos

- Edita directamente la vista correspondiente.
- Ejemplo:
  - título dashboard tenant: `app/views/tenant_portal/dashboard/show.html.erb`
  - textos login: `app/views/devise/sessions/new.html.erb`

### Cómo cambiar colores/estilos

- Variables CSS en `:root` de `app/assets/stylesheets/application.css`.
- También hay overrides por área:
  - `body.app-area-tenant`
  - `body.app-area-admin`

### Cómo cambiar estructura de una pantalla

- Modifica la vista `.html.erb` específica.
- Si añades comportamiento dinámico, vincula controller Stimulus (`data-controller`, `data-action`, `data-*-target`).

### Cómo cambiar formularios

- Lado view: campos en partial/form (`_form.html.erb`).
- Lado controller: permitir params en `permit(...)`.
- Lado model: validaciones.

### Cómo cambiar tablas/listados

- Listados en vistas tipo `index.html.erb`.
- Filtros cliente (sin backend) en `card_filter_controller.js`.

---

## 8. Servicios, helpers, concerns y lib (si existen)

### Patrones usados

- Service Objects: sí (`app/services/*`).
- Concern de modelo: sí (`TenantScoped`).
- Helpers de vista: sí (`ApplicationHelper` + namespaced vacíos).
- Presenters/Decorators: **No encontrado en el repo**.

### Servicios relevantes y por qué existen

- `AuditLogger`:
  - unifica creación de `AuditLog`.
- `Inventory::BarcodeLookupService`:
  - flujo lookup barcode local + OpenFoodFacts + fallback.
- `Menus::GenerateDailyMenuService`:
  - prioridad de lotes, llamada IA, persistencia menú, fallback manual, auditoría.
- `Tenancy::TenantSwitchService`:
  - valida cambio de tenant por membresía activa.
- `Integrations::OpenFoodFactsClient`:
  - llamada HTTP, normalización payload, cache en `Rails.cache`.
- `Integrations::OpenAiClient`:
  - llamada a `/v1/chat/completions`, fuerza JSON y normaliza respuesta.

### Helpers

- `ApplicationHelper`:
  - `status_pill`, `ui_date`, `ui_datetime`, `nav_link_to`, `area_nav_items`, mapas OSM helpers.
- Helpers en `app/helpers/admin/*` y `app/helpers/api/*`:
  - existen pero vacíos.

### Concerns

- `app/models/concerns/tenant_scoped.rb`:
  - obligatorio para recursos multitenant.

### `lib/`

- `lib/tasks`: solo `.keep`.
- Tasks custom: **No encontrado en el repo**.

---

## 9. Jobs, mailers, integraciones externas (si existen)

### Background jobs

- `GenerateDailyMenuJob` (cola `critical`): reintento async de generación menú.
- `SyncProductFromBarcodeJob` (cola `default`): refresco producto por barcode.
- `ExpiryAlertsJob` (cola `default`): marca lotes expirados y audita.
- `AuditCleanupJob` (cola `low`): borra logs antiguos (>24 meses).

### Cómo se ejecutan

- Worker local:
  - `bundle exec sidekiq -C config/sidekiq.yml`
- En Heroku/Procfile:
  - proceso `worker` separado.

### Mailers

- Solo `ApplicationMailer` base.
- Emails de negocio concretos: **No encontrado en el repo**.
- Previews de mailers: **No encontrado en el repo**.

### Integraciones externas

- OpenFoodFacts:
  - endpoint: `https://world.openfoodfacts.org/api/v2/product/:barcode.json`
- OpenAI:
  - endpoint: `https://api.openai.com/v1/chat/completions`
  - modelo por `OPENAI_MODEL` (default `gpt-4o-mini`)

### ENV vars relacionadas

- `OPENAI_API_KEY` obligatorio para generación IA real.
- `OPENAI_MODEL` opcional.
- `REDIS_URL` para Sidekiq/ActionCable.
- `APP_HOST` para URLs de mailer en producción.

---

## 10. Testing y calidad (si hay tests)

### Framework

- Minitest (`test/*`).
- Capybara + Selenium instalados.

### Estructura de tests encontrada

- Integración:
  - `test/integration/public_portal_test.rb`
  - `test/integration/admin_metrics_access_test.rb`
  - `test/integration/tenant_api_inventory_test.rb`
  - `test/integration/tenant_menu_generator_page_test.rb`
- Servicios:
  - `test/services/inventory/barcode_lookup_service_test.rb`
  - `test/services/menus/generate_daily_menu_service_test.rb`

### Cómo correr tests

- Todos:
  - `bin/rails test`
- Integración:
  - `bin/rails test test/integration`
- Servicios:
  - `bin/rails test test/services`

### Qué cubren y qué no

- Cubren:
  - acceso admin autorizado/no autorizado
  - portal público básico
  - aislamiento tenant en API inventario
  - fallback de servicio IA
- No cubren ampliamente:
  - todos los controllers/actions
  - policies en detalle exhaustivo
  - jobs en profundidad
  - layout/frontend completo

---

## 11. Cómo ejecutar y desarrollar en local (paso a paso)

### Requisitos

- Ruby `3.3.5`
- PostgreSQL
- Redis
- Bundler

### Setup inicial

1. `bundle install`
2. Configurar `.env` con al menos:
   - `OPENAI_API_KEY` (si usarás IA)
   - `REDIS_URL` (si worker)
3. Crear/preparar BD:
   - `bin/rails db:create db:migrate db:seed`

### Instalar deps

- Script automático:
  - `bin/setup`

### Crear BD / migraciones

- `bin/rails db:prepare`
- `bin/rails db:migrate`

### Seeds

- `bin/rails db:seed`
- Credenciales demo se imprimen al final de seed.

### Arrancar server

- Web:
  - `bin/rails server`
- Worker:
  - `bundle exec sidekiq -C config/sidekiq.yml`

### Troubleshooting común

- Error DB conexión:
  - revisar `config/database.yml` + servicio postgres activo.
- Error Redis:
  - revisar `REDIS_URL` y servicio redis.
- Menú IA no genera:
  - revisar `OPENAI_API_KEY` y logs.
- Redirect inesperado al root:
  - probable fallo de policy/permiso o falta tenant actual.

### Comandos útiles

- Rutas: `bin/rails routes`
- Consola: `bin/rails c`
- Logs dev: `tail -f log/development.log`
- Rehacer BD local rápido:
  - `bin/rails db:drop db:create db:migrate db:seed`

---

## 12. Playbook de cambios (GUÍA PARA NO PROGRAMADORES)

### Receta A: Cambiar una pantalla existente

Checklist:

- [ ] identificar vista exacta (`app/views/...`)
- [ ] cambiar HTML/texto
- [ ] si hay datos nuevos, revisar controller
- [ ] probar en navegador

Ejemplo real: cambiar texto de dashboard tenant.

- Archivo: `app/views/tenant_portal/dashboard/show.html.erb`

### Receta B: Añadir un botón con link a otra pantalla

Checklist:

- [ ] ubicar vista origen
- [ ] añadir `link_to`
- [ ] verificar ruta con `bin/rails routes`

Ejemplo:

```erb
<%= link_to "Ir a alertas", tenant_alerts_expirations_path, class: "btn btn-secondary" %>
```

### Receta C: Añadir nueva página simple (controller + view + ruta)

Checklist:

- [ ] crear ruta en `config/routes.rb`
- [ ] crear controller/action
- [ ] crear vista
- [ ] probar URL

Ejemplo (tenant):

1. Ruta: `get "reports/summary", to: "reports#summary"`
2. Controller: `app/controllers/tenant_portal/reports_controller.rb`
3. Vista: `app/views/tenant_portal/reports/summary.html.erb`

### Receta D: Añadir nuevo modelo CRUD básico

Checklist:

- [ ] generar model+migration
- [ ] migrar DB
- [ ] crear controller CRUD
- [ ] crear vistas CRUD
- [ ] añadir policy Pundit
- [ ] añadir rutas

Base inspirada en `InventoryLot` + `InventoryLotPolicy` + views tenant.

### Receta E: Añadir campo a modelo existente y mostrar en UI

Checklist:

- [ ] migration
- [ ] `permit` en controller
- [ ] input en form
- [ ] mostrar en show/index
- [ ] test/manual QA

Ejemplo de archivos a tocar si campo en `Tenant`:

- `db/migrate/*_add_x_to_tenants.rb`
- `app/controllers/admin/tenants_controller.rb`
- `app/controllers/api/v1/admin/tenants_controller.rb`
- `app/views/admin/tenants/_form.html.erb`
- `app/views/admin/tenants/show.html.erb`

### Receta F: Añadir validación y mensaje de error

Checklist:

- [ ] validación en modelo
- [ ] render de errores en form
- [ ] probar create/update inválido

Ejemplo:

- Modelo: `app/models/product.rb`
- Forms ya muestran errores con `@model.errors.full_messages.join(', ')`.

### Receta G: Añadir filtro/búsqueda básica en listado

Checklist:

- [ ] añadir `data-controller="card-filter"`
- [ ] input con `data-card-filter-target="query"`
- [ ] filas/cards con `data-card-filter-target="card"` y `data-search="..."`

Ejemplos ya implementados:

- `app/views/public/tenants/index.html.erb`
- `app/views/tenant_portal/inventory_lots/index.html.erb`
- `app/views/tenant_portal/menus/index.html.erb`

### Receta H: Añadir permisos/roles

Checklist:

- [ ] identificar recurso policy (`app/policies/*`)
- [ ] cambiar métodos `index?/show?/create?/...`
- [ ] asegurar `authorize` en controller
- [ ] revisar `policy_scope`

Nota:

- Roles actuales reales:
  - Global: `system_admin` (`SystemRole`)
  - Tenant: `tenant_manager`, `tenant_staff` (`Membership`)

### Receta I: Añadir API endpoint JSON

Checklist:

- [ ] añadir ruta bajo `namespace :api do ...`
- [ ] crear acción en controller API
- [ ] usar `render_resource`/`render_collection`/`render_error`
- [ ] añadir authorize/policy_scope
- [ ] test de integración

Referencia:

- `app/controllers/api/v1/tenant/inventory_lots_controller.rb`

### Receta J: Cambiar estilos globales

Checklist:

- [ ] editar variables en `:root`
- [ ] probar áreas public/tenant/admin
- [ ] revisar mobile

Archivo principal:

- `app/assets/stylesheets/application.css`

---

## 13. “Prompts” listos para usar con IA (copiar/pegar)

### Prompt: diseño UI de una vista

```text
Actúa como senior Rails frontend. Modifica SOLO este archivo: app/views/tenant_portal/dashboard/show.html.erb.
Objetivo: mejorar jerarquía visual sin romper funcionalidad existente.
Devuélveme:
1) código completo final del archivo,
2) explicación corta de cambios,
3) pasos de verificación,
4) comando para probar local.
No cambies rutas ni controllers.
```

### Prompt: controller Rails

```text
Necesito añadir una acción nueva en app/controllers/tenant_portal/menus_controller.rb.
Acción: duplicate (duplica un menú existente con fecha nueva).
Devuélveme:
1) archivo completo actualizado,
2) ruta exacta a añadir en config/routes.rb,
3) validaciones/errores,
4) pasos de verificación y comando de prueba.
Incluye authorize/policy_scope donde aplique.
```

### Prompt: migration

```text
Genera una migration para añadir el campo notes_internal:text a la tabla inventory_lots.
Además indícame exactamente qué tocar en:
- app/controllers/tenant_portal/inventory_lots_controller.rb (strong params)
- app/views/tenant_portal/inventory_lots/_form.html.erb
- app/views/tenant_portal/inventory_lots/show.html.erb
Devuélveme código completo de cada archivo modificado + comandos de migración y verificación.
```

### Prompt: relaciones de modelo

```text
Quiero crear un modelo Supplier relacionado con Tenant y Product.
Usa este repo real y propón implementación mínima compatible con Pundit y rutas tenant/admin.
Devuélveme:
1) migration(s) completas,
2) modelos completos,
3) policy nueva,
4) rutas exactas,
5) controllers mínimos,
6) test básico.
Incluye comandos exactos para ejecutar y verificar.
```

### Prompt: debugging

```text
Tengo error 403 (No autorizado) al entrar en /tenant/inventory_lots.
Analiza este repo y dime exactamente:
1) posibles causas en policies/controllers,
2) archivos concretos a revisar,
3) cambios mínimos sugeridos con diffs,
4) comandos para reproducir y verificar fix.
No inventes archivos inexistentes.
```

### Prompt: rutas

```text
Necesito añadir ruta GET /tenant/reports/summary en este repo.
Dime exactamente qué líneas agregar en config/routes.rb y qué archivo controller/view crear.
Devuélveme código completo de los archivos nuevos y checklist de prueba manual.
```

### Prompt: tests

```text
Escribe tests Minitest para este repo (no RSpec).
Objetivo: cubrir create/update de TenantPortal::InventoryLotsController con usuario autorizado.
Indica archivo exacto de test, código completo y datos mínimos de setup.
Incluye comando exacto para ejecutar solo ese test.
```

---

## 14. Checklist final para el hackathon

### Antes de PR/merge

- [ ] `git status` limpio (o cambios esperados)
- [ ] rutas nuevas visibles en `bin/rails routes`
- [ ] migraciones corren ok
- [ ] flujo principal manual probado
- [ ] permisos Pundit revisados
- [ ] no hay secretos hardcodeados

### Comandos a correr

- `bin/rails test`
- `bin/rails routes`
- `bin/rails db:migrate`
- `bundle exec sidekiq -C config/sidekiq.yml` (si tocaste jobs)

### Qué mirar en logs

- `log/development.log`
- errores de autorización (`Pundit::NotAuthorizedError`)
- errores integración (`openai_error`, timeouts Faraday)
- errores sidekiq/redis

### Cómo revertir cambios

- Revertir archivo puntual:
  - `git restore path/al/archivo`
- Revertir commit sin romper historial compartido:
  - `git revert <sha>`
- Revertir migración reciente:
  - `bin/rails db:rollback`

---

## Apéndice útil: dónde tocar cada cosa (rápido)

- Login/sesión: `app/views/devise/sessions/new.html.erb`, `app/models/user.rb`
- Selección tenant actual: `app/controllers/application_controller.rb`, `app/services/tenancy/tenant_switch_service.rb`
- Inventario: `app/controllers/tenant_portal/inventory_lots_controller.rb`, `app/models/inventory_lot.rb`, `app/views/tenant_portal/inventory_lots/*`
- Escaneo barcode: `app/controllers/tenant_portal/scans_controller.rb`, `app/services/inventory/barcode_lookup_service.rb`, `app/javascript/controllers/barcode_scanner_controller.js`
- Menú IA: `app/services/menus/generate_daily_menu_service.rb`, `app/controllers/tenant_portal/menus_controller.rb`, `app/views/tenant_portal/menus/generate.html.erb`
- API tenant inventory: `app/controllers/api/v1/tenant/inventory_lots_controller.rb`
- Permisos: `app/policies/*`
- Auditoría: `app/models/audit_log.rb`, `app/services/audit_logger.rb`, `app/views/admin/audit_logs/index.html.erb`
- Admin usuarios: `app/controllers/admin/users_controller.rb`, `app/views/admin/users/*`
- Estilos globales: `app/assets/stylesheets/application.css`

