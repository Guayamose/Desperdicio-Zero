using DesperdicioZero.Maui.Models;
using DesperdicioZero.Maui.Services;

namespace DesperdicioZero.Maui.Pages;

public partial class ProfilePage : ContentPage
{
    private readonly AppState _state;
    private List<TenantOption> _tenantOptions = [];

    public ProfilePage() : this(ServiceHelper.GetRequiredService<AppState>())
    {
    }

    public ProfilePage(AppState state)
    {
        InitializeComponent();
        _state = state;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadProfileAsync();
    }

    private async Task LoadProfileAsync()
    {
        try
        {
            await _state.TryRestoreSessionAsync();

            BaseUrlEntry.Text = _state.BaseUrl;
            UserEmailLabel.Text = _state.User?.Email ?? "";
            FullNameEntry.Text = _state.User?.FullName ?? "";

            _tenantOptions = _state.Session?.Memberships
                .Where(m => m.Active && m.Tenant is not null)
                .Select(m => new TenantOption
                {
                    TenantId = m.TenantId,
                    Label = (m.Tenant?.Name ?? "Tenant") + " (" + m.Role + ")"
                })
                .ToList() ?? [];

            TenantPicker.ItemsSource = _tenantOptions;
            var currentTenant = _state.CurrentTenant;
            if (currentTenant is not null)
            {
                TenantPicker.SelectedItem = _tenantOptions.FirstOrDefault(x => x.TenantId == currentTenant.Id);
            }
            else if (_tenantOptions.Count > 0)
            {
                TenantPicker.SelectedIndex = 0;
            }
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private async void OnUpdateBaseUrlClicked(object sender, EventArgs e)
    {
        _state.UpdateBaseUrl(BaseUrlEntry.Text ?? string.Empty);
        await DisplayAlert("Conexión", "URL actualizada.", "OK");
    }

    private async void OnSaveProfileClicked(object sender, EventArgs e)
    {
        try
        {
            var updated = await _state.Api.UpdateProfileAsync(new ProfileInput
            {
                FullName = FullNameEntry.Text?.Trim() ?? string.Empty
            });

            _state.ApplySession(updated);
            await DisplayAlert("Perfil", "Datos actualizados.", "OK");
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private async void OnChangePasswordClicked(object sender, EventArgs e)
    {
        try
        {
            await _state.Api.UpdatePasswordAsync(NewPasswordEntry.Text ?? string.Empty, ConfirmPasswordEntry.Text ?? string.Empty);
            NewPasswordEntry.Text = string.Empty;
            ConfirmPasswordEntry.Text = string.Empty;
            await _state.TryRestoreSessionAsync();
            await DisplayAlert("Contraseña", "Contraseña actualizada correctamente.", "OK");
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private async void OnSwitchTenantClicked(object sender, EventArgs e)
    {
        if (TenantPicker.SelectedItem is not TenantOption selected)
        {
            await DisplayAlert("Tenant", "Selecciona un comedor.", "OK");
            return;
        }

        try
        {
            await _state.SwitchTenantAsync(selected.TenantId);
            await DisplayAlert("Tenant", "Comedor activo actualizado.", "OK");
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private async void OnLogoutClicked(object sender, EventArgs e)
    {
        await _state.LogoutAsync();
        ((App)Application.Current!).NavigateToLogin();
    }

    private class TenantOption
    {
        public int TenantId { get; set; }
        public string Label { get; set; } = string.Empty;
    }
}
