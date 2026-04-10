using DesperdicioZero.User.Maui.Models;
using DesperdicioZero.User.Maui.Services;

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
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
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
            EmptyMenuLabel.IsVisible = true;
            BindableLayout.SetItemsSource(MenuItemsLayout, null);
            return;
        }

        MenuDateLabel.Text = menu.MenuDateText;
        MenuTitleLabel.Text = menu.Title;
        MenuDescriptionLabel.Text = menu.Description;
        MenuDescriptionLabel.IsVisible = menu.HasDescription;
        MenuContent.IsVisible = true;
        EmptyMenuLabel.IsVisible = false;
        BindableLayout.SetItemsSource(MenuItemsLayout, menu.DailyMenuItems);
    }

    private async void OnRefreshing(object sender, EventArgs e)
    {
        await LoadTenantAsync();
    }
}
