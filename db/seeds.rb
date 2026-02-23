# frozen_string_literal: true

puts "== Social Kitchen seed: start =="

SEED_PROMPT_VERSION = "seed_v2".freeze
DEFAULT_PASSWORD = "ChangeMe123!".freeze

DAYS_ORDER = %w[lunes martes miercoles jueves viernes sabado domingo].freeze

OPERATING_HOURS = {
  "lunes" => "08:00-16:00",
  "martes" => "08:00-16:00",
  "miercoles" => "08:00-16:00",
  "jueves" => "08:00-16:00",
  "viernes" => "08:00-16:00",
  "sabado" => "09:00-14:00",
  "domingo" => "cerrado"
}.freeze

TENANTS_DATA = [
  {
    slug: "comedor-central",
    name: "Comedor Central",
    status: :active,
    address: "Calle Mayor 123",
    city: "Madrid",
    region: "Madrid",
    country: "ES",
    latitude: 40.416775,
    longitude: -3.70379,
    contact_email: "central@socialkitchen.local",
    contact_phone: "+34 900 100 201"
  },
  {
    slug: "comedor-rio",
    name: "Comedor Rio",
    status: :active,
    address: "Av. del Rio 45",
    city: "Sevilla",
    region: "Andalucia",
    country: "ES",
    latitude: 37.389092,
    longitude: -5.984459,
    contact_email: "rio@socialkitchen.local",
    contact_phone: "+34 900 100 202"
  },
  {
    slug: "comedor-marina",
    name: "Comedor Marina",
    status: :active,
    address: "Passeig de la Marina 10",
    city: "Valencia",
    region: "Comunidad Valenciana",
    country: "ES",
    latitude: 39.469907,
    longitude: -0.376288,
    contact_email: "marina@socialkitchen.local",
    contact_phone: "+34 900 100 203"
  },
  {
    slug: "comedor-norte",
    name: "Comedor Norte",
    status: :active,
    address: "Calle del Puerto 88",
    city: "Bilbao",
    region: "Pais Vasco",
    country: "ES",
    latitude: 43.263012,
    longitude: -2.934985,
    contact_email: "norte@socialkitchen.local",
    contact_phone: "+34 900 100 204"
  },
  {
    slug: "comedor-huerta",
    name: "Comedor Huerta",
    status: :inactive,
    address: "Camino de la Huerta 17",
    city: "Murcia",
    region: "Region de Murcia",
    country: "ES",
    latitude: 37.992239,
    longitude: -1.130654,
    contact_email: "huerta@socialkitchen.local",
    contact_phone: "+34 900 100 205"
  }
].freeze

PRODUCTS_DATA = [
  { barcode: "8411111111111", name: "Arroz integral", brand: "Solidario", category: "granos", allergens_json: ["gluten"] },
  { barcode: "8411111111112", name: "Lentejas", brand: "Solidario", category: "legumbres", allergens_json: [] },
  { barcode: "8411111111113", name: "Garbanzos", brand: "Solidario", category: "legumbres", allergens_json: [] },
  { barcode: "8411111111114", name: "Pasta", brand: "Comedor+", category: "granos", allergens_json: ["gluten"] },
  { barcode: "8411111111115", name: "Tomate triturado", brand: "Huerta Viva", category: "conserva", allergens_json: [] },
  { barcode: "8411111111116", name: "Atun en conserva", brand: "Mar Azul", category: "proteina", allergens_json: ["pescado"] },
  { barcode: "8411111111117", name: "Pollo troceado", brand: "Campo Fresco", category: "proteina", allergens_json: [] },
  { barcode: "8411111111118", name: "Huevos", brand: "Granja Norte", category: "proteina", allergens_json: ["huevo"] },
  { barcode: "8411111111119", name: "Leche", brand: "Lactea", category: "lacteos", allergens_json: ["lactosa"] },
  { barcode: "8411111111120", name: "Yogur natural", brand: "Lactea", category: "lacteos", allergens_json: ["lactosa"] },
  { barcode: "8411111111121", name: "Pan integral", brand: "Horno Social", category: "panaderia", allergens_json: ["gluten"] },
  { barcode: "8411111111122", name: "Zanahoria", brand: "Huerta Viva", category: "verdura", allergens_json: [] },
  { barcode: "8411111111123", name: "Cebolla", brand: "Huerta Viva", category: "verdura", allergens_json: [] },
  { barcode: "8411111111124", name: "Patata", brand: "Huerta Viva", category: "verdura", allergens_json: [] },
  { barcode: "8411111111125", name: "Aceite de oliva", brand: "Cooperativa Sur", category: "aceites", allergens_json: [] },
  { barcode: "8411111111126", name: "Manzana", brand: "Fruta Norte", category: "fruta", allergens_json: [] }
].freeze

MENU_BASES = [
  {
    title: "Menu mediterraneo solidario",
    description: "Propuesta equilibrada con prioridad en ingredientes cercanos a caducidad.",
    items: [
      { name: "Lentejas estofadas", ingredients: ["lentejas", "zanahoria", "cebolla"], allergens: [] },
      { name: "Arroz con verduras", ingredients: ["arroz integral", "tomate triturado", "cebolla"], allergens: ["gluten"] },
      { name: "Fruta de temporada", ingredients: ["manzana"], allergens: [] }
    ]
  },
  {
    title: "Menu proteico de aprovechamiento",
    description: "Menu orientado a aprovechar lotes donados de proteina y verdura fresca.",
    items: [
      { name: "Pollo guisado", ingredients: ["pollo troceado", "patata", "zanahoria"], allergens: [] },
      { name: "Ensalada de garbanzos", ingredients: ["garbanzos", "tomate triturado", "cebolla"], allergens: [] },
      { name: "Yogur natural", ingredients: ["yogur natural"], allergens: ["lactosa"] }
    ]
  },
  {
    title: "Menu rapido comunitario",
    description: "Formato sencillo para servicios con alta demanda en horario punta.",
    items: [
      { name: "Pasta con atun", ingredients: ["pasta", "atun en conserva", "tomate triturado"], allergens: ["gluten", "pescado"] },
      { name: "Tortilla de patata", ingredients: ["huevos", "patata", "cebolla"], allergens: ["huevo"] },
      { name: "Pan integral", ingredients: ["pan integral"], allergens: ["gluten"] }
    ]
  }
].freeze

def upsert_user!(email:, full_name:, locale: "es", blocked: false)
  user = User.find_or_initialize_by(email: email)
  user.full_name = full_name
  user.locale = locale
  user.gdpr_consent_at ||= Time.current
  user.password = DEFAULT_PASSWORD
  user.password_confirmation = DEFAULT_PASSWORD
  user.blocked_at = blocked ? (user.blocked_at || Time.current) : nil
  user.save!
  user
end

def upsert_tenant!(attrs)
  tenant = Tenant.find_or_initialize_by(slug: attrs.fetch(:slug))
  tenant.assign_attributes(attrs.merge(operating_hours_json: OPERATING_HOURS))
  tenant.save!
  tenant
end

def upsert_product!(attrs)
  product = Product.find_or_initialize_by(barcode: attrs.fetch(:barcode))
  product.assign_attributes(
    name: attrs.fetch(:name),
    brand: attrs[:brand],
    category: attrs[:category],
    ingredients_text: attrs[:ingredients_text] || attrs.fetch(:name),
    allergens_json: attrs[:allergens_json] || [],
    nutrition_json: attrs[:nutrition_json] || { "kcal_100g" => rand(50..260) },
    source: :manual,
    last_synced_at: Time.current
  )
  product.save!
  product
end

ActiveRecord::Base.transaction do
  srand(17)

  puts "Cleaning previous seed traces..."
  MenuGeneration.where(prompt_version: SEED_PROMPT_VERSION).delete_all
  AuditLog.where("action LIKE 'seed.%'").delete_all

  puts "Creating global users..."
  admin = upsert_user!(email: "admin@socialkitchen.local", full_name: "System Admin")
  ops_admin = upsert_user!(email: "ops-admin@socialkitchen.local", full_name: "Operations Admin")
  blocked_user = upsert_user!(email: "blocked.user@socialkitchen.local", full_name: "Blocked User", blocked: true)

  [admin, ops_admin].each do |user|
    SystemRole.find_or_create_by!(user: user, role: :system_admin)
  end

  puts "Creating tenants..."
  tenants = TENANTS_DATA.map { |attrs| upsert_tenant!(attrs) }

  puts "Creating products catalog..."
  products = PRODUCTS_DATA.map { |attrs| upsert_product!(attrs) }

  puts "Creating tenant users, memberships and operations data..."
  tenants.each_with_index do |tenant, index|
    manager = upsert_user!(
      email: "manager+#{tenant.slug}@socialkitchen.local",
      full_name: "Manager #{tenant.name}"
    )

    staff_a = upsert_user!(
      email: "staff-a+#{tenant.slug}@socialkitchen.local",
      full_name: "Staff A #{tenant.name}"
    )

    staff_b = upsert_user!(
      email: "staff-b+#{tenant.slug}@socialkitchen.local",
      full_name: "Staff B #{tenant.name}"
    )

    [
      [manager, :tenant_manager],
      [staff_a, :tenant_staff],
      [staff_b, :tenant_staff]
    ].each do |user, role|
      membership = Membership.find_or_initialize_by(user: user, tenant: tenant)
      membership.role = role
      membership.active = true
      membership.save!
    end

    Membership.find_or_create_by!(user: blocked_user, tenant: tenant) do |membership|
      membership.role = :tenant_staff
      membership.active = false
    end

    tenant_products = products.rotate(index * 3).first(8)
    expiry_offsets = [ -2, -1, 1, 2, 4, 7, 12, 20 ]

    tenant_products.each_with_index do |product, lot_index|
      expires_on = Date.current + expiry_offsets[lot_index]
      received_on = [Date.current - 3.days, expires_on - 10.days].max
      source = lot_index.even? ? :donation : :purchase
      quantity = rand(4.0..25.0).round(2)

      lot = InventoryLot.find_or_initialize_by(
        tenant: tenant,
        product: product,
        expires_on: expires_on,
        source: source
      )

      lot.assign_attributes(
        quantity: quantity,
        unit: %i[kg g l ml unit].sample,
        status: expires_on < Date.current ? :expired : (lot_index % 5 == 0 ? :reserved : :available),
        received_on: received_on,
        notes: "Seed lote #{lot_index + 1} para #{tenant.slug}"
      )
      lot.save!

      StockMovement.find_or_create_by!(
        tenant: tenant,
        inventory_lot: lot,
        movement_type: :inbound,
        quantity_delta: quantity,
        reason: "seed_stock_in",
        occurred_at: received_on.to_time.change(hour: 10),
        performed_by: manager
      )

      if lot.status == "expired"
        StockMovement.find_or_create_by!(
          tenant: tenant,
          inventory_lot: lot,
          movement_type: :waste,
          quantity_delta: -quantity,
          reason: "seed_expired",
          occurred_at: expires_on.to_time.change(hour: 8),
          performed_by: staff_a
        )
      elsif lot_index % 3 == 0
        consumed_qty = (quantity * 0.4).round(2)
        StockMovement.find_or_create_by!(
          tenant: tenant,
          inventory_lot: lot,
          movement_type: :outbound,
          quantity_delta: -consumed_qty,
          reason: "seed_consumption",
          occurred_at: Date.current.to_time.change(hour: 13),
          performed_by: staff_b
        )
      end
    end

    [Date.yesterday, Date.current, Date.tomorrow].each_with_index do |menu_date, menu_index|
      menu_template = MENU_BASES[(index + menu_index) % MENU_BASES.length]
      status = if menu_date < Date.current
                 :archived
               elsif menu_date == Date.current
                 (index.even? ? :published : :draft)
               else
                 :draft
               end

      menu = DailyMenu.find_or_initialize_by(tenant: tenant, menu_date: menu_date)
      menu.assign_attributes(
        title: "#{menu_template[:title]} (#{tenant.city})",
        description: menu_template[:description],
        allergens_json: menu_template[:items].flat_map { |i| i[:allergens] }.uniq,
        status: status,
        generated_by: (menu_index.even? ? :ai : :manual),
        created_by: manager
      )
      menu.save!

      menu.daily_menu_items.destroy_all
      menu_template[:items].each_with_index do |item, position|
        menu.daily_menu_items.create!(
          name: item[:name],
          description: "Servicio #{menu_date == Date.current ? 'actual' : 'programado'} para #{tenant.name}",
          position: position,
          ingredients_json: item[:ingredients],
          allergens_json: item[:allergens]
        )
      end
    end

    MenuGeneration.create!(
      tenant: tenant,
      requested_by: manager,
      input_lot_ids_json: tenant.inventory_lots.limit(5).pluck(:id),
      model: "gpt-4o-mini",
      prompt_version: SEED_PROMPT_VERSION,
      status: index.even? ? :succeeded : :fallback_manual,
      latency_ms: rand(900..4200),
      error_code: index.even? ? nil : "TimeoutError",
      raw_response_encrypted: "{\"seed\":true}"
    )

    [manager, staff_a, staff_b].each do |actor|
      AuditLog.create!(
        tenant: tenant,
        actor: actor,
        action: "seed.activity",
        entity_type: "Tenant",
        entity_id: tenant.id,
        metadata_json: {
          seed: true,
          actor_email: actor.email,
          lots: tenant.inventory_lots.count,
          menus: tenant.daily_menus.count
        },
        ip_address: "127.0.0.1"
      )
    end
  end

  AuditLog.create!(
    action: "seed.completed",
    entity_type: "System",
    entity_id: 0,
    metadata_json: {
      seed: true,
      tenants: Tenant.count,
      users: User.count,
      products: Product.count,
      inventory_lots: InventoryLot.count,
      daily_menus: DailyMenu.count
    },
    ip_address: "127.0.0.1"
  )
end

puts "== Social Kitchen seed: done =="
puts "\nCredenciales demo:"
puts "- Admin global: admin@socialkitchen.local / #{DEFAULT_PASSWORD}"
puts "- Ops admin: ops-admin@socialkitchen.local / #{DEFAULT_PASSWORD}"
puts "- Manager base: manager+comedor-central@socialkitchen.local / #{DEFAULT_PASSWORD}"
puts "- Staff base: staff-a+comedor-central@socialkitchen.local / #{DEFAULT_PASSWORD}"
puts "\nResumen:"
puts "- Tenants: #{Tenant.count}"
puts "- Users: #{User.count}"
puts "- Memberships: #{Membership.count}"
puts "- Products: #{Product.count}"
puts "- Inventory lots: #{InventoryLot.count}"
puts "- Daily menus: #{DailyMenu.count}"
puts "- Menu generations: #{MenuGeneration.count}"
puts "- Audit logs: #{AuditLog.count}"
