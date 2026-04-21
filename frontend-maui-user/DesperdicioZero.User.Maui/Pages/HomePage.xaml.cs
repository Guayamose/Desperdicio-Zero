using DesperdicioZero.User.Maui.Models;
using DesperdicioZero.User.Maui.Services;
using Microsoft.Maui.Graphics;

namespace DesperdicioZero.User.Maui.Pages;

public partial class HomePage : ContentPage
{
    private enum TenantFilter
    {
        All,
        Favorites,
        MenuToday,
        Contact
    }

    private readonly UserAppState _state;
    private List<TenantSummary> _tenants = [];
    private bool _isLoading;
    private TenantFilter _activeFilter = TenantFilter.All;
    private string? _lastLoadedBaseUrl;

    public HomePage() : this(ServiceHelper.GetRequiredService<UserAppState>())
    {
    }

    public HomePage(UserAppState state)
    {
        InitializeComponent();
        _state = state;
        _state.FavoritesChanged += OnFavoritesChanged;
        _state.BaseUrlChanged += OnBaseUrlChanged;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();

        if (_tenants.Count == 0 || !string.Equals(_lastLoadedBaseUrl, _state.BaseUrl, StringComparison.OrdinalIgnoreCase))
        {
            await LoadTenantsAsync();
            return;
        }

        RefreshSummary();
        ApplyFilter();
    }

    private async Task LoadTenantsAsync()
    {
        if (_isLoading)
        {
            return;
        }

        try
        {
            _isLoading = true;
            RefreshControl.IsRefreshing = true;
            HideError();
            BaseUrlLabel.Text = $"Backend: {_state.BaseUrl}";
            _tenants = await _state.Api.GetPublicTenantsAsync();
            _lastLoadedBaseUrl = _state.BaseUrl;
            UpdateFavoriteState();
            RefreshSummary();
            ApplyFilter();
        }
        catch (Exception ex)
        {
            ShowError(ex.Message);
        }
        finally
        {
            _isLoading = false;
            RefreshControl.IsRefreshing = false;
        }
    }

    private void ApplyFilter()
    {
        var query = SearchEntry.Text?.Trim() ?? string.Empty;

        UpdateFavoriteState();

        IEnumerable<TenantSummary> filtered = _activeFilter switch
        {
            TenantFilter.Favorites => _tenants.Where(tenant => tenant.IsFavorite),
            TenantFilter.MenuToday => TenantsWithMenu(),
            TenantFilter.Contact => _tenants.Where(tenant => tenant.HasContact),
            _ => _tenants
        };

        if (!string.IsNullOrWhiteSpace(query))
        {
            filtered = filtered.Where(tenant =>
                tenant.Name.Contains(query, StringComparison.OrdinalIgnoreCase)
                || (tenant.City ?? string.Empty).Contains(query, StringComparison.OrdinalIgnoreCase)
                || (tenant.Region ?? string.Empty).Contains(query, StringComparison.OrdinalIgnoreCase)
                || (tenant.Country ?? string.Empty).Contains(query, StringComparison.OrdinalIgnoreCase)
                || (tenant.TodayMenuTitle ?? string.Empty).Contains(query, StringComparison.OrdinalIgnoreCase));
        }

        var ordered = filtered
            .OrderByDescending(tenant => tenant.IsFavorite)
            .ThenByDescending(tenant => tenant.HasTodayMenu)
            .ThenBy(tenant => tenant.Name, StringComparer.OrdinalIgnoreCase)
            .ToList();

        TenantsList.ItemsSource = ordered;
        ResultsLabel.Text = ordered.Count switch
        {
            0 => BuildEmptyResultText(query),
            1 => BuildSingleResultText(),
            _ => $"{ordered.Count} comedores visibles en este momento."
        };

        LastUpdatedLabel.Text = _tenants.Count == 0
            ? "Aun no se ha sincronizado el directorio."
            : $"Favoritos arriba. Ultima sincronizacion desde {_state.BaseUrl}.";
        UpdateFilterButtons();
    }

    private async void OnOpenTenantClicked(object sender, EventArgs e)
    {
        if (sender is not Button button || button.CommandParameter is not TenantSummary tenant)
        {
            return;
        }

        await Shell.Current.Navigation.PushAsync(new TenantDetailPage(_state, tenant));
    }

    private async void OnRefreshing(object sender, EventArgs e)
    {
        await LoadTenantsAsync();
    }

    private void OnSearchChanged(object sender, TextChangedEventArgs e)
    {
        ApplyFilter();
    }

    private void OnAllFilterClicked(object sender, EventArgs e)
    {
        _activeFilter = TenantFilter.All;
        ApplyFilter();
    }

    private void OnFavoritesFilterClicked(object sender, EventArgs e)
    {
        _activeFilter = TenantFilter.Favorites;
        ApplyFilter();
    }

    private void OnMenuFilterClicked(object sender, EventArgs e)
    {
        _activeFilter = TenantFilter.MenuToday;
        ApplyFilter();
    }

    private void OnContactFilterClicked(object sender, EventArgs e)
    {
        _activeFilter = TenantFilter.Contact;
        ApplyFilter();
    }

    private void OnToggleFavoriteClicked(object sender, EventArgs e)
    {
        if (sender is not Button button || button.CommandParameter is not TenantSummary tenant)
        {
            return;
        }

        _state.ToggleFavorite(tenant.Slug);
        UpdateFavoriteState();
        RefreshSummary();
        ApplyFilter();
    }

    private async void OnRetryClicked(object sender, EventArgs e)
    {
        await LoadTenantsAsync();
    }

    private void OnFavoritesChanged(object? sender, EventArgs e)
    {
        Dispatcher.Dispatch(() =>
        {
            UpdateFavoriteState();
            RefreshSummary();
            ApplyFilter();
        });
    }

    private void OnBaseUrlChanged(object? sender, EventArgs e)
    {
        Dispatcher.Dispatch(() =>
        {
            BaseUrlLabel.Text = $"Backend: {_state.BaseUrl}";
        });
    }

    private void RefreshSummary()
    {
        SummaryTenantsLabel.Text = _tenants.Count.ToString();
        SummaryMenusLabel.Text = TenantsWithMenu().Count().ToString();
        SummaryFavoritesLabel.Text = _state.FavoriteCount.ToString();
        BaseUrlLabel.Text = $"Backend: {_state.BaseUrl}";
    }

    private void UpdateFavoriteState()
    {
        foreach (var tenant in _tenants)
        {
            tenant.IsFavorite = _state.IsFavorite(tenant.Slug);
        }
    }

    private void UpdateFilterButtons()
    {
        SetFilterButtonState(AllFilterButton, _activeFilter == TenantFilter.All);
        SetFilterButtonState(FavoritesFilterButton, _activeFilter == TenantFilter.Favorites);
        SetFilterButtonState(MenuFilterButton, _activeFilter == TenantFilter.MenuToday);
        SetFilterButtonState(ContactFilterButton, _activeFilter == TenantFilter.Contact);
    }

    private void SetFilterButtonState(Button button, bool isActive)
    {
        button.BackgroundColor = isActive
            ? Color.FromArgb("#2F6B4F")
            : Color.FromArgb("#00000000");
        button.TextColor = isActive
            ? Colors.White
            : Color.FromArgb("#214A37");
        button.BorderColor = isActive
            ? Color.FromArgb("#2F6B4F")
            : Color.FromArgb("#DCCFB8");
        button.BorderWidth = isActive ? 0 : 1;
    }

    private void ShowError(string message)
    {
        ErrorLabel.Text = message;
        ErrorBanner.IsVisible = true;
    }

    private void HideError()
    {
        ErrorBanner.IsVisible = false;
        ErrorLabel.Text = string.Empty;
    }

    private string BuildEmptyResultText(string query)
    {
        if (_activeFilter == TenantFilter.Favorites)
        {
            return "Todavia no tienes favoritos que coincidan con el filtro actual.";
        }

        return string.IsNullOrWhiteSpace(query)
            ? "No hay resultados con el filtro actual."
            : "No hay coincidencias con la busqueda actual.";
    }

    private string BuildSingleResultText()
    {
        return _activeFilter == TenantFilter.Favorites
            ? "1 favorito coincide con tu seleccion."
            : "1 comedor visible en este momento.";
    }

    private IEnumerable<TenantSummary> TenantsWithMenu()
    {
        return _tenants.Where(tenant => tenant.HasTodayMenu);
    }
}
