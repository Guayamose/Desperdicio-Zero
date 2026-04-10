using DesperdicioZero.User.Maui.Services;
using Microsoft.Extensions.DependencyInjection;

namespace DesperdicioZero.User.Maui;

public partial class App : Application
{
    public App(IServiceProvider services)
    {
        InitializeComponent();
        ServiceHelper.Initialize(services);
        MainPage = services.GetRequiredService<AppShell>();
    }
}
