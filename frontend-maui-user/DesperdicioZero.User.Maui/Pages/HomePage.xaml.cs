using DesperdicioZero.User.Maui.Models;
using DesperdicioZero.User.Maui.Services;
using Microsoft.Maui.Controls;
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
    private DateTimeOffset? _lastLoadedAt;
    private bool _usingFallbackData;

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
            LoadingIndicator.IsVisible = true;
            LoadingIndicator.IsRunning = true;
            HideError();

            try
            {
                _tenants = await _state.Api.GetPublicTenantsAsync();
                _usingFallbackData = false;
            }
            catch
            {
                _tenants = await _state.Api.GetBundledPublicTenantsAsync();
                _usingFallbackData = true;
            }

            _lastLoadedBaseUrl = _state.BaseUrl;
            _lastLoadedAt = DateTimeOffset.Now;

            UpdateFavoriteState();
            BuildSuggestionChips();
            RefreshSummary();
            ApplyFilter();
        }
        catch (Exception ex)
        {
            _usingFallbackData = false;
            ShowError(ex.Message);
        }
        finally
        {
            _isLoading = false;
            RefreshControl.IsRefreshing = false;
            LoadingIndicator.IsRunning = false;
            LoadingIndicator.IsVisible = false;
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
            TenantFilter.Contact => TenantsWithContact(),
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
            _ => $"{ordered.Count} comedores disponibles ahora."
        };

        LastUpdatedLabel.Text = BuildLastUpdatedText();
        UpdateFilterButtons();
        RefreshSuggestionChipState();
    }

    private async void OnOpenTenantClicked(object sender, EventArgs e)
    {
        if (sender is not Button button || button.CommandParameter is not TenantSummary tenant)
        {
            return;
        }

        await OpenTenantAsync(tenant);
    }

    private async void OnTenantCardTapped(object sender, TappedEventArgs e)
    {
        if (sender is not TapGestureRecognizer tapGesture || tapGesture.BindingContext is not TenantSummary tenant)
        {
            return;
        }

        await OpenTenantAsync(tenant);
    }

    private async Task OpenTenantAsync(TenantSummary tenant)
    {
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
            LastUpdatedLabel.Text = BuildLastUpdatedText();
        });
    }

    private void RefreshSummary()
    {
        SummaryTenantsLabel.Text = _tenants.Count.ToString();
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
            : Colors.White;
        button.TextColor = isActive
            ? Colors.White
            : Color.FromArgb("#214A37");
        button.BorderColor = isActive
            ? Color.FromArgb("#2F6B4F")
            : Color.FromArgb("#DCCFB8");
        button.BorderWidth = 1;
    }

    private void BuildSuggestionChips()
    {
        SuggestionChipsLayout.Children.Clear();

        var suggestions = _tenants
            .Select(tenant => tenant.City)
            .Where(city => !string.IsNullOrWhiteSpace(city))
            .Select(city => city!.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(city => city, StringComparer.OrdinalIgnoreCase)
            .Take(6)
            .ToList();

        if (suggestions.Count == 0)
        {
            return;
        }

        foreach (var suggestion in suggestions)
        {
            var button = new Button
            {
                Text = suggestion
            };

            if (Application.Current?.Resources.TryGetValue("ChipButtonStyle", out var styleResource) == true
                && styleResource is Style chipButtonStyle)
            {
                button.Style = chipButtonStyle;
            }

            button.Clicked += OnSuggestionChipClicked;
            SuggestionChipsLayout.Children.Add(button);
        }

        RefreshSuggestionChipState();
    }

    private void RefreshSuggestionChipState()
    {
        var query = SearchEntry.Text?.Trim() ?? string.Empty;

        foreach (var child in SuggestionChipsLayout.Children)
        {
            if (child is not Button button)
            {
                continue;
            }

            var isActive = !string.IsNullOrWhiteSpace(query)
                && string.Equals(button.Text, query, StringComparison.OrdinalIgnoreCase);

            button.BackgroundColor = isActive
                ? Color.FromArgb("#2F6B4F")
                : Colors.White;
            button.TextColor = isActive
                ? Colors.White
                : Color.FromArgb("#214A37");
            button.BorderColor = isActive
                ? Color.FromArgb("#2F6B4F")
                : Color.FromArgb("#DCCFB8");
            button.BorderWidth = 1;
        }
    }

    private void OnSuggestionChipClicked(object? sender, EventArgs e)
    {
        if (sender is not Button button)
        {
            return;
        }

        SearchEntry.Text = string.Equals(SearchEntry.Text?.Trim(), button.Text, StringComparison.OrdinalIgnoreCase)
            ? string.Empty
            : button.Text;
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
            : "1 comedor disponible ahora.";
    }

    private string BuildLastUpdatedText()
    {
        if (_usingFallbackData)
        {
            return "Sin conexion con el backend. Mostrando la copia local del listado.";
        }

        if (_lastLoadedAt is null)
        {
            return "Actualizacion del listado pendiente.";
        }

        return $"Actualizado el {_lastLoadedAt.Value:dd/MM/yyyy} a las {_lastLoadedAt.Value:HH:mm}.";
    }

    private IEnumerable<TenantSummary> TenantsWithMenu()
    {
        return _tenants.Where(tenant => tenant.HasTodayMenu);
    }

    private IEnumerable<TenantSummary> TenantsWithContact()
    {
        return _tenants.Where(tenant => tenant.HasContact);
    }
}
