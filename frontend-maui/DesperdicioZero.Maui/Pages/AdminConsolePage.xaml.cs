using System.Text.Json;
using DesperdicioZero.Maui.Models;
using DesperdicioZero.Maui.Services;

namespace DesperdicioZero.Maui.Pages;

public partial class AdminConsolePage : ContentPage
{
    private readonly AppState _state;
    private List<TenantSummary> _tenants = [];
    private List<AdminUserDto> _users = [];
    private TenantSummary? _editingTenant;

    public AdminConsolePage() : this(ServiceHelper.GetRequiredService<AppState>())
    {
    }

    public AdminConsolePage(AppState state)
    {
        InitializeComponent();
        _state = state;

        TenantStatusPicker.ItemsSource = new List<string> { "active", "inactive", "suspended" };
        TenantStatusPicker.SelectedItem = "active";

        UserRolePicker.ItemsSource = new List<string> { "tenant_staff", "tenant_manager" };
        UserRolePicker.SelectedItem = "tenant_staff";
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();

        if (_state.IsSystemAdmin == false)
        {
            await DisplayAlert("Acceso", "Esta sección es solo para administradores globales.", "OK");
            return;
        }

        await LoadAllAsync();
    }

    private async Task LoadAllAsync()
    {
        try
        {
            RefreshControl.IsRefreshing = true;

            var metrics = await _state.Api.GetAdminMetricsAsync();
            MetricsLabel.Text = $"Tenants: {metrics.Tenants} | Activos: {metrics.ActiveTenants} | Usuarios: {metrics.Users} | Lotes: {metrics.InventoryLots} | Vencidos: {metrics.ExpiredLots} | Menús hoy: {metrics.MenusToday} | Éxito IA: {metrics.AiSuccessRatio:P0}";

            _tenants = await _state.Api.GetAdminTenantsAsync();
            TenantsList.ItemsSource = _tenants;

            var pickerSource = new List<TenantSummary> { new TenantSummary { Id = 0, Name = "Sin asignar" } };
            pickerSource.AddRange(_tenants);
            UserTenantPicker.ItemsSource = pickerSource;
            UserTenantPicker.ItemDisplayBinding = new Binding("Name");
            UserTenantPicker.SelectedIndex = 0;

            _users = await _state.Api.GetAdminUsersAsync();
            UsersList.ItemsSource = _users;

            AuditList.ItemsSource = await _state.Api.GetAdminAuditLogsAsync();
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

    private TenantInput BuildTenantInput()
    {
        var slug = TenantSlugEntry.Text?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(slug))
        {
            slug = (TenantNameEntry.Text ?? string.Empty)
                .Trim()
                .ToLowerInvariant()
                .Replace(" ", "-");
        }

        return new TenantInput
        {
            Name = TenantNameEntry.Text?.Trim() ?? string.Empty,
            Slug = slug,
            Status = TenantStatusPicker.SelectedItem?.ToString() ?? "active",
            City = TenantCityEntry.Text?.Trim(),
            Country = "ES",
            OperatingHoursJson = new Dictionary<string, string>
            {
                { "Lunes", "09:00-15:00" }
            }
        };
    }

    private void ResetTenantEditor()
    {
        _editingTenant = null;
        TenantEditorTitle.Text = "Nuevo comedor";
        TenantNameEntry.Text = string.Empty;
        TenantSlugEntry.Text = string.Empty;
        TenantCityEntry.Text = string.Empty;
        TenantStatusPicker.SelectedItem = "active";
    }

    private async void OnSaveTenantClicked(object sender, EventArgs e)
    {
        try
        {
            var input = BuildTenantInput();
            if (string.IsNullOrWhiteSpace(input.Name))
            {
                await DisplayAlert("Validación", "El nombre del comedor es obligatorio.", "OK");
                return;
            }

            if (_editingTenant is null)
            {
                await _state.Api.CreateAdminTenantAsync(input);
            }
            else
            {
                await _state.Api.UpdateAdminTenantAsync(_editingTenant.Id, input);
            }

            ResetTenantEditor();
            await LoadAllAsync();
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private void OnResetTenantClicked(object sender, EventArgs e)
    {
        ResetTenantEditor();
    }

    private void OnEditTenantClicked(object sender, EventArgs e)
    {
        if (sender is Button button && button.CommandParameter is TenantSummary tenant)
        {
            _editingTenant = tenant;
            TenantEditorTitle.Text = $"Editar comedor #{tenant.Id}";
            TenantNameEntry.Text = tenant.Name;
            TenantSlugEntry.Text = tenant.Slug;
            TenantCityEntry.Text = tenant.City;
            TenantStatusPicker.SelectedItem = tenant.Status;
        }
    }

    private async void OnDeleteTenantClicked(object sender, EventArgs e)
    {
        if (sender is Button button && button.CommandParameter is TenantSummary tenant)
        {
            var confirm = await DisplayAlert("Eliminar", $"¿Eliminar comedor {tenant.Name}?", "Sí", "No");
            if (confirm == false)
            {
                return;
            }

            try
            {
                await _state.Api.DeleteAdminTenantAsync(tenant.Id);
                if (_editingTenant?.Id == tenant.Id)
                {
                    ResetTenantEditor();
                }

                await LoadAllAsync();
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", ex.Message, "OK");
            }
        }
    }

    private async void OnCreateUserClicked(object sender, EventArgs e)
    {
        try
        {
            TempUserPasswordLabel.IsVisible = false;
            var selectedTenant = UserTenantPicker.SelectedItem as TenantSummary;

            var input = new AdminUserInput
            {
                FullName = UserNameEntry.Text?.Trim() ?? string.Empty,
                Email = UserEmailEntry.Text?.Trim() ?? string.Empty,
                Locale = "es",
                TenantId = selectedTenant is null || selectedTenant.Id == 0 ? null : selectedTenant.Id,
                Role = UserRolePicker.SelectedItem?.ToString() ?? "tenant_staff",
                SystemAdmin = SystemAdminSwitch.IsToggled
            };

            if (string.IsNullOrWhiteSpace(input.FullName) || string.IsNullOrWhiteSpace(input.Email))
            {
                await DisplayAlert("Validación", "Nombre y email son obligatorios.", "OK");
                return;
            }

            var result = await _state.Api.CreateAdminUserAsync(input);
            TempUserPasswordLabel.Text = $"Password temporal: {result.temporaryPassword}";
            TempUserPasswordLabel.IsVisible = string.IsNullOrWhiteSpace(result.temporaryPassword) == false;

            UserNameEntry.Text = string.Empty;
            UserEmailEntry.Text = string.Empty;
            UserRolePicker.SelectedItem = "tenant_staff";
            UserTenantPicker.SelectedIndex = 0;
            SystemAdminSwitch.IsToggled = false;

            await LoadAllAsync();
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private async void OnBlockUserClicked(object sender, EventArgs e)
    {
        if (sender is Button button && button.CommandParameter is AdminUserDto user)
        {
            try
            {
                await _state.Api.BlockAdminUserAsync(user.Id);
                await LoadAllAsync();
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", ex.Message, "OK");
            }
        }
    }

    private async void OnAnonymizeUserClicked(object sender, EventArgs e)
    {
        if (sender is Button button && button.CommandParameter is AdminUserDto user)
        {
            var confirm = await DisplayAlert("Anonimizar", $"¿Anonimizar datos de {user.FullName}?", "Sí", "No");
            if (confirm == false)
            {
                return;
            }

            try
            {
                await _state.Api.AnonymizeAdminUserAsync(user.Id);
                await LoadAllAsync();
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", ex.Message, "OK");
            }
        }
    }

    private async void OnExportUserClicked(object sender, EventArgs e)
    {
        if (sender is Button button && button.CommandParameter is AdminUserDto user)
        {
            try
            {
                var exportData = await _state.Api.ExportAdminUserAsync(user.Id);
                var pretty = exportData.HasValue ? JsonSerializer.Serialize(exportData.Value, new JsonSerializerOptions { WriteIndented = true }) : "Sin datos";
                if (pretty.Length > 1200)
                {
                    pretty = pretty[..1200] + "...";
                }

                await DisplayAlert("Export user", pretty, "OK");
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", ex.Message, "OK");
            }
        }
    }

    private async void OnRefreshing(object sender, EventArgs e)
    {
        await LoadAllAsync();
    }
}
