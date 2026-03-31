using DesperdicioZero.Maui.Services;

namespace DesperdicioZero.Maui.Pages;

public partial class TenantDashboardPage : ContentPage
{
    private readonly AppState _state;

    public TenantDashboardPage() : this(ServiceHelper.GetRequiredService<AppState>())
    {
    }

    public TenantDashboardPage(AppState state)
    {
        InitializeComponent();
        _state = state;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadDashboardAsync();
    }

    private async Task LoadDashboardAsync()
    {
        try
        {
            RefreshControl.IsRefreshing = true;
            var dashboard = await _state.Api.GetTenantDashboardAsync();

            TenantLabel.Text = dashboard.Tenant?.Name ?? _state.CurrentTenant?.Name ?? "Mi comedor";
            InventoryMetric.Text = dashboard.Metrics.InventoryCount.ToString();
            ExpiringMetric.Text = dashboard.Metrics.ExpiringCount.ToString();
            TodayMenuMetric.Text = dashboard.Metrics.TodayMenuCount.ToString();
            LatencyMetric.Text = dashboard.Metrics.LatestGenerationLatencyMs is int ms ? $"{ms} ms" : "---";

            if (dashboard.TodayMenu is null)
            {
                TodayMenuTitle.Text = "No hay menú publicado";
                TodayMenuDescription.Text = "Genera uno desde la sección Menús.";
            }
            else
            {
                TodayMenuTitle.Text = dashboard.TodayMenu.Title;
                TodayMenuDescription.Text = dashboard.TodayMenu.Description;
            }
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

    private async void OnRefreshing(object sender, EventArgs e)
    {
        await LoadDashboardAsync();
    }
}
