require "test_helper"

class Menus::GenerateDailyMenuServiceTest < ActiveSupport::TestCase
  class FailingAiClient
    def generate_menu(ingredients:, planning_context:, locale:)
      raise "simulated_failure"
    end

    def model
      "gpt-test"
    end
  end

  class SuccessfulAiClient
    def generate_menu(ingredients:, planning_context:, locale:)
      {
        "title" => "Menu anti desperdicio",
        "description" => "Plan inteligente para combinar variedad y volumen.",
        "allergens" => [ "gluten" ],
        "nutritionSummary" => {
          "estimatedTotalKcal" => 4200,
          "estimatedAverageKcalPerServing" => 525,
          "proteinFocus" => "media",
          "carbFocus" => "alta",
          "fatFocus" => "moderada"
        },
        "dietaryGuidance" => {
          "halalStatus" => "needs_review",
          "haramRisks" => [ "gelatina no certificada" ],
          "vegetarianOptions" => [ "Crema de verduras" ],
          "veganOptions" => [ "Crema de verduras" ],
          "religiousNotes" => "Verificar certificados de ingredientes procesados."
        },
        "planningNotes" => {
          "productionMode" => "balanced",
          "strategy" => "Dos platos base y uno de rotacion para aprovechar lotes pequenos.",
          "estimatedTotalServings" => 8,
          "wasteReductionPlan" => [ "Reutilizar excedente de crema como salsa del dia siguiente" ]
        },
        "items" => [
          {
            "name" => "Guiso de lentejas",
            "description" => "Con sofrito de verduras",
            "ingredients" => [ "lentejas", "zanahoria", "cebolla" ],
            "allergens" => [ "apio" ],
            "servings" => 4,
            "repetitions" => 1,
            "nutrition" => {
              "kcal" => 450,
              "protein_g" => 21,
              "carbs_g" => 56,
              "fat_g" => 12,
              "fiber_g" => 8
            },
            "dietaryFlags" => [ "halal_needs_review", "vegetariano" ],
            "religiousNotes" => "Sin cerdo, revisar caldo industrial.",
            "inventoryUsage" => [
              { "lotId" => ingredients.first[:lotId], "product" => ingredients.first[:product], "quantity" => 1.5, "unit" => "kg" }
            ]
          }
        ]
      }
    end

    def model
      "gpt-test"
    end
  end

  test "falls back to manual draft when AI fails" do
    tenant = Tenant.create!(name: "Comedor Sur", slug: "comedor-sur", status: :active)
    user = User.create!(full_name: "Manager", email: "manager@example.com", password: "Password123!", password_confirmation: "Password123!", locale: "es")
    Membership.create!(user: user, tenant: tenant, role: :tenant_manager, active: true)

    product = Product.create!(name: "Lentejas", barcode: "333", source: :manual)
    InventoryLot.create!(tenant: tenant, product: product, expires_on: Date.current + 1.day, quantity: 3, unit: :kg, status: :available, source: :donation)

    menu = Menus::GenerateDailyMenuService.new(tenant: tenant, user: user, ai_client: FailingAiClient.new).call(date: Date.current)

    assert menu.persisted?
    assert_equal "manual", menu.generated_by
    assert_equal "draft", menu.status
    assert_equal Date.current, menu.menu_date
  end

  test "stores enriched AI output for nutrition and dietary guidance" do
    tenant = Tenant.create!(name: "Comedor Este", slug: "comedor-este", status: :active)
    user = User.create!(full_name: "Manager", email: "manager2@example.com", password: "Password123!", password_confirmation: "Password123!", locale: "es")
    Membership.create!(user: user, tenant: tenant, role: :tenant_manager, active: true)

    product = Product.create!(name: "Arroz", barcode: "444", source: :manual)
    InventoryLot.create!(tenant: tenant, product: product, expires_on: Date.current + 1.day, quantity: 3, unit: :kg, status: :available, source: :donation)

    menu = Menus::GenerateDailyMenuService.new(tenant: tenant, user: user, ai_client: SuccessfulAiClient.new).call(date: Date.current)

    assert menu.persisted?
    assert_equal "ai", menu.generated_by
    assert_equal "balanced", menu.planning_notes_json["productionMode"]
    assert_equal "needs_review", menu.dietary_guidance_json["halalStatus"]

    item = menu.daily_menu_items.first
    assert_equal 4, item.servings
    assert_equal 1, item.repetitions
    assert_equal 450, item.nutrition_json["kcal"]
    assert_includes item.dietary_flags_json, "vegetariano"
    assert_equal "kg", item.inventory_usage_json.first["unit"]
  end
end
