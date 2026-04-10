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
}
