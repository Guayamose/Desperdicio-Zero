using DesperdicioZero.Maui.Models;
using DesperdicioZero.Maui.Services;

namespace DesperdicioZero.Maui.Pages;

public partial class EmployeesPage : ContentPage
{
    private readonly AppState _state;
    private List<EmployeeMembershipDto> _employees = [];

    public EmployeesPage() : this(ServiceHelper.GetRequiredService<AppState>())
    {
    }

    public EmployeesPage(AppState state)
    {
        InitializeComponent();
        _state = state;
        EmployeeRolePicker.ItemsSource = new List<string> { "tenant_staff", "tenant_manager" };
        EmployeeRolePicker.SelectedItem = "tenant_staff";
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadEmployeesAsync();
    }

    private async Task LoadEmployeesAsync()
    {
        try
        {
            RefreshControl.IsRefreshing = true;
            _employees = await _state.Api.GetEmployeesAsync();
            EmployeesList.ItemsSource = _employees;
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

    private async void OnCreateClicked(object sender, EventArgs e)
    {
        try
        {
            TempPasswordLabel.IsVisible = false;

            var input = new EmployeeInput
            {
                FullName = EmployeeNameEntry.Text?.Trim() ?? string.Empty,
                Email = EmployeeEmailEntry.Text?.Trim() ?? string.Empty,
                Locale = "es",
                Role = EmployeeRolePicker.SelectedItem?.ToString() ?? "tenant_staff"
            };

            if (string.IsNullOrWhiteSpace(input.FullName) || string.IsNullOrWhiteSpace(input.Email))
            {
                await DisplayAlert("Validación", "Nombre y email son obligatorios.", "OK");
                return;
            }

            var result = await _state.Api.CreateEmployeeAsync(input);

            TempPasswordLabel.Text = $"Contraseña temporal: {result.temporaryPassword}";
            TempPasswordLabel.IsVisible = string.IsNullOrWhiteSpace(result.temporaryPassword) == false;

            EmployeeNameEntry.Text = string.Empty;
            EmployeeEmailEntry.Text = string.Empty;
            EmployeeRolePicker.SelectedItem = "tenant_staff";

            await LoadEmployeesAsync();
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private async Task UpdateRoleAsync(object sender, string role)
    {
        if (sender is Button button && button.CommandParameter is EmployeeMembershipDto employee)
        {
            try
            {
                await _state.Api.UpdateEmployeeRoleAsync(employee.Id, role);
                await LoadEmployeesAsync();
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", ex.Message, "OK");
            }
        }
    }

    private async void OnSetManagerClicked(object sender, EventArgs e)
    {
        await UpdateRoleAsync(sender, "tenant_manager");
    }

    private async void OnSetStaffClicked(object sender, EventArgs e)
    {
        await UpdateRoleAsync(sender, "tenant_staff");
    }

    private async void OnDeleteClicked(object sender, EventArgs e)
    {
        if (sender is Button button && button.CommandParameter is EmployeeMembershipDto employee)
        {
            var confirm = await DisplayAlert("Eliminar", $"¿Eliminar a {employee.User.FullName}?", "Sí", "No");
            if (confirm == false)
            {
                return;
            }

            try
            {
                await _state.Api.DeleteEmployeeAsync(employee.Id);
                await LoadEmployeesAsync();
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", ex.Message, "OK");
            }
        }
    }

    private async void OnRefreshing(object sender, EventArgs e)
    {
        await LoadEmployeesAsync();
    }
}
