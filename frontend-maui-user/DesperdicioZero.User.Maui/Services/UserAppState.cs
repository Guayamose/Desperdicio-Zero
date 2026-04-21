using System.ComponentModel;
using System.Runtime.CompilerServices;
using Microsoft.Maui.Storage;

namespace DesperdicioZero.User.Maui.Services;

public class UserAppState : INotifyPropertyChanged
{
    private const string BaseUrlKey = "desperdiciozero.user.api.base_url";
    private const string FavoriteSlugsKey = "desperdiciozero.user.favorite_tenant_slugs";

    private readonly ApiClient _apiClient;
    private string _baseUrl;
    private HashSet<string> _favoriteSlugs;

    public event PropertyChangedEventHandler? PropertyChanged;
    public event EventHandler? BaseUrlChanged;
    public event EventHandler? FavoritesChanged;

    public UserAppState(ApiClient apiClient)
    {
        _apiClient = apiClient;
        _baseUrl = Preferences.Default.Get(BaseUrlKey, ApiClient.PlatformDefaultBaseUrl);
        _favoriteSlugs = LoadFavorites();
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

    public int FavoriteCount => _favoriteSlugs.Count;

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

    public bool IsFavorite(string slug)
    {
        return !string.IsNullOrWhiteSpace(slug) && _favoriteSlugs.Contains(slug.Trim());
    }

    public void ToggleFavorite(string slug)
    {
        if (string.IsNullOrWhiteSpace(slug))
        {
            return;
        }

        var normalized = slug.Trim();
        if (!_favoriteSlugs.Add(normalized))
        {
            _favoriteSlugs.Remove(normalized);
        }

        SaveFavorites();
    }

    private HashSet<string> LoadFavorites()
    {
        var raw = Preferences.Default.Get(FavoriteSlugsKey, string.Empty);

        return raw
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);
    }

    private void SaveFavorites()
    {
        var serialized = string.Join(",", _favoriteSlugs.OrderBy(slug => slug, StringComparer.OrdinalIgnoreCase));
        Preferences.Default.Set(FavoriteSlugsKey, serialized);
        OnPropertyChanged(nameof(FavoriteCount));
        FavoritesChanged?.Invoke(this, EventArgs.Empty);
    }

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}
