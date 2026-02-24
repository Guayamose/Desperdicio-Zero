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
      {
        name: "Lentejas estofadas",
        ingredients: ["lentejas 180g por ración", "zanahoria 80g por ración", "cebolla 60g por ración", "aceite de oliva 10ml", "sal, pimentón y comino"],
        allergens: [],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "45 min",
          "steps" => [
            "Remojar las lentejas en agua fría durante al menos 1 hora (si no son pardinas). Escurrir y reservar.",
            "Pelar y picar la cebolla en brunoise fina. Pelar la zanahoria y cortarla en rodajas de medio centímetro.",
            "En una olla grande, calentar el aceite de oliva a fuego medio. Pochar la cebolla hasta que esté transparente (unos 5 minutos).",
            "Añadir la zanahoria y rehogar 3 minutos más, removiendo con frecuencia.",
            "Incorporar las lentejas escurridas, cubrir con agua fría (el doble de volumen) y llevar a ebullición.",
            "Reducir a fuego medio-bajo, añadir el pimentón y el comino. Cocinar tapado durante 25-30 minutos hasta que las lentejas estén tiernas.",
            "Rectificar de sal al final de la cocción. Servir caliente en plato hondo."
          ],
          "tips" => [
            "No añadir la sal al principio: endurece las lentejas y alarga la cocción.",
            "Si sobra caldo, se puede reutilizar como base para sopa al día siguiente.",
            "Las lentejas pardinas no necesitan remojo previo."
          ],
          "waste_note" => "Las pieles de zanahoria y trozos de cebolla se pueden reservar para caldo de verduras."
        }
      },
      {
        name: "Arroz con verduras",
        ingredients: ["arroz integral 150g por ración", "tomate triturado 100g por ración", "cebolla 50g por ración", "aceite de oliva 10ml", "sal y pimienta"],
        allergens: ["gluten"],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "35 min",
          "steps" => [
            "Lavar el arroz integral bajo agua fría hasta que el agua salga clara. Escurrir bien.",
            "Picar la cebolla en dados pequeños.",
            "En una cazuela amplia, calentar el aceite y pochar la cebolla a fuego medio durante 5 minutos.",
            "Añadir el tomate triturado y cocinar 3-4 minutos hasta que oscurezca ligeramente.",
            "Incorporar el arroz, remover para que se impregne del sofrito durante 1-2 minutos.",
            "Añadir agua caliente (proporción 2.5:1 para integral), sal y pimienta. Llevar a ebullición.",
            "Tapar y cocinar a fuego bajo 20-25 minutos sin destapar. Dejar reposar 5 minutos antes de servir."
          ],
          "tips" => [
            "No remover el arroz una vez añadida el agua: se pega y queda pastoso.",
            "El arroz integral necesita más agua y tiempo que el blanco.",
            "Dejar reposar tapado es clave para una textura suelta."
          ],
          "waste_note" => "Los restos de arroz se pueden usar al día siguiente como base de ensalada fría o croquetas."
        }
      },
      {
        name: "Fruta de temporada",
        ingredients: ["manzana 1 unidad por ración"],
        allergens: [],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "5 min",
          "steps" => [
            "Lavar las manzanas bajo agua corriente frotando la piel.",
            "Secar con papel de cocina o paño limpio.",
            "Servir enteras o cortadas en cuartos según preferencia del comedor.",
            "Si se cortan, rociar con unas gotas de limón para evitar la oxidación."
          ],
          "tips" => [
            "Las manzanas con golpes se pueden pelar y aprovechar para compota.",
            "Servir a temperatura ambiente para más sabor."
          ],
          "waste_note" => "Las manzanas con desperfectos superficiales se pueden usar para compota o macedonia."
        }
      }
    ]
  },
  {
    title: "Menu proteico de aprovechamiento",
    description: "Menu orientado a aprovechar lotes donados de proteina y verdura fresca.",
    items: [
      {
        name: "Pollo guisado",
        ingredients: ["pollo troceado 200g por ración", "patata 150g por ración", "zanahoria 80g por ración", "aceite de oliva 15ml", "laurel, sal y pimienta"],
        allergens: [],
        cooking_instructions: {
          "difficulty" => "Medio",
          "prep_time" => "55 min",
          "steps" => [
            "Salpimentar los trozos de pollo generosamente por ambos lados.",
            "En una cazuela grande, calentar el aceite a fuego fuerte y dorar el pollo por todos los lados (3-4 min por cara). Reservar.",
            "En la misma cazuela con la grasa del pollo, sofreír la cebolla picada 4-5 minutos.",
            "Pelar las patatas y cortarlas en trozos grandes. Pelar y cortar la zanahoria en rodajas gruesas.",
            "Devolver el pollo a la cazuela, añadir patatas, zanahoria, laurel y cubrir con agua o caldo.",
            "Llevar a ebullición, reducir a fuego medio-bajo y cocinar tapado 30-35 minutos.",
            "Las patatas deben estar tiernas y el pollo completamente cocido (sin partes rosadas). Rectificar de sal."
          ],
          "tips" => [
            "Dorar bien el pollo antes de guisar aporta mucho sabor al caldo final.",
            "No cortar las patatas muy pequeñas: se deshacen con la cocción larga.",
            "El caldo sobrante es excelente para sopa o para cocinar arroz."
          ],
          "waste_note" => "Los huesos del pollo se pueden hervir para hacer caldo base para el día siguiente."
        }
      },
      {
        name: "Ensalada de garbanzos",
        ingredients: ["garbanzos cocidos 180g por ración", "tomate triturado 80g por ración", "cebolla 40g por ración", "aceite de oliva 10ml", "vinagre, sal y perejil"],
        allergens: [],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "15 min",
          "steps" => [
            "Si los garbanzos son de bote, escurrir y enjuagar bien bajo agua fría.",
            "Si son secos previamente cocidos, asegurarse de que están a temperatura ambiente.",
            "Picar la cebolla muy fina (brunoise). Si pica mucho, sumergir en agua fría 5 minutos y escurrir.",
            "Mezclar los garbanzos con la cebolla y el tomate triturado en un bol grande.",
            "Aliñar con aceite de oliva, vinagre, sal y perejil picado. Mezclar bien.",
            "Dejar reposar al menos 10 minutos a temperatura ambiente para que absorba sabores.",
            "Servir en plato llano o como guarnición."
          ],
          "tips" => [
            "Preparar con antelación mejora el sabor: los garbanzos absorben el aliño.",
            "Se puede añadir pimiento rojo o pepino si hay excedente en inventario."
          ],
          "waste_note" => "El líquido de los garbanzos en conserva (aquafaba) sirve como sustituto de huevo en repostería."
        }
      },
      {
        name: "Yogur natural",
        ingredients: ["yogur natural 125g por ración"],
        allergens: ["lactosa"],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "2 min",
          "steps" => [
            "Retirar los yogures del frigorífico 5 minutos antes de servir.",
            "Servir en su envase individual o en cuenco si es formato a granel.",
            "Opcionalmente, acompañar con un poco de miel o fruta troceada si hay disponibilidad."
          ],
          "tips" => [
            "Comprobar la fecha de caducidad antes de servir.",
            "El yogur natural sin azúcar es preferible para el perfil nutricional del comedor."
          ],
          "waste_note" => "Los yogures próximos a caducidad se pueden congelar para uso en batidos o repostería."
        }
      }
    ]
  },
  {
    title: "Menu rapido comunitario",
    description: "Formato sencillo para servicios con alta demanda en horario punta.",
    items: [
      {
        name: "Pasta con atun",
        ingredients: ["pasta 150g por ración", "atún en conserva 80g por ración", "tomate triturado 100g por ración", "aceite de oliva 10ml", "ajo, sal y orégano"],
        allergens: ["gluten", "pescado"],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "20 min",
          "steps" => [
            "Poner abundante agua a hervir en una olla grande (1 litro por cada 100g de pasta). Salar generosamente.",
            "Mientras hierve el agua, preparar la salsa: calentar aceite en una sartén y dorar el ajo laminado 1 minuto.",
            "Añadir el tomate triturado, sal y orégano. Cocinar a fuego medio 8-10 minutos removiendo de vez en cuando.",
            "Escurrir el atún de la lata y desmenuzar con un tenedor. Incorporar a la salsa los últimos 2 minutos.",
            "Cocer la pasta según las indicaciones del paquete (generalmente 8-10 min). Escurrir reservando un vaso de agua de cocción.",
            "Mezclar la pasta con la salsa de atún. Si queda seca, añadir un poco del agua de cocción reservada.",
            "Servir inmediatamente en plato hondo."
          ],
          "tips" => [
            "Reservar siempre un vaso de agua de cocción: el almidón ayuda a ligar la salsa.",
            "No enjuagar la pasta tras escurrirla: pierde el almidón que hace que la salsa adhiera.",
            "El atún en conserva en aceite de oliva da más sabor que el natural."
          ],
          "waste_note" => "El aceite del atún en conserva se puede reutilizar como base del sofrito."
        }
      },
      {
        name: "Tortilla de patata",
        ingredients: ["huevos 2 unidades por ración", "patata 200g por ración", "cebolla 60g por ración", "aceite de oliva abundante", "sal"],
        allergens: ["huevo"],
        cooking_instructions: {
          "difficulty" => "Medio",
          "prep_time" => "35 min",
          "steps" => [
            "Pelar y cortar las patatas en láminas finas (2-3 mm). Cortar la cebolla en juliana fina.",
            "Calentar abundante aceite de oliva en una sartén amplia (debe cubrir las patatas).",
            "Confitar las patatas y la cebolla a fuego medio-bajo durante 15-20 minutos. Deben quedar tiernas, no crujientes.",
            "Escurrir bien las patatas y cebolla del aceite (reservar el aceite para reutilizar).",
            "Batir los huevos en un bol grande, salar. Incorporar las patatas y cebolla escurridas. Mezclar con cuidado.",
            "En una sartén antiadherente con un poco de aceite, verter la mezcla. Cocinar a fuego medio-bajo 4-5 minutos.",
            "Dar la vuelta con ayuda de un plato. Cocinar 3-4 minutos más por el otro lado.",
            "Dejar reposar 2-3 minutos antes de cortar. Servir templada o a temperatura ambiente."
          ],
          "tips" => [
            "La clave es el fuego bajo: confitar, nunca freír las patatas.",
            "Para dar la vuelta, usar un plato llano más grande que la sartén.",
            "La tortilla jugosa se consigue sacándola del fuego un poco antes: el calor residual termina la cocción."
          ],
          "waste_note" => "El aceite de confitar se puede filtrar y reutilizar hasta 3 veces para tortillas o sofritos."
        }
      },
      {
        name: "Pan integral",
        ingredients: ["pan integral 1 rebanada por ración"],
        allergens: ["gluten"],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "3 min",
          "steps" => [
            "Si el pan es del día, cortar en rebanadas de 1-2 cm de grosor.",
            "Si el pan es del dia anterior, tostar ligeramente en horno o tostadora para recuperar textura.",
            "Servir como acompañamiento junto al plato principal."
          ],
          "tips" => [
            "El pan del día anterior se puede rociar con un poco de agua antes de calentar en horno para que recupere humedad.",
            "Cortar las rebanadas justo antes de servir para que no se sequen."
          ],
          "waste_note" => "El pan sobrante se puede secar y triturar para hacer pan rallado casero, o usar para torrijas o migas."
        }
      }
    ]
  }
].freeze

def upsert_user!(email:, full_name:, locale: "es", blocked: false, password: DEFAULT_PASSWORD)
  user = User.find_or_initialize_by(email: email)
  user.full_name = full_name
  user.locale = locale
  user.gdpr_consent_at ||= Time.current
  user.password = password
  user.password_confirmation = password
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

    demo_users = case tenant.slug
                 when "comedor-central"
                   [
                     [
                       upsert_user!(
                         email: "manager@test.com",
                         full_name: "Manager Demo Comedor Central",
                         password: "manager123"
                       ),
                       :tenant_manager
                     ],
                     [
                       upsert_user!(
                         email: "staff@test.com",
                         full_name: "Staff Demo Comedor Central",
                         password: "staff1234"
                       ),
                       :tenant_staff
                     ]
                   ]
                 when "comedor-rio"
                   [
                     [
                       upsert_user!(
                         email: "manager2@test.com",
                         full_name: "Manager Demo Comedor Rio",
                         password: "manager123"
                       ),
                       :tenant_manager
                     ]
                   ]
                 when "comedor-marina"
                   [
                     [
                       upsert_user!(
                         email: "manager3@test.com",
                         full_name: "Manager Demo Comedor Marina",
                         password: "manager123"
                       ),
                       :tenant_manager
                     ]
                   ]
                 else
                   []
                 end

    [
      [manager, :tenant_manager],
      [staff_a, :tenant_staff],
      [staff_b, :tenant_staff]
    ].concat(demo_users).each do |user, role|
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
          allergens_json: item[:allergens],
          cooking_instructions_json: item[:cooking_instructions] || {}
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
puts "- Manager demo (Comedor Central): manager@test.com / manager123"
puts "- Manager demo (Comedor Rio)    : manager2@test.com / manager123"
puts "- Manager demo (Comedor Marina) : manager3@test.com / manager123"
puts "- Staff demo (Comedor Central)  : staff@test.com / staff1234"
puts "\nResumen:"
puts "- Tenants: #{Tenant.count}"
puts "- Users: #{User.count}"
puts "- Memberships: #{Membership.count}"
puts "- Products: #{Product.count}"
puts "- Inventory lots: #{InventoryLot.count}"
puts "- Daily menus: #{DailyMenu.count}"
puts "- Menu generations: #{MenuGeneration.count}"
puts "- Audit logs: #{AuditLog.count}"
