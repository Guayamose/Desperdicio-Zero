# Carga el panel web de Sidekiq (cola de trabajos en segundo plano).
# Esto NO define rutas de tu app de negocio, solo permite ver/gestionar jobs.
require "sidekiq/web"

# Todo lo que va dentro de este bloque son rutas HTTP de Rails.
# Aqui se decide:
# - que URL existe
# - que metodo HTTP usa (GET, POST, PATCH, DELETE...)
# - que controller#accion la atiende
Rails.application.routes.draw do
  # Devise genera automaticamente rutas de autenticacion para User:
  # /users/sign_in, /users/sign_out, password reset, etc.
  devise_for :users

  # Endpoint de healthcheck para plataformas (renderiza estado de la app).
  # Ejemplo de uso: GET /up
  # "as: :rails_health_check" crea el helper rails_health_check_path.
  get "up" => "rails/health#show", as: :rails_health_check

  # Pagina principal de la web (GET /).
  root "public/home#show"

  # --------------------------------------------------------------------------
  # ZONA PUBLICA WEB (sin prefijo /public en la URL)
  # --------------------------------------------------------------------------
  # "scope module: :public" significa:
  # - URL: no agrega prefijo extra
  # - Controller: busca dentro de app/controllers/public/*
  scope module: :public do
    # resources :tenants crea rutas REST para "tenants".
    # only: limita a index + show para no abrir create/update/destroy.
    # param: :slug usa slug en vez de id en la URL.
    # path: "comedores" cambia la URL publica (/comedores en lugar de /tenants).
    # as: :public_tenants cambia el prefijo de helpers:
    #   public_tenants_path, public_tenant_path(...)
    resources :tenants, only: [ :index, :show ], param: :slug, path: "comedores", as: :public_tenants

    # Ruta custom para menu del dia de un comedor por slug.
    # :slug es un segmento dinamico en la URL.
    # Helper generado: public_tenant_menu_today_path(slug: ...)
    get "comedores/:slug/menu-today", to: "menus#today", as: :public_tenant_menu_today

    get "politica-de-privacidad", to: "home#privacy", as: :privacy_policy
  end

  # Redirecciones por compatibilidad con rutas viejas.
  # Si alguien entra a URL antigua, lo mandamos al nuevo listado publico.
  get "/public/tenants", to: redirect("/comedores")
  get "/public/comedores", to: redirect("/comedores")

  # --------------------------------------------------------------------------
  # ZONA WEB INTERNA DEL TENANT (panel de comedor)
  # --------------------------------------------------------------------------
  # scope con:
  # - module: :tenant_portal -> controllers en app/controllers/tenant_portal/*
  # - path: "tenant"          -> URL empieza por /tenant
  # - as: :tenant             -> helpers empiezan por tenant_*
  scope module: :tenant_portal, path: "tenant", as: :tenant do
    # Cambiar comedor activo en sesion.
    # tenant_id es dinamico en la URL.
    # Helper: tenant_switch_path(tenant_id)
    post "switch/:tenant_id", to: "sessions#switch", as: :switch

    # resource (singular) para dashboard:
    # usa /tenant/dashboard sin :id porque hay uno "actual" por sesion.
    resource :dashboard, only: [ :show ], controller: :dashboard

    # CRUD completo de lotes de inventario:
    # index, show, new, create, edit, update, destroy
    resources :inventory_lots

    # Escaneo: solo formulario + creacion.
    resources :scans, only: [ :new, :create ]

    # Menus internos.
    resources :menus, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
      # member = opera sobre un menu concreto (requiere :id en URL)
      # POST /tenant/menus/:id/publish
      post :publish, on: :member

      # collection = opera sobre el conjunto de menus (sin :id)
      # GET /tenant/menus/generate  -> pantalla previa
      # POST /tenant/menus/generate -> ejecutar generacion
      get :generate, on: :collection
      post :generate, on: :collection
    end

    # Vista de alertas de caducidad.
    # Helper: tenant_alerts_expirations_path
    get "alerts/expirations", to: "alerts#expirations", as: :alerts_expirations

    # Empleados del comedor (solo tenant_manager).
    resources :employees, only: [ :index, :new, :create, :update, :destroy ]

    # Perfil del usuario autenticado.
    resource :profile, only: [ :show, :edit, :update ], controller: :profile
    # Cambio de contraseña obligatorio en primer login.
    # GET /tenant/password/edit -> edit_tenant_password_path
    # PATCH /tenant/password    -> tenant_password_path
    resource :password, only: [ :edit, :update ], controller: :passwords
  end

  # --------------------------------------------------------------------------
  # ZONA WEB ADMIN GLOBAL
  # --------------------------------------------------------------------------
  # namespace :admin hace dos cosas:
  # - URL: agrega /admin
  # - Controller: busca en app/controllers/admin/*
  # - Helpers: prefijo admin_*
  namespace :admin do
    # Landing del panel admin (placeholder inicial).
    root to: "dashboard#show"
    resource :dashboard, only: [ :show ], controller: :dashboard

    # CRUD completo de tenants para admin global.
    resources :tenants

    # Usuarios admin: sin edit/update/destroy (solo flujos definidos).
    resources :users, only: [ :index, :show, :new, :create ] do
      # Acciones custom por usuario (requieren :id).
      patch :block, on: :member
      patch :anonymize, on: :member
      get :export, on: :member
    end

    # Metricas globales (singular porque es una sola pantalla).
    resource :metrics, only: [ :show ]

    # Auditoria solo lectura desde panel admin.
    resources :audit_logs, only: [ :index ]

    # Inventario global: vista cross-tenant agrupada por comedor.
    resource :inventory, only: [ :show ]
  end

  # --------------------------------------------------------------------------
  # API JSON
  # --------------------------------------------------------------------------
  namespace :api do
    # Versionado de API: /api/v1/...
    # Cuando llegue v2, convive sin romper clientes viejos.
    namespace :v1 do
      # --------------------------
      # API PUBLICA
      # --------------------------
      namespace :public do
        # Listado + detalle de tenants publicos por slug.
        resources :tenants, only: [ :index, :show ], param: :slug do
          # GET /api/v1/public/tenants/:slug/menu-today
          # "on: :member" porque aplica a un tenant concreto.
          get "menu-today", action: :menu_today, on: :member
        end
      end

      # --------------------------
      # API TENANT (requiere usuario autenticado y tenant activo)
      # --------------------------
      namespace :tenant do
        # Agrupamos endpoints de inventario bajo /inventory/*
        scope :inventory do
          # Usamos path /lots pero controller inventory_lots.
          resources :lots, controller: "inventory_lots", only: [ :index, :create, :update, :destroy ]

          # Endpoint de escaneo de codigo de barras.
          post :scan, to: "scans#create"
          post :barcode_check, to: "scans#barcode_check"
        end

        # Alertas de caducidad.
        get "alerts/expirations", to: "alerts#expirations"

        # Generar menu IA.
        post "menus/generate", to: "menus#generate"

        # Leer menu por fecha en la URL.
        # Helper: api_v1_tenant_menu_by_date_path(date: ...)
        get "menus/:date", to: "menus#show", as: :menu_by_date

        # Editar y publicar menu por id.
        patch "menus/:id", to: "menus#update"
        post "menus/:id/publish", to: "menus#publish"
      end

      # --------------------------
      # API ADMIN GLOBAL
      # --------------------------
      namespace :admin do
        # Tenants por API: sin show (solo listado + escritura basica).
        resources :tenants, only: [ :index, :create, :update, :destroy ]

        # Usuarios por API: creacion y acciones puntuales por id.
        resources :users, only: [ :create ] do
          patch :block, on: :member
          get :export, on: :member
        end

        # Metricas y auditoria por API.
        get :metrics, to: "metrics#show"
        get "audit-logs", to: "audit_logs#index"
      end
    end
  end

  # Monta panel web de Sidekiq en /sidekiq SOLO en development.
  # Evita exponer esta interfaz sensible en produccion por defecto.
  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?
end
