using System.ComponentModel;
using System.Runtime.CompilerServices;
using DesperdicioZero.Maui.Models;
using Microsoft.Maui.Storage;

namespace DesperdicioZero.Maui.Services;

public class AppState : INotifyPropertyChanged
{
    private const string BaseUrlKey = "desperdiciozero.api.base_url";

    private readonly ApiClient _apiClient;
    private SessionData? _session;
    private string _baseUrl;

    public event PropertyChangedEventHandler? PropertyChanged;
    public event EventHandler? SessionChanged;

    public AppState(ApiClient apiClient)
    {
        _apiClient = apiClient;
        _baseUrl = Preferences.Default.Get(BaseUrlKey, ApiClient.PlatformDefaultBaseUrl);
        _apiClient.SetBaseUrl(_baseUrl);
    }

    public SessionData? Session
    {
        get => _session;
        private set
        {
            _session = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(User));
            OnPropertyChanged(nameof(CurrentTenant));
            OnPropertyChanged(nameof(IsAuthenticated));
            OnPropertyChanged(nameof(IsSystemAdmin));
            SessionChanged?.Invoke(this, EventArgs.Empty);
        }
    }

    public UserSession? User => Session?.User;
    public TenantSummary? CurrentTenant => Session?.CurrentTenant;
    public bool IsAuthenticated => Session?.User is not null;
    public bool IsSystemAdmin => Session?.User?.SystemAdmin ?? false;
    public ApiClient Api => _apiClient;

    public string BaseUrl
    {
        get => _baseUrl;
        private set
        {
            _baseUrl = value;
            OnPropertyChanged();
        }
    }

    public async Task<bool> TryRestoreSessionAsync()
    {
        try
        {
            Session = await _apiClient.GetSessionAsync();
            return Session?.User is not null;
        }
        catch
        {
            Session = null;
            return false;
        }
    }

    public void ApplySession(SessionData? session)
    {
        Session = session;
    }

    public async Task LoginAsync(string email, string password)
    {
        Session = await _apiClient.LoginAsync(email, password);
    }

    public async Task LogoutAsync()
    {
        try
        {
            await _apiClient.LogoutAsync();
        }
        finally
        {
            Session = null;
        }
    }

    public async Task SwitchTenantAsync(int tenantId)
    {
        Session = await _apiClient.SwitchTenantAsync(tenantId);
    }

    public void UpdateBaseUrl(string baseUrl)
    {
        _apiClient.SetBaseUrl(baseUrl);
        BaseUrl = _apiClient.BaseUrl;
        Preferences.Default.Set(BaseUrlKey, BaseUrl);
    }

    private void OnPropertyChanged([CallerMemberName] string? name = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    }
}
