using DesperdicioZero.User.Maui.Models;
using DesperdicioZero.User.Maui.Services;
using Microsoft.Maui.ApplicationModel;

namespace DesperdicioZero.User.Maui.Pages;

public partial class TenantDetailPage : ContentPage
{
    private readonly UserAppState _state;
    private TenantSummary _tenant;
    private bool _isLoading;

    public TenantDetailPage(UserAppState state, TenantSummary tenant)
    {
        InitializeComponent();
        _state = state;
        _tenant = tenant;
        BindingContext = _tenant;
        Title = tenant.Name;
        BindOperatingHours();
        RefreshFavoriteButton();
        RefreshActionButtons();
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        RefreshFavoriteButton();
        RefreshActionButtons();
        await LoadTenantAsync();
    }

    private async Task LoadTenantAsync()
    {
        if (_isLoading)
        {
            return;
        }

        try
        {
            _isLoading = true;
            RefreshControl.IsRefreshing = true;
            MenuLoadingIndicator.IsRunning = true;
            MenuLoadingIndicator.IsVisible = true;

            var tenantTask = _state.Api.GetPublicTenantAsync(_tenant.Slug);
            var menuTask = _state.Api.GetPublicMenuTodayAsync(_tenant.Slug);

            await Task.WhenAll(tenantTask, menuTask);

            _tenant = tenantTask.Result;
            BindingContext = _tenant;
            Title = _tenant.Name;
            BindOperatingHours();
            RefreshFavoriteButton();
            RefreshActionButtons();
            RenderMenu(menuTask.Result);
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
        finally
        {
            _isLoading = false;
            MenuLoadingIndicator.IsRunning = false;
            MenuLoadingIndicator.IsVisible = false;
            RefreshControl.IsRefreshing = false;
        }
    }

    private void BindOperatingHours()
    {
        BindableLayout.SetItemsSource(OperatingHoursLayout, _tenant.OpeningHours);
    }

    private void RenderMenu(DailyMenuDto? menu)
    {
        if (menu is null)
        {
            MenuContent.IsVisible = false;
            EmptyMenuState.IsVisible = true;
            MenuStatsGrid.IsVisible = false;
            MenuStatusLabel.Text = "Pendiente";
            BindableLayout.SetItemsSource(MenuItemsLayout, null);
            return;
        }

        MenuDateLabel.Text = menu.MenuDateText;
        MenuTitleLabel.Text = menu.Title;
        MenuDescriptionLabel.Text = menu.Description;
        MenuDescriptionLabel.IsVisible = menu.HasDescription;
        MenuDishCountLabel.Text = menu.DishCount.ToString();
        MenuHighlightsLabel.Text = menu.HighlightCount.ToString();
        MenuStatusLabel.Text = "Publicado";
        MenuStatsGrid.IsVisible = true;
        MenuContent.IsVisible = true;
        EmptyMenuState.IsVisible = false;
        BindableLayout.SetItemsSource(MenuItemsLayout, menu.DailyMenuItems);
    }

    private async void OnRefreshing(object sender, EventArgs e)
    {
        await LoadTenantAsync();
    }

    private void RefreshFavoriteButton()
    {
        FavoriteButton.Text = _state.IsFavorite(_tenant.Slug) ? "En favoritos" : "Guardar";
    }

    private void RefreshActionButtons()
    {
        OpenMapButton.IsVisible = _tenant.CanOpenMap;
        CallButton.IsVisible = _tenant.CanCall;
        EmailButton.IsVisible = _tenant.CanEmail;
    }

    private void OnToggleFavoriteClicked(object sender, EventArgs e)
    {
        _state.ToggleFavorite(_tenant.Slug);
        RefreshFavoriteButton();
    }

    private async void OnOpenMapClicked(object sender, EventArgs e)
    {
        if (!_tenant.CanOpenMap)
        {
            return;
        }

        var query = Uri.EscapeDataString(_tenant.MapQuery);
        await OpenExternalUriAsync($"https://www.google.com/maps/search/?api=1&query={query}");
    }

    private async void OnCallClicked(object sender, EventArgs e)
    {
        if (!_tenant.CanCall)
        {
            return;
        }

        var phone = new string((_tenant.ContactPhone ?? string.Empty)
            .Where(ch => char.IsDigit(ch) || ch == '+')
            .ToArray());

        if (string.IsNullOrWhiteSpace(phone))
        {
            await DisplayAlert("Contacto", "No se ha podido interpretar el numero de telefono guardado.", "OK");
            return;
        }

        await OpenExternalUriAsync($"tel:{phone}");
    }

    private async void OnEmailClicked(object sender, EventArgs e)
    {
        if (!_tenant.CanEmail)
        {
            return;
        }

        await OpenExternalUriAsync($"mailto:{_tenant.ContactEmail}");
    }

    private async Task OpenExternalUriAsync(string uri)
    {
        try
        {
            await Launcher.Default.OpenAsync(new Uri(uri));
        }
        catch (Exception ex)
        {
            await DisplayAlert("Accion no disponible", ex.Message, "OK");
        }
    }
}
