using DesperdicioZero.User.Maui.Models;
using DesperdicioZero.User.Maui.Services;
using Microsoft.Maui.ApplicationModel;

namespace DesperdicioZero.User.Maui.Pages;

public partial class TenantDetailPage : ContentPage
{
    private readonly UserAppState _state;
    private TenantSummary _tenant;
    private bool _isLoading;
    private bool _usingFallbackData;

    public TenantDetailPage(UserAppState state, TenantSummary tenant)
    {
        InitializeComponent();
        _state = state;
        _tenant = tenant;
        BindingContext = _tenant;
        Title = tenant.Name;
        BindOperatingHours();
        BindRecentMenus();
        RefreshFavoriteButton();
        RefreshActionButtons();
        ResetMenuState();
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

            try
            {
                var tenantTask = _state.Api.GetPublicTenantAsync(_tenant.Slug);
                var menuTask = _state.Api.GetPublicMenuTodayAsync(_tenant.Slug);

                await Task.WhenAll(tenantTask, menuTask);

                _tenant = tenantTask.Result;
                _usingFallbackData = false;
                BindingContext = _tenant;
                Title = _tenant.Name;
                BindOperatingHours();
                BindRecentMenus();
                RefreshFavoriteButton();
                RefreshActionButtons();
                RenderMenu(menuTask.Result);
            }
            catch
            {
                var bundledTenant = await _state.Api.GetBundledPublicTenantAsync(_tenant.Slug);
                if (bundledTenant is null)
                {
                    throw;
                }

                _tenant = bundledTenant;
                _usingFallbackData = true;
                BindingContext = _tenant;
                Title = _tenant.Name;
                BindOperatingHours();
                BindRecentMenus();
                RefreshFavoriteButton();
                RefreshActionButtons();
                RenderMenu(null);
            }
        }
        catch (Exception ex)
        {
            _usingFallbackData = false;
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

    private void BindRecentMenus()
    {
        RecentMenusCard.IsVisible = _tenant.HasRecentMenus;
        BindableLayout.SetItemsSource(RecentMenusLayout, _tenant.RecentMenus);
    }

    private void ResetMenuState()
    {
        MenuDateLabel.Text = string.Empty;
        MenuDateLabel.IsVisible = false;
        MenuTitleLabel.Text = _usingFallbackData ? "Menu no disponible sin backend" : "Menu pendiente";
        MenuDescriptionLabel.Text = _usingFallbackData
            ? "Mostrando la informacion local del seed web. Para ver el menu diario en tiempo real necesitas el backend activo."
            : _tenant.StatusDetailText;
        MenuDescriptionLabel.IsVisible = true;
        MenuStatusLabel.Text = "Pendiente";
        MenuStatsGrid.IsVisible = false;
        MenuContent.IsVisible = false;
        EmptyMenuState.IsVisible = false;
        BindableLayout.SetItemsSource(MenuItemsLayout, null);
    }

    private void RenderMenu(DailyMenuDto? menu)
    {
        if (menu is null)
        {
            ResetMenuState();
            EmptyMenuState.IsVisible = true;
            return;
        }

        MenuDateLabel.Text = menu.MenuDateText;
        MenuDateLabel.IsVisible = !string.IsNullOrWhiteSpace(MenuDateLabel.Text);
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
        OpenMapButton.Text = _tenant.MapActionLabel;
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
        if (string.IsNullOrWhiteSpace(_tenant.MapLink))
        {
            return;
        }

        await OpenExternalUriAsync(_tenant.MapLink);
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
