require "cgi"

module ApplicationHelper
  PLACEHOLDER_IMAGES = [
    "placeholders/kitchen-01.svg",
    "placeholders/kitchen-02.svg",
    "placeholders/kitchen-03.svg",
    "placeholders/kitchen-04.svg"
  ].freeze

  STATUS_CLASS_MAP = {
    "active" => "status-positive",
    "available" => "status-positive",
    "published" => "status-positive",
    "succeeded" => "status-positive",
    "tenant_manager" => "status-positive",
    "system_admin" => "status-positive",
    "compatible" => "status-positive",
    "variety" => "status-positive",

    "draft" => "status-neutral",
    "queued" => "status-neutral",
    "running" => "status-neutral",
    "reserved" => "status-neutral",
    "balanced" => "status-neutral",
    "batch" => "status-neutral",

    "inactive" => "status-warning",
    "fallback_manual" => "status-warning",
    "needs_review" => "status-warning",

    "suspended" => "status-danger",
    "discarded" => "status-danger",
    "expired" => "status-danger",
    "failed" => "status-danger",
    "blocked" => "status-danger",
    "archived" => "status-danger",
    "not_compatible" => "status-danger"
  }.freeze

  def status_pill(value)
    label = value.to_s.tr("_", " ").capitalize
    klass = STATUS_CLASS_MAP.fetch(value.to_s, "status-neutral")

    content_tag(:span, label, class: "status-pill #{klass}")
  end

  def yes_no(value)
    value ? "Si" : "No"
  end

  def present_or_dash(value)
    value.present? ? value : "-"
  end

  def ui_date(value)
    return "-" if value.blank?

    l(value.to_date)
  rescue StandardError
    value.to_s
  end

  def ui_datetime(value)
    return "-" if value.blank?

    l(value, format: :short)
  rescue StandardError
    value.to_s
  end

  def nav_link_to(label_or_path = nil, path = nil, **options, &block)
    if block_given?
      path = label_or_path
      classes = ["nav-link", options.delete(:class)]
      classes << "is-active" if current_page?(path)
      link_to(path, **options.merge(class: classes.compact.join(" ")), &block)
    else
      classes = ["nav-link", options.delete(:class)]
      classes << "is-active" if current_page?(path)
      link_to(label_or_path, path, **options.merge(class: classes.compact.join(" ")))
    end
  end

  def current_area
    return :admin if controller_path.start_with?("admin/")
    return :tenant if controller_path.start_with?("tenant_portal/")

    :public
  end

  def current_area_label
    case current_area
    when :admin then "Administración Global"
    when :tenant then "Panel del Comedor"
    else "Portal Público"
    end
  end

  def area_nav_items
    case current_area
    when :admin
      [
        [ "Metricas", admin_metrics_path ],
        [ "Comedores", admin_tenants_path ],
        [ "Usuarios", admin_users_path ],
        [ "Auditoria", admin_audit_logs_path ]
      ]
    when :tenant
      return [] unless current_tenant

      [
        [ "Resumen", tenant_dashboard_path ],
        [ "Inventario", tenant_inventory_lots_path ],
        [ "Escaneo", new_tenant_scan_path ],
        [ "Menús", tenant_menus_path ],
        [ "Generador IA", generate_tenant_menus_path(date: Date.current) ],
        [ "Alertas", tenant_alerts_expirations_path ]
      ]
    else
      []
    end
  end

  def area_nav_link_to(label, path)
    active = current_page?(path)
    classes = [ "section-link", ("is-active" if active) ].compact.join(" ")
    link_to(label, path, class: classes)
  end

  def tenant_placeholder_image(tenant, **options)
    image_tag(placeholder_image_for(tenant), { alt: "Imagen de referencia del comedor" }.merge(options))
  end

  def map_placeholder_image(**options)
    image_tag("placeholders/map-placeholder.svg", { alt: "Mapa de referencia" }.merge(options))
  end

  def tenant_map_embed_url(tenant, delta: 0.02)
    return nil if tenant.latitude.blank? || tenant.longitude.blank?

    lat = tenant.latitude.to_f
    lon = tenant.longitude.to_f
    bbox = [ lon - delta, lat - delta, lon + delta, lat + delta ].join(",")

    "https://www.openstreetmap.org/export/embed.html?bbox=#{CGI.escape(bbox)}&layer=mapnik&marker=#{lat},#{lon}"
  end

  def tenant_map_link(tenant)
    return nil if tenant.latitude.blank? || tenant.longitude.blank?

    "https://www.openstreetmap.org/?mlat=#{tenant.latitude}&mlon=#{tenant.longitude}#map=14/#{tenant.latitude}/#{tenant.longitude}"
  end

  private

  def placeholder_image_for(tenant)
    seed = tenant.id || tenant.slug.to_s.each_byte.sum
    PLACEHOLDER_IMAGES[seed % PLACEHOLDER_IMAGES.length]
  end
end
