using DesperdicioZero.User.Maui.Services;

namespace DesperdicioZero.User.Maui.Pages;

public partial class SettingsPage : ContentPage
{
    private readonly UserAppState _state;

    public SettingsPage() : this(ServiceHelper.GetRequiredService<UserAppState>())
    {
    }

    public SettingsPage(UserAppState state)
    {
        InitializeComponent();
        _state = state;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        RefreshForm();
    }

    private void RefreshForm()
    {
        BaseUrlEntry.Text = _state.BaseUrl;
        SavedUrlLabel.Text = $"Guardada: {_state.BaseUrl}";
        FavoritesCountLabel.Text = _state.FavoriteCount switch
        {
            0 => "No tienes favoritos guardados todavia.",
            1 => "Tienes 1 comedor guardado como favorito.",
            _ => $"Tienes {_state.FavoriteCount} comedores guardados como favoritos."
        };
        ConnectionStatusLabel.Text = "Comprueba la conexion antes de cambiar de entorno si quieres validar la API publica.";
    }

    private async void OnSaveClicked(object sender, EventArgs e)
    {
        try
        {
            _state.UpdateBaseUrl(BaseUrlEntry.Text ?? string.Empty);
            RefreshForm();
            await DisplayAlert("Ajustes", "La URL del backend se ha actualizado.", "OK");
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private async void OnResetClicked(object sender, EventArgs e)
    {
        _state.RestoreDefaultBaseUrl();
        RefreshForm();
        await DisplayAlert("Ajustes", "Se ha restaurado la URL por defecto.", "OK");
    }

    private async void OnTestClicked(object sender, EventArgs e)
    {
        try
        {
            ConnectionStatusLabel.Text = "Probando conexion con la API publica...";
            var tenants = await _state.Api.GetPublicTenantsAsync();
            var menusToday = tenants.Count(tenant => tenant.HasTodayMenu);

            ConnectionStatusLabel.Text = tenants.Count switch
            {
                0 => "Conexion correcta, pero no hay comedores operativos visibles en este entorno.",
                _ => $"Conexion correcta: {tenants.Count} comedores visibles y {menusToday} con menu hoy."
            };
        }
        catch (Exception ex)
        {
            ConnectionStatusLabel.Text = $"Fallo de conexion: {ex.Message}";
        }
    }
}
