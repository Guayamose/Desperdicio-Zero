require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  root "public/home#show"

  scope module: :public do
    resources :tenants, only: [ :index, :show ], param: :slug, path: "comedores", as: :public_tenants
    get "comedores/:slug/menu-today", to: "menus#today", as: :public_tenant_menu_today
  end

  # Redirect old paths to the new intuitive ones
  get "/public/tenants", to: redirect("/comedores")
  get "/public/comedores", to: redirect("/comedores")

  scope module: :tenant_portal, path: "tenant", as: :tenant do
    post "switch/:tenant_id", to: "sessions#switch", as: :switch

    resource :dashboard, only: [ :show ], controller: :dashboard
    resources :inventory_lots
    resources :scans, only: [ :new, :create ]
    resources :menus, only: [ :index, :show, :new, :create, :edit, :update ] do
      post :publish, on: :member
      get :generate, on: :collection
      post :generate, on: :collection
    end
    get "alerts/expirations", to: "alerts#expirations", as: :alerts_expirations
  end

  namespace :admin do
    resources :tenants
    resources :users, only: [ :index, :show, :new, :create ] do
      patch :block, on: :member
      patch :anonymize, on: :member
      get :export, on: :member
    end
    resource :metrics, only: [ :show ]
    resources :audit_logs, only: [ :index ]
  end

  namespace :api do
    namespace :v1 do
      namespace :public do
        resources :tenants, only: [ :index, :show ], param: :slug do
          get "menu-today", action: :menu_today, on: :member
        end
      end

      namespace :tenant do
        scope :inventory do
          resources :lots, controller: "inventory_lots", only: [ :index, :create, :update, :destroy ]
          post :scan, to: "scans#create"
        end

        get "alerts/expirations", to: "alerts#expirations"
        post "menus/generate", to: "menus#generate"
        get "menus/:date", to: "menus#show", as: :menu_by_date
        patch "menus/:id", to: "menus#update"
        post "menus/:id/publish", to: "menus#publish"
      end

      namespace :admin do
        resources :tenants, only: [ :index, :create, :update, :destroy ]
        resources :users, only: [ :create ] do
          patch :block, on: :member
          get :export, on: :member
        end
        get :metrics, to: "metrics#show"
        get "audit-logs", to: "audit_logs#index"
      end
    end
  end

  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?
end
