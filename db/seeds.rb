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
  },
  {
    slug: "comedor-sol",
    name: "Comedor del Sol",
    status: :active,
    address: "Plaza del Sol 1",
    city: "Málaga",
    region: "Andalucía",
    country: "ES",
    latitude: 36.721273,
    longitude: -4.421398,
    contact_email: "sol@socialkitchen.local",
    contact_phone: "+34 900 100 206"
  },
  {
    slug: "comedor-pinares",
    name: "Comedor Pinares",
    status: :active,
    address: "Avenida de los Pinares 12",
    city: "Valladolid",
    region: "Castilla y León",
    country: "ES",
    latitude: 41.652251,
    longitude: -4.724532,
    contact_email: "pinares@socialkitchen.local",
    contact_phone: "+34 900 100 207"
  },
  {
    slug: "comedor-esperanza",
    name: "Comedor La Esperanza",
    status: :active,
    address: "Calle de la Esperanza 44",
    city: "Zaragoza",
    region: "Aragón",
    country: "ES",
    latitude: 41.649693,
    longitude: -0.887712,
    contact_email: "esperanza@socialkitchen.local",
    contact_phone: "+34 900 100 208"
  },
  {
    slug: "comedor-puerto",
    name: "Comedor del Puerto",
    status: :active,
    address: "Paseo Marítimo 3",
    city: "A Coruña",
    region: "Galicia",
    country: "ES",
    latitude: 43.371350,
    longitude: -8.396000,
    contact_email: "puerto@socialkitchen.local",
    contact_phone: "+34 900 100 209"
  },
  {
    slug: "comedor-sierra",
    name: "Comedor La Sierra",
    status: :active,
    address: "Calle Alta 100",
    city: "Granada",
    region: "Andalucía",
    country: "ES",
    latitude: 37.177336,
    longitude: -3.598557,
    contact_email: "sierra@socialkitchen.local",
    contact_phone: "+34 900 100 210"
  }
].freeze

PRODUCTS_DATA = [
  { barcode: "8411111111111", name: "Arroz integral", brand: "Solidario", category: "granos", allergens_json: ["gluten"] },
  { barcode: "8411111111112", name: "Lentejas pardinas", brand: "Solidario", category: "legumbres", allergens_json: [] },
  { barcode: "8411111111113", name: "Garbanzos", brand: "Solidario", category: "legumbres", allergens_json: [] },
  { barcode: "8411111111114", name: "Macarrones", brand: "Comedor+", category: "granos", allergens_json: ["gluten"] },
  { barcode: "8411111111115", name: "Tomate triturado", brand: "Huerta Viva", category: "conserva", allergens_json: [] },
  { barcode: "8411111111116", name: "Atún claro en aceite", brand: "Mar Azul", category: "proteina", allergens_json: ["pescado"] },
  { barcode: "8411111111117", name: "Pechuga de pollo", brand: "Campo Fresco", category: "proteina", allergens_json: [] },
  { barcode: "8411111111118", name: "Huevos L", brand: "Granja Norte", category: "proteina", allergens_json: ["huevo"] },
  { barcode: "8411111111119", name: "Leche entera", brand: "Lactea", category: "lacteos", allergens_json: ["lactosa"] },
  { barcode: "8411111111120", name: "Yogur natural", brand: "Lactea", category: "lacteos", allergens_json: ["lactosa"] },
  { barcode: "8411111111121", name: "Pan de molde integral", brand: "Horno Social", category: "panaderia", allergens_json: ["gluten"] },
  { barcode: "8411111111122", name: "Zanahorias bolsa", brand: "Huerta Viva", category: "verdura", allergens_json: [] },
  { barcode: "8411111111123", name: "Cebollas malla", brand: "Huerta Viva", category: "verdura", allergens_json: [] },
  { barcode: "8411111111124", name: "Patatas saco", brand: "Huerta Viva", category: "verdura", allergens_json: [] },
  { barcode: "8411111111125", name: "Aceite de oliva virgen", brand: "Cooperativa Sur", category: "aceites", allergens_json: [] },
  { barcode: "8411111111126", name: "Manzanas Golden", brand: "Fruta Norte", category: "fruta", allergens_json: [] },
  { barcode: "8411111111127", name: "Plátanos de Canarias", brand: "Isla Sol", category: "fruta", allergens_json: [] },
  { barcode: "8411111111128", name: "Pimientos rojos", brand: "Huerta Viva", category: "verdura", allergens_json: [] },
  { barcode: "8411111111129", name: "Alubias blancas", brand: "Solidario", category: "legumbres", allergens_json: [] },
  { barcode: "8411111111130", name: "Leche semi-desnatada", brand: "Lactea", category: "lacteos", allergens_json: ["lactosa"] },
  { barcode: "8411111111131", name: "Bebida de avena", brand: "Natura", category: "lacteos", allergens_json: ["gluten"] },
  { barcode: "8411111111132", name: "Harina de trigo", brand: "El Molino", category: "granos", allergens_json: ["gluten"] },
  { barcode: "8411111111133", name: "Merluza congelada", brand: "Mar Azul", category: "proteina", allergens_json: ["pescado"] },
  { barcode: "8411111111134", name: "Carne picada mixta", brand: "Campo Fresco", category: "proteina", allergens_json: [] },
  { barcode: "8411111111135", name: "Caldo de pollo", brand: "Sopas de Oro", category: "conserva", allergens_json: ["apio"] },
  { barcode: "8411111111136", name: "Guisantes en conserva", brand: "Huerta Viva", category: "conserva", allergens_json: [] },
  { barcode: "8411111111137", name: "Ajo seco", brand: "Huerta Viva", category: "verdura", allergens_json: [] },
  { barcode: "8411111111138", name: "Mandarinas frescas", brand: "Fruta Norte", category: "fruta", allergens_json: [] },
  { barcode: "8411111111139", name: "Galletas maria", brand: "Horno Social", category: "panaderia", allergens_json: ["gluten", "lactosa"] },
  { barcode: "8411111111140", name: "Azúcar blanco", brand: "DulceVida", category: "otros", allergens_json: [] },
  { barcode: "8411111111141", name: "Sal fina", brand: "Marinos", category: "otros", allergens_json: [] },
  { barcode: "8411111111142", name: "Salsa de soja", brand: "AsiaFlavors", category: "salsas", allergens_json: ["soja", "gluten"] },
  { barcode: "8411111111143", name: "Mayonesa", brand: "Salsas Chef", category: "salsas", allergens_json: ["huevo"] },
  { barcode: "8411111111144", name: "Lomo de cerdo", brand: "Campo Fresco", category: "proteina", allergens_json: [] },
  { barcode: "8411111111145", name: "Calabacín fresco", brand: "Huerta Viva", category: "verdura", allergens_json: [] },
  { barcode: "8411111111146", name: "Queso en lonchas", brand: "Lactea", category: "lacteos", allergens_json: ["lactosa"] },
  { barcode: "8411111111147", name: "Pera conferencia", brand: "Fruta Norte", category: "fruta", allergens_json: [] },
  { barcode: "8411111111148", name: "Sardinas en aceite", brand: "Mar Azul", category: "proteina", allergens_json: ["pescado"] },
  { barcode: "8411111111149", name: "Lazos de pasta tricolor", brand: "Comedor+", category: "granos", allergens_json: ["gluten"] },
  { barcode: "8411111111150", name: "Vinagre de manzana", brand: "Cooperativa Sur", category: "aceites", allergens_json: ["sulfitos"] }
].freeze

MENU_BASES = [
  {
    title: "Menu mediterráneo solidario",
    description: "Propuesta equilibrada con prioridad en ingredientes cercanos a caducidad.",
    planning_notes_json: { "strategy" => "Priorización rotación perecederos cortos", "estimatedTotalServings" => 150, "productionMode" => "Batch 2 turnos" },
    nutrition_summary_json: { "estimatedAverageKcalPerServing" => 750, "proteinFocus" => "Media (legumbre)", "carbFocus" => "Complejos (integral)", "fatFocus" => "Saludable (AOVE)" },
    dietary_guidance_json: { "halalStatus" => "Apto", "haramRisks" => [], "religiousNotes" => "Menú apto sin carne" },
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
            "En una olla grande, calentar el aceite de oliva a fuego medio. Pochar la cebolla hasta que esté transparente.",
            "Añadir la zanahoria y rehogar 3 minutos más, removiendo con frecuencia.",
            "Incorporar las lentejas escurridas, cubrir con agua fría (el doble de volumen) y llevar a ebullición.",
            "Reducir a fuego medio-bajo, añadir el pimentón y el comino. Cocinar tapado durante 25-30 minutos hasta que las lentejas estén tiernas."
          ],
          "tips" => ["No añadir la sal al principio: endurece las lentejas y alarga la cocción."],
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
            "Picar la cebolla en dados pequeños. Pochar en una cazuela amplia con aceite.",
            "Añadir el tomate triturado y cocinar 3-4 minutos hasta que oscurezca ligeramente.",
            "Incorporar el arroz y remover. Añadir agua caliente (proporción 2.5:1), sal y pimienta. Llevar a ebullición.",
            "Tapar y cocinar a fuego bajo 20-25 minutos sin destapar. Dejar reposar 5 minutos antes de servir."
          ],
          "tips" => ["Dejar reposar tapado es clave para una textura suelta."],
          "waste_note" => "Los restos de arroz se pueden usar al día siguiente como base de ensalada."
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
            "Servir enteras o cortadas en cuartos según preferencia del comedor."
          ],
          "tips" => ["Servir a temperatura ambiente para más sabor."],
          "waste_note" => "Las manzanas con desperfectos se pueden usar para compota."
        }
      }
    ]
  },
  {
    title: "Menú proteico de aprovechamiento",
    description: "Menú orientado a aprovechar lotes donados de proteína y verdura fresca.",
    planning_notes_json: { "strategy" => "Procesamiento inmediato de cárnicos", "estimatedTotalServings" => 120, "productionMode" => "Batch único" },
    nutrition_summary_json: { "estimatedAverageKcalPerServing" => 850, "proteinFocus" => "Alta (pollo, garbanzo)", "carbFocus" => "Media", "fatFocus" => "Moderada" },
    dietary_guidance_json: { "halalStatus" => "Verificar certificación del pollo", "haramRisks" => ["Contaminación cruzada"], "religiousNotes" => "Confirmar trazabilidad de carne donada" },
    items: [
      {
        name: "Pollo guisado",
        ingredients: ["pollo troceado 200g por ración", "patata 150g por ración", "zanahoria 80g por ración", "aceite de oliva 15ml", "laurel, sal y pimienta"],
        allergens: [],
        cooking_instructions: {
          "difficulty" => "Medio",
          "prep_time" => "55 min",
          "steps" => [
            "Salpimentar los trozos de pollo. En una cazuela grande, calentar el aceite y dorar el pollo por todos los lados. Reservar.",
            "En la misma cazuela, sofreír la cebolla picada 4-5 minutos.",
            "Pelar las patatas y cortarlas en trozos grandes. Pelar y cortar la zanahoria.",
            "Devolver el pollo a la cazuela, añadir patatas, zanahoria, laurel y cubrir con agua o caldo.",
            "Llevar a ebullición y cocinar tapado 30-35 minutos a fuego medio-bajo."
          ],
          "tips" => ["Dorar bien el pollo antes de guisar aporta mucho sabor al caldo final."],
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
            "Escurrir y enjuagar bien los garbanzos bajo agua fría.",
            "Picar la cebolla muy fina (brunoise).",
            "Mezclar los garbanzos con la cebolla y el tomate triturado en un bol grande.",
            "Aliñar con aceite de oliva, vinagre, sal y perejil picado. Mezclar bien."
          ],
          "tips" => ["Preparar con antelación mejora el sabor."],
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
          "steps" => ["Retirar los yogures del frigorífico 5 minutos antes de servir."],
          "tips" => ["El yogur natural sin azúcar es preferible para el perfil nutricional."],
          "waste_note" => "Los yogures próximos a caducidad se pueden congelar para uso en batidos."
        }
      }
    ]
  },
  {
    title: "Menú rápido comunitario",
    description: "Formato sencillo para servicios con alta demanda en horario punta.",
    planning_notes_json: { "strategy" => "Operativa de alta velocidad de emplatado", "estimatedTotalServings" => 300, "productionMode" => "Línea continua" },
    nutrition_summary_json: { "estimatedAverageKcalPerServing" => 900, "proteinFocus" => "Media (atún, huevo)", "carbFocus" => "Media-Alta", "fatFocus" => "Media (fritura controlada)" },
    dietary_guidance_json: { "halalStatus" => "Apto", "haramRisks" => [], "religiousNotes" => "Pescado y huevo son generalmente aceptados" },
    items: [
      {
        name: "Pasta con atún",
        ingredients: ["pasta 150g por ración", "atún en conserva 80g por ración", "tomate triturado 100g por ración", "aceite de oliva 10ml", "ajo, sal y orégano"],
        allergens: ["gluten", "pescado"],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "20 min",
          "steps" => [
            "Hervir agua en una olla grande y cocer la pasta. Escurrir reservando algo de agua.",
            "Calentar aceite en una sartén, dorar el ajo y añadir el tomate triturado. Cocinar 8-10 mins.",
            "Escurrir el atún y desmenuzarlo. Incorporar a la salsa.",
            "Mezclar la pasta con la salsa de atún y servir."
          ],
          "tips" => ["Reservar siempre un vaso de agua de cocción: el almidón ayuda a ligar la salsa."],
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
            "Confitar las patatas y la cebolla en abundante aceite de oliva a fuego medio-bajo durante 15-20 minutos.",
            "Escurrir bien. Batir los huevos en un bol grande, salar e incorporar las patatas y cebolla.",
            "En una sartén con poco aceite, verter la mezcla y cocinar a fuego medio-bajo.",
            "Dar la vuelta con ayuda de un plato y cocinar por el otro lado."
          ],
          "tips" => ["La clave es el fuego bajo: confitar, nunca freír las patatas."],
          "waste_note" => "El aceite de confitar se puede filtrar y reutilizar hasta 3 veces."
        }
      },
      {
        name: "Pan integral",
        ingredients: ["pan integral 1 rebanada por ración"],
        allergens: ["gluten"],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "3 min",
          "steps" => ["Cortar en rebanadas y servir como acompañamiento."],
          "tips" => ["El pan del día anterior se puede rociar con agua antes de calentar."],
          "waste_note" => "El pan sobrante se puede secar y triturar para hacer pan rallado casero."
        }
      }
    ]
  },
  {
    title: "Menú Caliente de Invierno",
    description: "Menú denso en calorías para refugios de invierno, ideal para combatir el frío.",
    planning_notes_json: { "strategy" => "Cocción lenta de alto rendimiento", "estimatedTotalServings" => 200, "productionMode" => "Ollas gran formato" },
    nutrition_summary_json: { "estimatedAverageKcalPerServing" => 1100, "proteinFocus" => "Alta (carne, legumbre)", "carbFocus" => "Alta", "fatFocus" => "Moderada" },
    dietary_guidance_json: { "halalStatus" => "No Apto por defecto", "haramRisks" => ["Carne picada mixta (cerdo)"], "religiousNotes" => "Ofrecer alternativa vegetal si se solicita" },
    items: [
      {
        name: "Cocido completo",
        ingredients: ["garbanzos 200g por ración", "carne picada mixta 100g por ración", "patatas saco 100g por ración", "zanahorias bolsa 50g por ración", "caldo de pollo 200ml"],
        allergens: ["apio"],
        cooking_instructions: {
          "difficulty" => "Medio",
          "prep_time" => "2 horas",
          "steps" => [
            "Dejar los garbanzos en remojo la noche anterior.",
            "En una olla express, añadir los garbanzos, la carne picada (formada en albóndigas), verduras troceadas y caldo de pollo.",
            "Cocinar a presión durante unos 40 minutos o hasta que los garbanzos estén tiernos.",
            "Servir el caldo primero y luego los ingredientes sólidos."
          ],
          "tips" => ["El caldo absorbe todo el sabor de la carne, desgrasar antes de servir."],
          "waste_note" => "El caldo sobrante puede congelarse para sopas futuras."
        }
      },
      {
        name: "Pan de molde integral",
        ingredients: ["pan de molde integral 2 rebanadas por ración"],
        allergens: ["gluten"],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "0 min",
          "steps" => ["Servir para acompañar el caldo."],
          "tips" => [],
          "waste_note" => "Hacer picatostes con las rebanadas secas."
        }
      },
      {
        name: "Mandarinas frescas",
        ingredients: ["mandarinas frescas 2 unidades por ración"],
        allergens: [],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "5 min",
          "steps" => ["Lavar y servir enteras en una cesta de fruta común."],
          "tips" => ["Aportan una dosis necesaria de vitamina C en invierno."],
          "waste_note" => "Las cáscaras pueden utilizarse para compostaje o aromatizantes."
        }
      }
    ]
  },
  {
    title: "Menú Vegetariano Equilibrado",
    description: "Opción libre de carne con fuerte aporte proteico a través de legumbres y lácteos.",
    planning_notes_json: { "strategy" => "Sostenibilidad y bajo coste", "estimatedTotalServings" => 100, "productionMode" => "Batch único" },
    nutrition_summary_json: { "estimatedAverageKcalPerServing" => 650, "proteinFocus" => "Media (alubia, leche)", "carbFocus" => "Media", "fatFocus" => "Baja" },
    dietary_guidance_json: { "halalStatus" => "Apto", "haramRisks" => [], "religiousNotes" => "Apto universal (salvo alergias)" },
    items: [
      {
        name: "Alubias blancas con verduras",
        ingredients: ["alubias blancas 180g por ración", "calabacín fresco 100g por ración", "pimientos rojos 80g por ración", "aceite de oliva virgen 15ml", "sal y pimentón"],
        allergens: [],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "1.5 horas",
          "steps" => [
            "Poner en remojo las alubias 12 horas. Escurrir y meter en una olla con agua limpia.",
            "Picar el calabacín y los pimientos rojos, sofreír en sartén con aceite de oliva.",
            "Añadir el sofrito a la olla y cocer a fuego lento hasta que espese el caldo."
          ],
          "tips" => ["Romper hervor 3 veces (asustar) para que queden tiernas."],
          "waste_note" => "El agua de remojo se puede usar para regar huertos urbanos."
        }
      },
      {
        name: "Revuelto de calabacín",
        ingredients: ["huevos L 2 unidades por ración", "calabacín fresco 100g por ración", "aceite de oliva virgen 10ml"],
        allergens: ["huevo"],
        cooking_instructions: {
          "difficulty" => "Media",
          "prep_time" => "15 min",
          "steps" => [
            "Picar el calabacín en bastones finos y saltear en una sartén con poco aceite.",
            "Batir huevos y añadir a la sartén removiendo rápidamente para que no cuaje en bloque.",
            "Retirar del fuego mientras siga jugoso."
          ],
          "tips" => ["No sobrecocer el huevo para una buena textura."],
          "waste_note" => "Se pueden usar también los tallos blandos del calabacín."
        }
      },
      {
        name: "Yogur natural con manzana",
        ingredients: ["yogur natural 1 unidad por ración", "manzanas Golden 0.5 unidades por ración"],
        allergens: ["lactosa"],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "5 min",
          "steps" => ["Picar la manzana en dados muy finos y mezclar con el yogur antes de servir."],
          "tips" => ["Batir el yogur hasta que sea cremoso."],
          "waste_note" => "Composta los núcleos de manzana."
        }
      }
    ]
  },
  {
    title: "Menú Ligero y Dietético",
    description: "Especial para usuarios con estómagos más delicados o dietas blandas.",
    planning_notes_json: { "strategy" => "Elaboración centralizada bajo en especias", "estimatedTotalServings" => 50, "productionMode" => "Bandejas individuales" },
    nutrition_summary_json: { "estimatedAverageKcalPerServing" => 500, "proteinFocus" => "Media (pescado)", "carbFocus" => "Media", "fatFocus" => "Baja" },
    dietary_guidance_json: { "halalStatus" => "Apto", "haramRisks" => [], "religiousNotes" => "Pescado aceptado" },
    items: [
      {
        name: "Merluza al horno con verduritas",
        ingredients: ["merluza congelada 150g por ración", "zanahorias bolsa 50g por ración", "patatas saco 100g por ración", "aceite de oliva virgen 10ml"],
        allergens: ["pescado"],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "35 min",
          "steps" => [
            "Descongelar la merluza en cámara el día anterior.",
            "Cortar patatas y zanahorias en láminas muy finas (panadera).",
            "Disponer las verduras en una bandeja de horno, hornear a 180°C durante 20 min.",
            "Añadir la merluza encima y hornear 10 minutos más."
          ],
          "tips" => ["No pasar el pescado de tiempo para que no quede seco."],
          "waste_note" => "Usa restos de recortes de pescado para futuros fumets."
        }
      },
      {
        name: "Lazos de pasta con aceite",
        ingredients: ["lazos de pasta tricolor 100g por ración", "aceite de oliva virgen 5ml"],
        allergens: ["gluten"],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "15 min",
          "steps" => [
            "Hervir agua abundante, cocer la pasta el tiempo indicado.",
            "Escurrir, mezclar con un hilo de aceite para dar brillo y evitar que se pegue."
          ],
          "tips" => ["Es una guarnición neutral excelente."],
          "waste_note" => ""
        }
      },
      {
        name: "Pera conferencia",
        ingredients: ["pera conferencia 1 unidad por ración"],
        allergens: [],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "0 min",
          "steps" => ["Lavar y servir."],
          "tips" => ["Estas peras son dulces y muy jugosas."],
          "waste_note" => ""
        }
      }
    ]
  },
  {
    title: "Menú Internacional Asiático",
    description: "Variedad cultural con ingredientes muy atractivos que eleva la moral de los asistentes.",
    planning_notes_json: { "strategy" => "Servicio de wok directo", "estimatedTotalServings" => 150, "productionMode" => "Salteado en tanda" },
    nutrition_summary_json: { "estimatedAverageKcalPerServing" => 800, "proteinFocus" => "Alta (lomo de cerdo)", "carbFocus" => "Alta (arroz)", "fatFocus" => "Moderada" },
    dietary_guidance_json: { "halalStatus" => "Prohibido", "haramRisks" => ["Cerdo"], "religiousNotes" => "El lomo de cerdo es haram. Reemplazo requerido." },
    items: [
      {
        name: "Arroz frito con vegetales",
        ingredients: ["arroz integral 150g por ración", "guisantes en conserva 50g por ración", "zanahorias bolsa 50g por ración", "salsa de soja 10ml"],
        allergens: ["soja", "gluten"],
        cooking_instructions: {
          "difficulty" => "Medio",
          "prep_time" => "25 min",
          "steps" => [
            "Cocer el arroz y dejar enfriar completamente (preferible del día anterior).",
            "Picar zanahorias en dados. Saltear junto con los guisantes a fuego fuerte (wok).",
            "Añadir el arroz, mezclar todo y saltear a fuego máximo.",
            "Añadir salsa de soja al final para desglasar."
          ],
          "tips" => ["El arroz frío es vital para que no quede pastoso al saltearlo."],
          "waste_note" => ""
        }
      },
      {
        name: "Lomo de cerdo en salsa",
        ingredients: ["lomo de cerdo 120g por ración", "cebollas malla 50g por ración", "salsa de soja 10ml"],
        allergens: ["soja", "gluten"],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "30 min",
          "steps" => [
            "Cortar el lomo en tiras muy finas.",
            "Saltear la cebolla, añadir el cerdo y sofreír hasta que dore.",
            "Mezclar un poco de harina de trigo con agua y salsa de soja, verter en la sartén hasta espesar."
          ],
          "tips" => ["El corte fino hace que rinda mucho más visualmente."],
          "waste_note" => "La salsa concentrada se aprovecha toda mojando arroz."
        }
      },
      {
        name: "Plátano",
        ingredients: ["plátanos de Canarias 1 unidad por ración"],
        allergens: [],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "0 min",
          "steps" => ["Servir la pieza entera."],
          "tips" => [],
          "waste_note" => "Plátanos muy maduros pueden usarse para bizcocho."
        }
      }
    ]
  },
  {
    title: "Menú Estival Refrescante",
    description: "Platos frescos para la temporada de calor, sin necesidad de horno u ollas largas.",
    planning_notes_json: { "strategy" => "Línea fría total", "estimatedTotalServings" => 250, "productionMode" => "Montaje en mesa fría" },
    nutrition_summary_json: { "estimatedAverageKcalPerServing" => 750, "proteinFocus" => "Media (atún, huevo)", "carbFocus" => "Media", "fatFocus" => "Media (mayonesa)" },
    dietary_guidance_json: { "halalStatus" => "Apto", "haramRisks" => [], "religiousNotes" => "" },
    items: [
      {
        name: "Ensalada de pasta tricolor",
        ingredients: ["lazos de pasta tricolor 120g por ración", "atún claro en aceite 50g por ración", "tomate triturado 30g por ración", "mayonesa 20g por ración"],
        allergens: ["gluten", "pescado", "huevo"],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "20 min",
          "steps" => [
            "Cocer la pasta, escurrir y enfriar bajo el grifo. Escurrir bien.",
            "Mezclar en grandes boles la pasta, el atún desmigado y un chorrito de tomate.",
            "Añadir mayonesa justo antes del servicio."
          ],
          "tips" => ["Mantener refrigerado en todo momento antes del servicio para evitar problemas alimenticios."],
          "waste_note" => ""
        }
      },
      {
        name: "Huevos rellenos",
        ingredients: ["huevos L 1.5 unidades por ración", "mayonesa 10g por ración"],
        allergens: ["huevo"],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "25 min",
          "steps" => [
            "Cocer los huevos durante 10-12 minutos. Pelar bajo agua fría.",
            "Cortar a la mitad, sacar las yemas.",
            "Mezclar las yemas con un poco de mayonesa y volver a rellenar las claras."
          ],
          "tips" => ["Enfriar los huevos rápidamente tras cocerlos hace que la piel salga fácilmente."],
          "waste_note" => "Las cáscaras de huevo van perfectas para agricultura/compost."
        }
      },
      {
        name: "Manzana limpia",
        ingredients: ["manzanas Golden 1 unidad por ración"],
        allergens: [],
        cooking_instructions: {
          "difficulty" => "Fácil",
          "prep_time" => "0 min",
          "steps" => ["Lavar y secar."],
          "tips" => [],
          "waste_note" => ""
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

    tenant_products = products.rotate(index * 3).first(25)
    expiry_offsets = [ -5, -3, -2, -1, 1, 2, 4, 7, 10, 12, 15, 20, 30, 45, 60 ]

    tenant_products.each_with_index do |product, lot_index|
      expires_on = Date.current + expiry_offsets[lot_index % expiry_offsets.length].days
      received_on = [Date.current - 3.days, expires_on - 10.days].max
      source = lot_index.even? ? :donation : :purchase
      category = product.category
      if ["granos", "legumbres", "verdura", "fruta", "otros", "proteina"].include?(category)
        unit = :kg
        quantity = rand(50.0..500.0).round(2)
      elsif ["lacteos", "aceites", "salsas"].include?(category)
        unit = :l
        quantity = rand(20.0..100.0).round(2)
      else
        unit = :unit
        quantity = rand(100.0..1000.0).round(2)
      end

      # Excepción para huevos (vienen en unidades, no kg aunque sean proteina)
      if product.name.downcase.include?("huevo")
        unit = :unit
        quantity = rand(300..1500).to_f
      end

      lot = InventoryLot.find_or_initialize_by(
        tenant: tenant,
        product: product,
        expires_on: expires_on,
        source: source
      )

      lot.assign_attributes(
        quantity: quantity,
        unit: unit,
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

    ((Date.current - 4.days)..Date.tomorrow).to_a.each_with_index do |menu_date, menu_index|
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
        planning_notes_json: menu_template[:planning_notes_json] || {},
        nutrition_summary_json: menu_template[:nutrition_summary_json] || {},
        dietary_guidance_json: menu_template[:dietary_guidance_json] || {},
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
