using DesperdicioZero.Maui.Pages;
using DesperdicioZero.Maui.Services;
using Microsoft.Maui.ApplicationModel;

namespace DesperdicioZero.Maui;

public partial class App : Application
{
    private readonly AppState _state;
    private readonly IServiceProvider _services;

    public App(AppState state, IServiceProvider services)
    {
        InitializeComponent();
        _state = state;
        _services = services;
        ServiceHelper.Initialize(services);

        MainPage = new ContentPage
        {
            BackgroundColor = Color.FromArgb("#F8FAFC"),
            Content = new Grid
            {
                Children =
                {
                    new ActivityIndicator
                    {
                        IsRunning = true,
                        Color = Color.FromArgb("#059669"),
                        VerticalOptions = LayoutOptions.Center,
                        HorizontalOptions = LayoutOptions.Center
                    }
                }
            }
        };

        _ = BootstrapAsync();
    }

    private async Task BootstrapAsync()
    {
        var restored = await _state.TryRestoreSessionAsync();

        MainThread.BeginInvokeOnMainThread(() =>
        {
            MainPage = restored
                ? _services.GetRequiredService<AppShell>()
                : new NavigationPage(_services.GetRequiredService<LoginPage>());
        });
    }

    public void NavigateToShell()
    {
        MainPage = _services.GetRequiredService<AppShell>();
    }

    public void NavigateToLogin()
    {
        MainPage = new NavigationPage(_services.GetRequiredService<LoginPage>());
    }
}
