using DesperdicioZero.Maui.Pages;
using DesperdicioZero.Maui.Services;
using Microsoft.Extensions.Logging;

namespace DesperdicioZero.Maui;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();

        builder
            .UseMauiApp<App>()
            .ConfigureFonts(fonts =>
            {
                // If custom fonts are added later, register them here.
            });

#if DEBUG
        builder.Logging.AddDebug();
#endif

        builder.Services.AddSingleton<ApiClient>();
        builder.Services.AddSingleton<AppState>();

        builder.Services.AddTransient<AppShell>();
        builder.Services.AddTransient<LoginPage>();
        builder.Services.AddTransient<PublicTenantsPage>();
        builder.Services.AddTransient<TenantDashboardPage>();
        builder.Services.AddTransient<InventoryPage>();
        builder.Services.AddTransient<AlertsPage>();
        builder.Services.AddTransient<MenusPage>();
        builder.Services.AddTransient<EmployeesPage>();
        builder.Services.AddTransient<AdminConsolePage>();
        builder.Services.AddTransient<ProfilePage>();

        return builder.Build();
    }
}
