using DesperdicioZero.User.Maui.Models;
using DesperdicioZero.User.Maui.Services;

namespace DesperdicioZero.User.Maui.Pages;

public partial class HomePage : ContentPage
{
    private readonly UserAppState _state;
    private List<TenantSummary> _tenants = [];
    private bool _isLoading;

    public HomePage() : this(ServiceHelper.GetRequiredService<UserAppState>())
    {
    }

    public HomePage(UserAppState state)
    {
        InitializeComponent();
        _state = state;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadTenantsAsync();
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
            BaseUrlLabel.Text = $"Backend: {_state.BaseUrl}";
            _tenants = await _state.Api.GetPublicTenantsAsync();
            ApplyFilter();
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
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

        var filtered = string.IsNullOrWhiteSpace(query)
            ? _tenants
            : _tenants.Where(tenant =>
                    tenant.Name.Contains(query, StringComparison.OrdinalIgnoreCase)
                    || (tenant.City ?? string.Empty).Contains(query, StringComparison.OrdinalIgnoreCase)
                    || (tenant.Region ?? string.Empty).Contains(query, StringComparison.OrdinalIgnoreCase)
                    || (tenant.Country ?? string.Empty).Contains(query, StringComparison.OrdinalIgnoreCase))
                .ToList();

        TenantsList.ItemsSource = filtered;
        ResultsLabel.Text = filtered.Count switch
        {
            0 => "No hay coincidencias con la busqueda actual.",
            1 => "1 comedor disponible.",
            _ => $"{filtered.Count} comedores disponibles."
        };
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
}
