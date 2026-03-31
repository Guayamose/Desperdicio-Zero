using DesperdicioZero.Maui.Services;

namespace DesperdicioZero.Maui.Pages;

public partial class LoginPage : ContentPage
{
    private readonly AppState _state;

    public LoginPage(AppState state)
    {
        InitializeComponent();
        _state = state;

        BaseUrlEntry.Text = _state.BaseUrl;
#if DEBUG
        EmailEntry.Text = "admin@socialkitchen.local";
        PasswordEntry.Text = "ChangeMe123!";
#endif
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();

        if (_state.IsAuthenticated)
        {
            ((App)Application.Current!).NavigateToShell();
        }
    }

    private async void OnLoginClicked(object sender, EventArgs e)
    {
        ErrorLabel.IsVisible = false;
        LoginButton.IsEnabled = false;

        try
        {
            _state.UpdateBaseUrl(BaseUrlEntry.Text ?? string.Empty);
            await _state.LoginAsync(EmailEntry.Text?.Trim() ?? string.Empty, PasswordEntry.Text ?? string.Empty);

            if (_state.User?.MustChangePassword == true)
            {
                await DisplayAlert("Cambio de contraseña", "Tu cuenta requiere actualizar contraseña en el apartado Perfil.", "OK");
            }

            ((App)Application.Current!).NavigateToShell();
        }
        catch (ApiException apiEx)
        {
            ErrorLabel.Text = apiEx.Message;
            ErrorLabel.IsVisible = true;
        }
        catch (Exception ex)
        {
            ErrorLabel.Text = $"Error de conexión: {ex.Message}";
            ErrorLabel.IsVisible = true;
        }
        finally
        {
            LoginButton.IsEnabled = true;
        }
    }
}
