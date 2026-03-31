using DesperdicioZero.Maui.Models;
using DesperdicioZero.Maui.Services;

namespace DesperdicioZero.Maui.Pages;

public partial class PublicTenantsPage : ContentPage
{
    private readonly AppState _state;
    private List<TenantSummary> _tenants = [];

    public PublicTenantsPage() : this(ServiceHelper.GetRequiredService<AppState>())
    {
    }

    public PublicTenantsPage(AppState state)
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
        if (RefreshControl.IsRefreshing)
        {
            return;
        }

        try
        {
            RefreshControl.IsRefreshing = true;
            _tenants = await _state.Api.GetPublicTenantsAsync();
            ApplyFilter();
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
        finally
        {
            RefreshControl.IsRefreshing = false;
        }
    }

    private void ApplyFilter()
    {
        var query = SearchEntry.Text?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(query))
        {
            TenantsList.ItemsSource = _tenants;
            return;
        }

        TenantsList.ItemsSource = _tenants.Where(t =>
            t.Name.Contains(query, StringComparison.OrdinalIgnoreCase)
            || (t.City ?? string.Empty).Contains(query, StringComparison.OrdinalIgnoreCase)
            || (t.Region ?? string.Empty).Contains(query, StringComparison.OrdinalIgnoreCase));
    }

    private async void OnOpenMenuClicked(object sender, EventArgs e)
    {
        if (sender is not Button button || button.CommandParameter is not TenantSummary tenant)
        {
            return;
        }

        try
        {
            var menu = await _state.Api.GetPublicMenuTodayAsync(tenant.Slug);
            MenuFrame.IsVisible = true;
            MenuTenantLabel.Text = tenant.Name;

            if (menu is null)
            {
                MenuTitleLabel.Text = "Sin menú publicado hoy";
                MenuDescriptionLabel.Text = "Este comedor aún no publicó su menú diario.";
                MenuItemsList.ItemsSource = null;
                return;
            }

            MenuTitleLabel.Text = menu.Title;
            MenuDescriptionLabel.Text = menu.Description;
            MenuItemsList.ItemsSource = menu.DailyMenuItems;
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
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
