using Microsoft.Extensions.DependencyInjection;

namespace DesperdicioZero.User.Maui.Services;

public static class ServiceHelper
{
    public static IServiceProvider? Services { get; private set; }

    public static void Initialize(IServiceProvider services)
    {
        Services = services;
    }

    public static T GetRequiredService<T>() where T : notnull
    {
        if (Services is null)
        {
            throw new InvalidOperationException("Service provider not initialized.");
        }

        return Services.GetRequiredService<T>();
    }
}
