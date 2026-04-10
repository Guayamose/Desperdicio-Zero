using DesperdicioZero.User.Maui.Pages;
using DesperdicioZero.User.Maui.Services;
using Microsoft.Extensions.Logging;

namespace DesperdicioZero.User.Maui;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();

        builder
            .UseMauiApp<App>()
            .ConfigureFonts(fonts =>
            {
            });

#if DEBUG
        builder.Logging.AddDebug();
#endif

        builder.Services.AddSingleton<ApiClient>();
        builder.Services.AddSingleton<UserAppState>();

        builder.Services.AddSingleton<AppShell>();
        builder.Services.AddTransient<HomePage>();
        builder.Services.AddTransient<SettingsPage>();

        return builder.Build();
    }
}
