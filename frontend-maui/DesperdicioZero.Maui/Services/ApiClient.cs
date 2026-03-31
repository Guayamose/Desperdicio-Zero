using System.Globalization;
using System.Net;
using System.Text;
using System.Text.Json;
using DesperdicioZero.Maui.Models;
using Microsoft.Maui.Devices;

namespace DesperdicioZero.Maui.Services;

public class ApiClient
{
    private readonly CookieContainer _cookies = new();
    private readonly JsonSerializerOptions _jsonOptions;
    private readonly HttpClient _httpClient;

    public static string PlatformDefaultBaseUrl => DeviceInfo.Platform == DevicePlatform.Android
        ? "http://10.0.2.2:3000"
        : "http://localhost:3000";

    public string BaseUrl { get; private set; } = PlatformDefaultBaseUrl;

    public ApiClient()
    {
        var handler = new HttpClientHandler
        {
            UseCookies = true,
            CookieContainer = _cookies
        };

        _httpClient = new HttpClient(handler)
        {
            Timeout = TimeSpan.FromSeconds(45)
        };

        _jsonOptions = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull
        };

        SetBaseUrl(BaseUrl);
    }

    public void SetBaseUrl(string baseUrl)
    {
        var normalized = NormalizeBaseUrl(baseUrl);
        BaseUrl = normalized;
        _httpClient.BaseAddress = new Uri(normalized);
    }

    public async Task<SessionData> LoginAsync(string email, string password)
    {
        var envelope = await SendAsync<ApiEnvelope<SessionData>>(HttpMethod.Post, "/api/v1/auth/login", new
        {
            email,
            password
        });

        return envelope.Data ?? throw new ApiException("Login sin datos de sesión", HttpStatusCode.InternalServerError);
    }

    public async Task<SessionData> GetSessionAsync()
    {
        var envelope = await SendAsync<ApiEnvelope<SessionData>>(HttpMethod.Get, "/api/v1/auth/me");
        return envelope.Data ?? throw new ApiException("No hay sesión activa", HttpStatusCode.Unauthorized);
    }

    public async Task<SessionData> SwitchTenantAsync(int tenantId)
    {
        var envelope = await SendAsync<ApiEnvelope<SessionData>>(HttpMethod.Post, $"/api/v1/auth/switch-tenant/{tenantId}");
        return envelope.Data ?? throw new ApiException("No se pudo cambiar de tenant", HttpStatusCode.Forbidden);
    }

    public async Task LogoutAsync()
    {
        await SendAsync<JsonElement>(HttpMethod.Delete, "/api/v1/auth/logout");
    }

    public async Task<List<TenantSummary>> GetPublicTenantsAsync()
    {
        var envelope = await SendAsync<ApiEnvelope<List<TenantSummary>>>(HttpMethod.Get, "/api/v1/public/tenants");
        return envelope.Data ?? [];
    }

    public async Task<DailyMenuDto?> GetPublicMenuTodayAsync(string slug)
    {
        var envelope = await SendAsync<ApiEnvelope<DailyMenuDto>>(HttpMethod.Get, $"/api/v1/public/tenants/{Uri.EscapeDataString(slug)}/menu-today", allowNotFound: true);
        return envelope.Data;
    }

    public async Task<DashboardData> GetTenantDashboardAsync()
    {
        var envelope = await SendAsync<ApiEnvelope<DashboardData>>(HttpMethod.Get, "/api/v1/tenant/dashboard");
        return envelope.Data ?? new DashboardData();
    }

    public async Task<List<InventoryLotDto>> GetInventoryLotsAsync()
    {
        var envelope = await SendAsync<ApiEnvelope<List<InventoryLotDto>>>(HttpMethod.Get, "/api/v1/tenant/inventory/lots?per_page=200");
        return envelope.Data ?? [];
    }

    public async Task<InventoryLotDto> CreateInventoryLotAsync(InventoryLotInput input)
    {
        var payload = new
        {
            inventory_lot = new
            {
                product_id = input.ProductId,
                barcode = input.Barcode,
                product_name = input.ProductName,
                expires_on = input.ExpiresOn.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                quantity = input.Quantity,
                unit = input.Unit,
                status = input.Status,
                received_on = input.ReceivedOn.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                source = input.Source,
                notes = input.Notes
            }
        };

        var envelope = await SendAsync<ApiEnvelope<InventoryLotDto>>(HttpMethod.Post, "/api/v1/tenant/inventory/lots", payload);
        return envelope.Data ?? throw new ApiException("No se pudo crear lote", HttpStatusCode.InternalServerError);
    }

    public async Task<InventoryLotDto> UpdateInventoryLotAsync(int lotId, InventoryLotInput input)
    {
        var payload = new
        {
            inventory_lot = new
            {
                product_id = input.ProductId,
                barcode = input.Barcode,
                product_name = input.ProductName,
                expires_on = input.ExpiresOn.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                quantity = input.Quantity,
                unit = input.Unit,
                status = input.Status,
                received_on = input.ReceivedOn.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                source = input.Source,
                notes = input.Notes
            }
        };

        var envelope = await SendAsync<ApiEnvelope<InventoryLotDto>>(HttpMethod.Patch, $"/api/v1/tenant/inventory/lots/{lotId}", payload);
        return envelope.Data ?? throw new ApiException("No se pudo actualizar lote", HttpStatusCode.InternalServerError);
    }

    public async Task DeleteInventoryLotAsync(int lotId)
    {
        await SendAsync<JsonElement>(HttpMethod.Delete, $"/api/v1/tenant/inventory/lots/{lotId}");
    }

    public async Task<ProductDto?> ScanBarcodeAsync(string barcode, string source = "usb")
    {
        var envelope = await SendAsync<ApiEnvelope<ScanData>>(HttpMethod.Post, "/api/v1/tenant/inventory/scan", new
        {
            barcode,
            source
        }, allowNotFound: true);

        return envelope.Data?.Product;
    }

    public async Task<AlertsData> GetAlertsAsync()
    {
        var envelope = await SendAsync<ApiEnvelope<AlertsData>>(HttpMethod.Get, "/api/v1/tenant/alerts/expirations");
        return envelope.Data ?? new AlertsData();
    }

    public async Task<List<DailyMenuDto>> GetMenusAsync()
    {
        var envelope = await SendAsync<ApiEnvelope<List<DailyMenuDto>>>(HttpMethod.Get, "/api/v1/tenant/menus?per_page=200");
        return envelope.Data ?? [];
    }

    public async Task<DailyMenuDto> CreateMenuAsync(MenuInput input)
    {
        var envelope = await SendAsync<ApiEnvelope<DailyMenuDto>>(HttpMethod.Post, "/api/v1/tenant/menus", BuildMenuPayload(input));
        return envelope.Data ?? throw new ApiException("No se pudo crear menú", HttpStatusCode.InternalServerError);
    }

    public async Task<DailyMenuDto> UpdateMenuAsync(int menuId, MenuInput input)
    {
        var envelope = await SendAsync<ApiEnvelope<DailyMenuDto>>(HttpMethod.Patch, $"/api/v1/tenant/menus/{menuId}", BuildMenuPayload(input));
        return envelope.Data ?? throw new ApiException("No se pudo actualizar menú", HttpStatusCode.InternalServerError);
    }

    public async Task<DailyMenuDto> GenerateMenuAsync(DateTime date)
    {
        var envelope = await SendAsync<ApiEnvelope<DailyMenuDto>>(HttpMethod.Post, "/api/v1/tenant/menus/generate", new
        {
            date = date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)
        });

        return envelope.Data ?? throw new ApiException("No se pudo generar menú", HttpStatusCode.InternalServerError);
    }

    public async Task<DailyMenuDto?> GetMenuByDateAsync(DateTime date)
    {
        var dateText = date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
        var envelope = await SendAsync<ApiEnvelope<DailyMenuDto>>(HttpMethod.Get, $"/api/v1/tenant/menus/{dateText}", allowNotFound: true);
        return envelope.Data;
    }

    public async Task PublishMenuAsync(int menuId)
    {
        await SendAsync<ApiEnvelope<DailyMenuDto>>(HttpMethod.Post, $"/api/v1/tenant/menus/{menuId}/publish");
    }

    public async Task DeleteMenuAsync(int menuId)
    {
        await SendAsync<JsonElement>(HttpMethod.Delete, $"/api/v1/tenant/menus/{menuId}");
    }

    public async Task<List<EmployeeMembershipDto>> GetEmployeesAsync()
    {
        var envelope = await SendAsync<ApiEnvelope<List<EmployeeMembershipDto>>>(HttpMethod.Get, "/api/v1/tenant/employees");
        return envelope.Data ?? [];
    }

    public async Task<(EmployeeMembershipDto employee, string temporaryPassword)> CreateEmployeeAsync(EmployeeInput input)
    {
        var payload = new
        {
            user = new
            {
                full_name = input.FullName,
                email = input.Email,
                locale = input.Locale
            },
            membership = new
            {
                role = input.Role
            }
        };

        var raw = await SendAsync<CreateEmployeeResponse>(HttpMethod.Post, "/api/v1/tenant/employees", payload);
        var employee = raw.Data ?? throw new ApiException("No se devolvió empleado", HttpStatusCode.InternalServerError);
        return (employee, raw.TemporaryPassword ?? string.Empty);
    }

    public async Task<EmployeeMembershipDto> UpdateEmployeeRoleAsync(int membershipId, string role)
    {
        var envelope = await SendAsync<ApiEnvelope<EmployeeMembershipDto>>(HttpMethod.Patch, $"/api/v1/tenant/employees/{membershipId}", new
        {
            membership = new
            {
                role
            }
        });

        return envelope.Data ?? throw new ApiException("No se pudo actualizar empleado", HttpStatusCode.InternalServerError);
    }

    public async Task DeleteEmployeeAsync(int membershipId)
    {
        await SendAsync<JsonElement>(HttpMethod.Delete, $"/api/v1/tenant/employees/{membershipId}");
    }

    public async Task<SessionData> GetProfileAsync()
    {
        var envelope = await SendAsync<ApiEnvelope<SessionData>>(HttpMethod.Get, "/api/v1/tenant/profile");
        return envelope.Data ?? throw new ApiException("No se pudo cargar perfil", HttpStatusCode.InternalServerError);
    }

    public async Task<SessionData> UpdateProfileAsync(ProfileInput input)
    {
        var payload = new
        {
            user = new
            {
                full_name = input.FullName,
                password = input.Password,
                password_confirmation = input.PasswordConfirmation,
                current_password = input.CurrentPassword
            }
        };

        var envelope = await SendAsync<ApiEnvelope<SessionData>>(HttpMethod.Patch, "/api/v1/tenant/profile", payload);
        return envelope.Data ?? throw new ApiException("No se pudo actualizar perfil", HttpStatusCode.InternalServerError);
    }

    public async Task UpdatePasswordAsync(string password, string passwordConfirmation)
    {
        await SendAsync<ApiEnvelope<JsonElement>>(HttpMethod.Patch, "/api/v1/tenant/profile/password", new
        {
            user = new
            {
                password,
                password_confirmation = passwordConfirmation
            }
        });
    }

    public async Task<AdminMetricsDto> GetAdminMetricsAsync()
    {
        var envelope = await SendAsync<ApiEnvelope<AdminMetricsDto>>(HttpMethod.Get, "/api/v1/admin/metrics");
        return envelope.Data ?? new AdminMetricsDto();
    }

    public async Task<List<TenantSummary>> GetAdminTenantsAsync()
    {
        var envelope = await SendAsync<ApiEnvelope<List<TenantSummary>>>(HttpMethod.Get, "/api/v1/admin/tenants?per_page=200");
        return envelope.Data ?? [];
    }

    public async Task<TenantSummary> CreateAdminTenantAsync(TenantInput input)
    {
        var envelope = await SendAsync<ApiEnvelope<TenantSummary>>(HttpMethod.Post, "/api/v1/admin/tenants", new
        {
            tenant = new
            {
                name = input.Name,
                slug = input.Slug,
                status = input.Status,
                address = input.Address,
                city = input.City,
                region = input.Region,
                country = input.Country,
                contact_email = input.ContactEmail,
                contact_phone = input.ContactPhone,
                operating_hours_json = input.OperatingHoursJson
            }
        });

        return envelope.Data ?? throw new ApiException("No se pudo crear comedor", HttpStatusCode.InternalServerError);
    }

    public async Task<TenantSummary> UpdateAdminTenantAsync(int tenantId, TenantInput input)
    {
        var envelope = await SendAsync<ApiEnvelope<TenantSummary>>(HttpMethod.Patch, $"/api/v1/admin/tenants/{tenantId}", new
        {
            tenant = new
            {
                name = input.Name,
                slug = input.Slug,
                status = input.Status,
                address = input.Address,
                city = input.City,
                region = input.Region,
                country = input.Country,
                contact_email = input.ContactEmail,
                contact_phone = input.ContactPhone,
                operating_hours_json = input.OperatingHoursJson
            }
        });

        return envelope.Data ?? throw new ApiException("No se pudo actualizar comedor", HttpStatusCode.InternalServerError);
    }

    public async Task DeleteAdminTenantAsync(int tenantId)
    {
        await SendAsync<JsonElement>(HttpMethod.Delete, $"/api/v1/admin/tenants/{tenantId}");
    }

    public async Task<List<AdminUserDto>> GetAdminUsersAsync()
    {
        var envelope = await SendAsync<ApiEnvelope<List<AdminUserDto>>>(HttpMethod.Get, "/api/v1/admin/users?per_page=200");
        return envelope.Data ?? [];
    }

    public async Task<(AdminUserDto user, string temporaryPassword)> CreateAdminUserAsync(AdminUserInput input)
    {
        var response = await SendAsync<CreateAdminUserResponse>(HttpMethod.Post, "/api/v1/admin/users", new
        {
            user = new
            {
                full_name = input.FullName,
                email = input.Email,
                locale = input.Locale
            },
            tenant_id = input.TenantId,
            role = input.Role,
            system_admin = input.SystemAdmin
        });

        var user = response.Data ?? throw new ApiException("No se devolvió usuario creado", HttpStatusCode.InternalServerError);
        return (user, response.TemporaryPassword ?? string.Empty);
    }

    public async Task BlockAdminUserAsync(int userId)
    {
        await SendAsync<JsonElement>(HttpMethod.Patch, $"/api/v1/admin/users/{userId}/block");
    }

    public async Task AnonymizeAdminUserAsync(int userId)
    {
        await SendAsync<JsonElement>(HttpMethod.Patch, $"/api/v1/admin/users/{userId}/anonymize");
    }

    public async Task<JsonElement?> ExportAdminUserAsync(int userId)
    {
        var envelope = await SendAsync<ApiEnvelope<JsonElement>>(HttpMethod.Get, $"/api/v1/admin/users/{userId}/export");
        return envelope.Data;
    }

    public async Task<List<AuditLogDto>> GetAdminAuditLogsAsync()
    {
        var envelope = await SendAsync<ApiEnvelope<List<AuditLogDto>>>(HttpMethod.Get, "/api/v1/admin/audit-logs?per_page=200");
        return envelope.Data ?? [];
    }

    private async Task<T> SendAsync<T>(HttpMethod method, string path, object? payload = null, bool allowNotFound = false)
    {
        using var request = new HttpRequestMessage(method, path);
        request.Headers.Accept.ParseAdd("application/json");

        if (payload is not null)
        {
            var json = JsonSerializer.Serialize(payload, _jsonOptions);
            request.Content = new StringContent(json, Encoding.UTF8, "application/json");
        }

        using var response = await _httpClient.SendAsync(request);
        var body = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            if (allowNotFound && response.StatusCode == HttpStatusCode.NotFound)
            {
                return Activator.CreateInstance<T>();
            }

            throw BuildApiException(response.StatusCode, body);
        }

        if (typeof(T) == typeof(JsonElement) && string.IsNullOrWhiteSpace(body))
        {
            return Activator.CreateInstance<T>();
        }

        if (string.IsNullOrWhiteSpace(body))
        {
            return Activator.CreateInstance<T>();
        }

        var result = JsonSerializer.Deserialize<T>(body, _jsonOptions);
        return result ?? Activator.CreateInstance<T>();
    }

    private static ApiException BuildApiException(HttpStatusCode statusCode, string body)
    {
        try
        {
            var error = JsonSerializer.Deserialize<ApiError>(body, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            var message = error?.Message;
            if (!string.IsNullOrWhiteSpace(message))
            {
                return new ApiException(message, statusCode, error?.Code);
            }
        }
        catch
        {
            // Ignore parse errors and fallback to generic message.
        }

        var fallback = string.IsNullOrWhiteSpace(body)
            ? $"API error ({(int)statusCode})"
            : body;

        return new ApiException(fallback, statusCode);
    }

    private static string[] CsvToArray(string? csv)
    {
        if (string.IsNullOrWhiteSpace(csv))
        {
            return [];
        }

        return csv
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .ToArray();
    }

    private static object BuildMenuPayload(MenuInput input)
    {
        var items = input.Items
            .Where(item => !string.IsNullOrWhiteSpace(item.Name) || item.Id.HasValue)
            .Select(item => new
            {
                id = item.Id,
                name = item.Name,
                description = item.Description,
                position = item.Position,
                servings = item.Servings,
                repetitions = item.Repetitions,
                ingredients_json = CsvToArray(item.IngredientsCsv),
                allergens_json = CsvToArray(item.AllergensCsv),
                _destroy = item.Destroy
            })
            .ToList();

        return new
        {
            daily_menu = new
            {
                menu_date = input.MenuDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                title = input.Title,
                description = input.Description,
                allergens_json = CsvToArray(input.AllergensCsv),
                daily_menu_items_attributes = items
            }
        };
    }

    private static string NormalizeBaseUrl(string input)
    {
        var candidate = string.IsNullOrWhiteSpace(input) ? PlatformDefaultBaseUrl : input.Trim();
        if (!candidate.StartsWith("http://", StringComparison.OrdinalIgnoreCase) && !candidate.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            candidate = $"http://{candidate}";
        }

        return candidate.EndsWith("/") ? candidate.TrimEnd('/') : candidate;
    }

    private sealed class ScanData
    {
        public ProductDto? Product { get; set; }
    }

    private sealed class CreateEmployeeResponse
    {
        public EmployeeMembershipDto? Data { get; set; }
        public string? TemporaryPassword { get; set; }
    }

    private sealed class CreateAdminUserResponse
    {
        public AdminUserDto? Data { get; set; }
        public string? TemporaryPassword { get; set; }
    }
}
