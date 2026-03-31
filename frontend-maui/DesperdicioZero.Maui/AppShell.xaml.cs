using DesperdicioZero.Maui.Services;

namespace DesperdicioZero.Maui;

public partial class AppShell : Shell
{
    private readonly AppState _state;

    public AppShell(AppState state)
    {
        InitializeComponent();
        _state = state;
        BindingContext = state;

        _state.SessionChanged += OnSessionChanged;
        ApplyVisibility();
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        ApplyVisibility();
    }

    private void OnSessionChanged(object? sender, EventArgs e)
    {
        MainThread.BeginInvokeOnMainThread(ApplyVisibility);
    }

    private void ApplyVisibility()
    {
        TenantFlyout.IsVisible = _state.CurrentTenant is not null;
        AdminFlyout.IsVisible = _state.IsSystemAdmin;
    }
}
