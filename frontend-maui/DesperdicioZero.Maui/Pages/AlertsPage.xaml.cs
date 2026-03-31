using DesperdicioZero.Maui.Services;

namespace DesperdicioZero.Maui.Pages;

public partial class AlertsPage : ContentPage
{
    private readonly AppState _state;

    public AlertsPage() : this(ServiceHelper.GetRequiredService<AppState>())
    {
    }

    public AlertsPage(AppState state)
    {
        InitializeComponent();
        _state = state;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadAsync();
    }

    private async Task LoadAsync()
    {
        try
        {
            RefreshControl.IsRefreshing = true;
            var data = await _state.Api.GetAlertsAsync();
            ExpiringList.ItemsSource = data.Expiring;
            ExpiredList.ItemsSource = data.Expired;
            SummaryLabel.Text = $"{data.Expiring.Count} por caducar, {data.Expired.Count} vencidos.";
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
        await LoadAsync();
    }
}
