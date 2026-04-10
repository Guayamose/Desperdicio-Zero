using System.ComponentModel;
using System.Runtime.CompilerServices;
using Microsoft.Maui.Storage;

namespace DesperdicioZero.User.Maui.Services;

public class UserAppState : INotifyPropertyChanged
{
    private const string BaseUrlKey = "desperdiciozero.user.api.base_url";

    private readonly ApiClient _apiClient;
    private string _baseUrl;

    public event PropertyChangedEventHandler? PropertyChanged;
    public event EventHandler? BaseUrlChanged;

    public UserAppState(ApiClient apiClient)
    {
        _apiClient = apiClient;
        _baseUrl = Preferences.Default.Get(BaseUrlKey, ApiClient.PlatformDefaultBaseUrl);
        _apiClient.SetBaseUrl(_baseUrl);
    }

    public ApiClient Api => _apiClient;

    public string BaseUrl
    {
        get => _baseUrl;
        private set
        {
            _baseUrl = value;
            OnPropertyChanged();
            BaseUrlChanged?.Invoke(this, EventArgs.Empty);
        }
    }

    public void UpdateBaseUrl(string baseUrl)
    {
        _apiClient.SetBaseUrl(baseUrl);
        BaseUrl = _apiClient.BaseUrl;
        Preferences.Default.Set(BaseUrlKey, BaseUrl);
    }

    public void RestoreDefaultBaseUrl()
    {
        UpdateBaseUrl(ApiClient.PlatformDefaultBaseUrl);
    }

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}
