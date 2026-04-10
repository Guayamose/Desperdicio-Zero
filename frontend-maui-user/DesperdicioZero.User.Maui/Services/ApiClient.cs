using System.Net;
using System.Text;
using System.Text.Json;
using DesperdicioZero.User.Maui.Models;
using Microsoft.Maui.Devices;

namespace DesperdicioZero.User.Maui.Services;

public class ApiClient
{
    private readonly JsonSerializerOptions _jsonOptions;
    private readonly HttpClient _httpClient;

    public static string PlatformDefaultBaseUrl => DeviceInfo.Platform == DevicePlatform.Android
        ? "http://10.0.2.2:3000"
        : "http://localhost:3000";

    public string BaseUrl { get; private set; } = PlatformDefaultBaseUrl;

    public ApiClient()
    {
        _httpClient = new HttpClient
        {
            Timeout = TimeSpan.FromSeconds(30)
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

    public async Task<List<TenantSummary>> GetPublicTenantsAsync()
    {
        var envelope = await SendAsync<ApiEnvelope<List<TenantSummary>>>(HttpMethod.Get, "/api/v1/public/tenants");
        return envelope.Data ?? [];
    }

    public async Task<TenantSummary> GetPublicTenantAsync(string slug)
    {
        var envelope = await SendAsync<ApiEnvelope<TenantSummary>>(HttpMethod.Get, $"/api/v1/public/tenants/{Uri.EscapeDataString(slug)}");
        return envelope.Data ?? throw new ApiException("No se pudo cargar el comedor", HttpStatusCode.InternalServerError);
    }

    public async Task<DailyMenuDto?> GetPublicMenuTodayAsync(string slug)
    {
        var envelope = await SendAsync<ApiEnvelope<DailyMenuDto>>(HttpMethod.Get, $"/api/v1/public/tenants/{Uri.EscapeDataString(slug)}/menu-today", allowNotFound: true);
        return envelope.Data;
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

            if (!string.IsNullOrWhiteSpace(error?.Message))
            {
                return new ApiException(error.Message, statusCode, error.Code);
            }
        }
        catch
        {
        }

        var fallback = string.IsNullOrWhiteSpace(body)
            ? $"API error ({(int)statusCode})"
            : body;

        return new ApiException(fallback, statusCode);
    }

    private static string NormalizeBaseUrl(string input)
    {
        var candidate = string.IsNullOrWhiteSpace(input) ? PlatformDefaultBaseUrl : input.Trim();
        if (!candidate.StartsWith("http://", StringComparison.OrdinalIgnoreCase) &&
            !candidate.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            candidate = $"http://{candidate}";
        }

        return candidate.EndsWith("/") ? candidate.TrimEnd('/') : candidate;
    }
}
