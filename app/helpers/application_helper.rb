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

  ALLERGEN_ICON_FILES = {
    gluten: "Icons/CerealesConGluten.webp",
    crustaceos: "Icons/Crustaceos.webp",
    huevos: "Icons/Huevos.webp",
    pescado: "Icons/Pescado.webp",
    cacahuetes: "Icons/Cacahuetes.webp",
    soja: "Icons/Soja.webp",
    lacteos: "Icons/Lacteos.webp",
    frutos_de_cascara: "Icons/FrutosDeCascara.webp",
    apio: "Icons/Apio.webp",
    mostaza: "Icons/Mostaza.webp",
    sesamo: "Icons/GranosSesamo.webp",
    sulfitos: "Icons/DioxidoDeAzufreYSulfatos.webp",
    altramuces: "Icons/Altramuces.webp",
    moluscos: "Icons/Moluscos.webp"
  }.freeze

  OPERATING_DAYS_LABELS = {
    "lunes" => "Lunes",
    "martes" => "Martes",
    "miercoles" => "Miercoles",
    "jueves" => "Jueves",
    "viernes" => "Viernes",
    "sabado" => "Sabado",
    "domingo" => "Domingo"
  }.freeze

  def status_pill(value)
    label = value.to_s.tr("_", " ").capitalize
    klass = STATUS_CLASS_MAP.fetch(value.to_s, "status-neutral")

    content_tag(:span, label, class: "status-pill #{klass}")
  end

  def yes_no(value)
    value ? "Si" : "No"
  end

  def allergen_badges(allergens, empty: nil, wrapper_class: "allergen-badge-group")
    values = Array(allergens).map { |item| item.to_s.strip }.reject(&:blank?)
    return content_tag(:span, empty, class: "muted") if values.empty? && empty.present?
    return content_tag(:span, "Ninguno", class: "muted") if values.empty?

    content_tag(:div, class: wrapper_class) do
      safe_join(values.map { |allergen| allergen_badge(allergen) })
    end
  end

  def allergen_icon_asset_map
    ALLERGEN_ICON_FILES.transform_values { |asset_name| asset_path(asset_name) }
  end

  def operating_days_labels
    OPERATING_DAYS_LABELS
  end

  def operating_hours_rows(raw_hours)
    hours = raw_hours.is_a?(Hash) ? raw_hours : {}
    normalized = hours
      .to_h
      .transform_keys(&:to_s)
      .transform_values { |value| value.to_s.strip }
      .reject { |_day, value| value.blank? }

    ordered_days = OPERATING_DAYS_LABELS.keys.select { |day| normalized.key?(day) }
    extra_days = (normalized.keys - OPERATING_DAYS_LABELS.keys).sort

    (ordered_days + extra_days).map do |day|
      [ OPERATING_DAYS_LABELS.fetch(day, day.humanize), normalized.fetch(day) ]
    end
  end

  def operating_hours_summary(raw_hours)
    rows = operating_hours_rows(raw_hours)
    return "Horario no disponible" if rows.empty?

    day, period = rows.first
    "#{day}: #{period}"
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

      items = [
        [ "Resumen", tenant_dashboard_path ],
        [ "Inventario", tenant_inventory_lots_path ],
        [ "Escaneo", new_tenant_scan_path ],
        [ "Menús", tenant_menus_path ],
        [ "Generador IA", generate_tenant_menus_path(date: Date.current) ],
        [ "Alertas", tenant_alerts_expirations_path ]
      ]
      items << [ "Empleados", tenant_employees_path ] if current_user&.tenant_manager_in?(current_tenant)
      items
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

  def sort_link(name, column, **options)
    is_active = column.to_s == params[:sort]
    direction = is_active && (params[:direction] == "asc") ? "desc" : "asc"
    
    if is_active
      if params[:direction] == "desc"
        svg = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="margin-left: 0.25rem;"><polyline points="6 9 12 15 18 9"></polyline></svg>'
      else
        svg = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="margin-left: 0.25rem;"><polyline points="18 15 12 9 6 15"></polyline></svg>'
      end
    else
      svg = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="margin-left: 0.25rem; opacity: 0.3;"><polyline points="7 15 12 20 17 15"></polyline><polyline points="7 9 12 4 17 9"></polyline></svg>'
    end
    
    icon = raw(svg)
    
    default_options = { 
      style: "color: inherit; text-decoration: none; display: inline-flex; align-items: center;",
      data: { turbo_action: "replace" }
    }
    
    query = request.query_parameters.merge(sort: column, direction: direction)
    link_to(query, **default_options.merge(options)) do
      safe_join([name, icon])
    end
  end

  private

  def allergen_badge(allergen)
    icon_path = allergen_icon_path(allergen)
    classes = [ "allergen-badge" ]
    classes << "allergen-badge-text-only" if icon_path.blank?

    content_tag(:span, class: classes.join(" "), title: allergen) do
      parts = []
      if icon_path.present?
        parts << image_tag(icon_path, alt: "Icono alergeno #{allergen}", class: "allergen-icon", loading: "lazy")
      end
      parts << content_tag(:span, allergen, class: "allergen-label")
      safe_join(parts)
    end
  end

  def allergen_icon_path(allergen)
    key = allergen_icon_key(allergen)
    return nil if key.blank?

    asset_path(ALLERGEN_ICON_FILES.fetch(key))
  end

  def allergen_icon_key(allergen)
    normalized = normalize_allergen_name(allergen)
    return :gluten if normalized.match?(/\b(gluten|trigo|cebada|centeno|avena|espelta|kamut)\b/)
    return :crustaceos if normalized.match?(/crustace|crustacean|shrimp|prawn/)
    return :huevos if normalized.match?(/huevo|egg/)
    return :pescado if normalized.match?(/pescado|fish/)
    return :cacahuetes if normalized.match?(/\b(cacahuete|cacahuetes|mani|peanut|peanuts)\b/)
    return :soja if normalized.match?(/soja|soy/)
    return :lacteos if normalized.match?(/\b(lacteo|lacteos|lactosa|leche|milk)\b/)
    return :frutos_de_cascara if normalized.match?(/frutos?\s+(de\s+)?cascara|frutos?\s+secos|nueces?|tree\s+nuts?/)
    return :apio if normalized.match?(/apio|celery/)
    return :mostaza if normalized.match?(/mostaza|mustard/)
    return :sesamo if normalized.match?(/sesamo|sesame/)
    return :sulfitos if normalized.match?(/sulfit|sulfat|dioxido\s+de\s+azufre|sulfur\s+dioxide/)
    return :altramuces if normalized.match?(/altramuz|altramuces|lupin/)
    return :moluscos if normalized.match?(/molusco|mollusc|mollusk/)

    nil
  end

  def normalize_allergen_name(value)
    I18n.transliterate(value.to_s).downcase.gsub(/[^a-z0-9]+/, " ").strip
  end

  def placeholder_image_for(tenant)
    seed = tenant.id || tenant.slug.to_s.each_byte.sum
    PLACEHOLDER_IMAGES[seed % PLACEHOLDER_IMAGES.length]
  end
end
