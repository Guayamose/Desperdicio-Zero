using System.Text.Json;
using System.Text.Json.Serialization;

namespace DesperdicioZero.Maui.Models;

public class ApiEnvelope<T>
{
    [JsonPropertyName("data")]
    public T? Data { get; set; }

    [JsonPropertyName("meta")]
    public ApiMeta? Meta { get; set; }

    [JsonPropertyName("requestId")]
    public string? RequestId { get; set; }
}

public class ApiMeta
{
    [JsonPropertyName("page")]
    public int Page { get; set; }

    [JsonPropertyName("perPage")]
    public int PerPage { get; set; }

    [JsonPropertyName("total")]
    public int Total { get; set; }

    [JsonPropertyName("totalPages")]
    public int TotalPages { get; set; }
}

public class ApiError
{
    [JsonPropertyName("code")]
    public string? Code { get; set; }

    [JsonPropertyName("message")]
    public string? Message { get; set; }

    [JsonPropertyName("details")]
    public JsonElement? Details { get; set; }
}

public class SessionData
{
    [JsonPropertyName("user")]
    public UserSession? User { get; set; }

    [JsonPropertyName("currentTenant")]
    public TenantSummary? CurrentTenant { get; set; }

    [JsonPropertyName("memberships")]
    public List<MembershipSummary> Memberships { get; set; } = [];
}

public class UserSession
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("fullName")]
    public string FullName { get; set; } = string.Empty;

    [JsonPropertyName("email")]
    public string Email { get; set; } = string.Empty;

    [JsonPropertyName("locale")]
    public string Locale { get; set; } = "es";

    [JsonPropertyName("mustChangePassword")]
    public bool MustChangePassword { get; set; }

    [JsonPropertyName("systemAdmin")]
    public bool SystemAdmin { get; set; }
}

public class MembershipSummary
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("tenantId")]
    public int TenantId { get; set; }

    [JsonPropertyName("role")]
    public string Role { get; set; } = "tenant_staff";

    [JsonPropertyName("active")]
    public bool Active { get; set; }

    [JsonPropertyName("tenant")]
    public TenantSummary? Tenant { get; set; }

    [JsonPropertyName("tenantName")]
    public string? TenantName { get; set; }
}

public class TenantSummary
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("slug")]
    public string Slug { get; set; } = string.Empty;

    [JsonPropertyName("status")]
    public string Status { get; set; } = string.Empty;

    [JsonPropertyName("address")]
    public string? Address { get; set; }

    [JsonPropertyName("city")]
    public string? City { get; set; }

    [JsonPropertyName("region")]
    public string? Region { get; set; }

    [JsonPropertyName("country")]
    public string? Country { get; set; }

    [JsonPropertyName("contactEmail")]
    public string? ContactEmail { get; set; }

    [JsonPropertyName("contactPhone")]
    public string? ContactPhone { get; set; }

    [JsonPropertyName("operatingHoursJson")]
    public Dictionary<string, string>? OperatingHoursJson { get; set; }
}

public class ProductDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("barcode")]
    public string? Barcode { get; set; }

    [JsonPropertyName("brand")]
    public string? Brand { get; set; }

    [JsonPropertyName("category")]
    public string? Category { get; set; }

    [JsonPropertyName("allergensJson")]
    public List<string> AllergensJson { get; set; } = [];
}

public class InventoryLotDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("productId")]
    public int ProductId { get; set; }

    [JsonPropertyName("tenantId")]
    public int TenantId { get; set; }

    [JsonPropertyName("expiresOn")]
    public DateTime ExpiresOn { get; set; }

    [JsonPropertyName("quantity")]
    public decimal Quantity { get; set; }

    [JsonPropertyName("unit")]
    public string Unit { get; set; } = "unit";

    [JsonPropertyName("status")]
    public string Status { get; set; } = "available";

    [JsonPropertyName("source")]
    public string Source { get; set; } = "other";

    [JsonPropertyName("receivedOn")]
    public DateTime? ReceivedOn { get; set; }

    [JsonPropertyName("notes")]
    public string? Notes { get; set; }

    [JsonPropertyName("product")]
    public ProductDto Product { get; set; } = new();
}

public class AlertsData
{
    [JsonPropertyName("expiring")]
    public List<InventoryLotDto> Expiring { get; set; } = [];

    [JsonPropertyName("expired")]
    public List<InventoryLotDto> Expired { get; set; } = [];
}

public class DailyMenuItemDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("position")]
    public int Position { get; set; }

    [JsonPropertyName("servings")]
    public int Servings { get; set; }

    [JsonPropertyName("repetitions")]
    public int Repetitions { get; set; }

    [JsonPropertyName("ingredientsJson")]
    public List<string> IngredientsJson { get; set; } = [];

    [JsonPropertyName("allergensJson")]
    public List<string> AllergensJson { get; set; } = [];

    [JsonPropertyName("dietaryFlagsJson")]
    public List<string> DietaryFlagsJson { get; set; } = [];

    [JsonPropertyName("religiousNotes")]
    public string? ReligiousNotes { get; set; }

    [JsonPropertyName("inventoryUsageJson")]
    public List<Dictionary<string, object>> InventoryUsageJson { get; set; } = [];
}

public class DailyMenuDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("tenantId")]
    public int TenantId { get; set; }

    [JsonPropertyName("menuDate")]
    public DateTime MenuDate { get; set; }

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; } = "draft";

    [JsonPropertyName("generatedBy")]
    public string GeneratedBy { get; set; } = "manual";

    [JsonPropertyName("allergensJson")]
    public List<string> AllergensJson { get; set; } = [];

    [JsonPropertyName("planningNotesJson")]
    public JsonElement PlanningNotesJson { get; set; }

    [JsonPropertyName("nutritionSummaryJson")]
    public JsonElement NutritionSummaryJson { get; set; }

    [JsonPropertyName("dietaryGuidanceJson")]
    public JsonElement DietaryGuidanceJson { get; set; }

    [JsonPropertyName("dailyMenuItems")]
    public List<DailyMenuItemDto> DailyMenuItems { get; set; } = [];
}

public class MenuGenerationDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; } = string.Empty;

    [JsonPropertyName("latencyMs")]
    public int? LatencyMs { get; set; }

    [JsonPropertyName("createdAt")]
    public DateTime CreatedAt { get; set; }
}

public class DashboardMetrics
{
    [JsonPropertyName("inventoryCount")]
    public int InventoryCount { get; set; }

    [JsonPropertyName("expiringCount")]
    public int ExpiringCount { get; set; }

    [JsonPropertyName("todayMenuCount")]
    public int TodayMenuCount { get; set; }

    [JsonPropertyName("latestGenerationLatencyMs")]
    public int? LatestGenerationLatencyMs { get; set; }
}

public class DashboardData
{
    [JsonPropertyName("tenant")]
    public TenantSummary? Tenant { get; set; }

    [JsonPropertyName("metrics")]
    public DashboardMetrics Metrics { get; set; } = new();

    [JsonPropertyName("todayMenu")]
    public DailyMenuDto? TodayMenu { get; set; }

    [JsonPropertyName("latestGeneration")]
    public MenuGenerationDto? LatestGeneration { get; set; }
}

public class EmployeeMembershipDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("role")]
    public string Role { get; set; } = "tenant_staff";

    [JsonPropertyName("active")]
    public bool Active { get; set; }

    [JsonPropertyName("user")]
    public UserSession User { get; set; } = new();
}

public class AdminMetricsDto
{
    [JsonPropertyName("tenants")]
    public int Tenants { get; set; }

    [JsonPropertyName("activeTenants")]
    public int ActiveTenants { get; set; }

    [JsonPropertyName("users")]
    public int Users { get; set; }

    [JsonPropertyName("inventoryLots")]
    public int InventoryLots { get; set; }

    [JsonPropertyName("expiredLots")]
    public int ExpiredLots { get; set; }

    [JsonPropertyName("menusToday")]
    public int MenusToday { get; set; }

    [JsonPropertyName("aiSuccessRatio")]
    public decimal AiSuccessRatio { get; set; }
}

public class AuditLogDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("action")]
    public string Action { get; set; } = string.Empty;

    [JsonPropertyName("entityType")]
    public string EntityType { get; set; } = string.Empty;

    [JsonPropertyName("entityId")]
    public int? EntityId { get; set; }

    [JsonPropertyName("createdAt")]
    public DateTime CreatedAt { get; set; }

    [JsonPropertyName("ipAddress")]
    public string? IpAddress { get; set; }
}

public class AdminUserDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("fullName")]
    public string FullName { get; set; } = string.Empty;

    [JsonPropertyName("email")]
    public string Email { get; set; } = string.Empty;

    [JsonPropertyName("locale")]
    public string Locale { get; set; } = "es";

    [JsonPropertyName("blockedAt")]
    public DateTime? BlockedAt { get; set; }

    [JsonPropertyName("systemAdmin")]
    public bool SystemAdmin { get; set; }

    [JsonPropertyName("memberships")]
    public List<MembershipSummary> Memberships { get; set; } = [];
}

public class InventoryLotInput
{
    public int? ProductId { get; set; }
    public string? Barcode { get; set; }
    public string? ProductName { get; set; }
    public DateTime ExpiresOn { get; set; } = DateTime.Today.AddDays(7);
    public decimal Quantity { get; set; } = 1;
    public string Unit { get; set; } = "unit";
    public string Status { get; set; } = "available";
    public DateTime ReceivedOn { get; set; } = DateTime.Today;
    public string Source { get; set; } = "donation";
    public string? Notes { get; set; }
}

public class MenuItemInput
{
    public int? Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int Position { get; set; }
    public int Servings { get; set; } = 1;
    public int Repetitions { get; set; } = 1;
    public string IngredientsCsv { get; set; } = string.Empty;
    public string AllergensCsv { get; set; } = string.Empty;
    public bool Destroy { get; set; }
}

public class MenuInput
{
    public DateTime MenuDate { get; set; } = DateTime.Today;
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string AllergensCsv { get; set; } = string.Empty;
    public List<MenuItemInput> Items { get; set; } = [];
}

public class EmployeeInput
{
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Locale { get; set; } = "es";
    public string Role { get; set; } = "tenant_staff";
}

public class ProfileInput
{
    public string FullName { get; set; } = string.Empty;
    public string? Password { get; set; }
    public string? PasswordConfirmation { get; set; }
    public string? CurrentPassword { get; set; }
}

public class TenantInput
{
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string Status { get; set; } = "active";
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? Region { get; set; }
    public string? Country { get; set; }
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
    public Dictionary<string, string> OperatingHoursJson { get; set; } = new();
}

public class AdminUserInput
{
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Locale { get; set; } = "es";
    public int? TenantId { get; set; }
    public string Role { get; set; } = "tenant_staff";
    public bool SystemAdmin { get; set; }
}

public static class JsonFormatting
{
    public static string Pretty(this JsonElement element)
    {
        if (element.ValueKind == JsonValueKind.Undefined || element.ValueKind == JsonValueKind.Null)
        {
            return string.Empty;
        }

        return element.ToString();
    }
}
