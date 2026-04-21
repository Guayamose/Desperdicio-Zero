using System.Text.Json.Serialization;

namespace DesperdicioZero.User.Maui.Models;

public class ApiEnvelope<T>
{
    [JsonPropertyName("data")]
    public T? Data { get; set; }
}

public class ApiError
{
    [JsonPropertyName("code")]
    public string? Code { get; set; }

    [JsonPropertyName("message")]
    public string? Message { get; set; }
}

public sealed record OpeningHoursEntry(string Day, string Hours);

public class TenantSummary
{
    private static readonly string[] DayOrder =
    [
        "lunes",
        "martes",
        "miercoles",
        "jueves",
        "viernes",
        "sabado",
        "domingo"
    ];

    private static readonly Dictionary<string, string> DayLabels = new(StringComparer.OrdinalIgnoreCase)
    {
        ["lunes"] = "Lunes",
        ["martes"] = "Martes",
        ["miercoles"] = "Miercoles",
        ["jueves"] = "Jueves",
        ["viernes"] = "Viernes",
        ["sabado"] = "Sabado",
        ["domingo"] = "Domingo"
    };

    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("slug")]
    public string Slug { get; set; } = string.Empty;

    [JsonPropertyName("status")]
    public string Status { get; set; } = string.Empty;

    [JsonPropertyName("address")]
    public string? Address { get; set; }

    [JsonPropertyName("city")]
    public string? City { get; set; }

    [JsonPropertyName("region")]
    public string? Region { get; set; }

    [JsonPropertyName("country")]
    public string? Country { get; set; }

    [JsonPropertyName("contactEmail")]
    public string? ContactEmail { get; set; }

    [JsonPropertyName("contactPhone")]
    public string? ContactPhone { get; set; }

    [JsonPropertyName("operatingHoursJson")]
    public Dictionary<string, string>? OperatingHoursJson { get; set; }

    [JsonPropertyName("todayMenuPublished")]
    public bool TodayMenuPublished { get; set; }

    [JsonPropertyName("todayMenuTitle")]
    public string? TodayMenuTitle { get; set; }

    [JsonPropertyName("todayMenuDate")]
    public DateTime? TodayMenuDate { get; set; }

    [JsonIgnore]
    public bool IsFavorite { get; set; }

    [JsonIgnore]
    public string StatusLabel => string.IsNullOrWhiteSpace(Status)
        ? "Disponible"
        : Status.Replace('_', ' ').Trim() switch
        {
            var raw when raw.Equals("active", StringComparison.OrdinalIgnoreCase) => "Abierto",
            var raw when raw.Equals("inactive", StringComparison.OrdinalIgnoreCase) => "Sin servicio",
            var raw when raw.Equals("suspended", StringComparison.OrdinalIgnoreCase) => "Suspendido",
            var raw => char.ToUpperInvariant(raw[0]) + raw[1..]
        };

    [JsonIgnore]
    public string LocationText => JoinParts(City, Region, Country);

    [JsonIgnore]
    public string AddressText => JoinParts(Address, City, Region, Country);

    [JsonIgnore]
    public bool HasLocation => !string.IsNullOrWhiteSpace(LocationText);

    [JsonIgnore]
    public string ContactText => JoinParts(ContactPhone, ContactEmail);

    [JsonIgnore]
    public bool HasContact => !string.IsNullOrWhiteSpace(ContactText);

    [JsonIgnore]
    public bool HasAddress => !string.IsNullOrWhiteSpace(Address);

    [JsonIgnore]
    public bool HasTodayMenu => TodayMenuPublished;

    [JsonIgnore]
    public bool CanCall => !string.IsNullOrWhiteSpace(ContactPhone);

    [JsonIgnore]
    public bool CanEmail => !string.IsNullOrWhiteSpace(ContactEmail);

    [JsonIgnore]
    public bool CanOpenMap => !string.IsNullOrWhiteSpace(MapQuery);

    [JsonIgnore]
    public string MenuAvailabilityLabel => HasTodayMenu ? "Menu disponible hoy" : "Menu pendiente";

    [JsonIgnore]
    public string MenuPreviewText => HasTodayMenu
        ? string.IsNullOrWhiteSpace(TodayMenuTitle) ? "Ya hay menu publicado para hoy." : TodayMenuTitle!
        : "Todavia no hay un menu publicado para hoy.";

    [JsonIgnore]
    public string FavoriteButtonText => IsFavorite ? "Guardado" : "Guardar";

    [JsonIgnore]
    public string PrimaryActionLabel => HasTodayMenu ? "Ver comedor y menu" : "Ver detalles";

    [JsonIgnore]
    public string MapQuery => JoinParts(Name, Address, City, Region, Country);

    [JsonIgnore]
    public IReadOnlyList<OpeningHoursEntry> OpeningHours
    {
        get
        {
            var normalized = (OperatingHoursJson ?? new Dictionary<string, string>())
                .Where(entry => !string.IsNullOrWhiteSpace(entry.Value))
                .ToDictionary(entry => entry.Key.Trim(), entry => entry.Value.Trim(), StringComparer.OrdinalIgnoreCase);

            var ordered = DayOrder
                .Where(normalized.ContainsKey)
                .Select(day => new OpeningHoursEntry(DayLabels[day], normalized[day]))
                .ToList();

            var extras = normalized.Keys
                .Except(DayOrder, StringComparer.OrdinalIgnoreCase)
                .OrderBy(day => day, StringComparer.OrdinalIgnoreCase)
                .Select(day => new OpeningHoursEntry(day, normalized[day]));

            ordered.AddRange(extras);
            return ordered;
        }
    }

    [JsonIgnore]
    public bool HasOperatingHours => OpeningHours.Count > 0;

    [JsonIgnore]
    public string ScheduleSummary
    {
        get
        {
            var firstRow = OpeningHours.FirstOrDefault();
            return firstRow is null ? "Horario no disponible" : $"{firstRow.Day}: {firstRow.Hours}";
        }
    }

    [JsonIgnore]
    public string ScheduleDetail => HasOperatingHours
        ? $"{OpeningHours.Count} franjas disponibles"
        : "Sin horario confirmado";

    private static string JoinParts(params string?[] parts)
    {
        return string.Join(" · ", parts.Where(part => !string.IsNullOrWhiteSpace(part)).Select(part => part!.Trim()));
    }
}

public class DailyMenuItemDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("ingredientsJson")]
    public List<string> IngredientsJson { get; set; } = [];

    [JsonPropertyName("allergensJson")]
    public List<string> AllergensJson { get; set; } = [];

    [JsonPropertyName("dietaryFlagsJson")]
    public List<string> DietaryFlagsJson { get; set; } = [];

    [JsonIgnore]
    public string IngredientsText => JoinValues(IngredientsJson, "Ingredientes no especificados");

    [JsonIgnore]
    public string AllergensText => JoinValues(AllergensJson, "Sin alergenos destacados");

    [JsonIgnore]
    public string DietaryFlagsText => JoinValues(DietaryFlagsJson, "Sin etiquetas adicionales");

    [JsonIgnore]
    public bool HasDescription => !string.IsNullOrWhiteSpace(Description);

    [JsonIgnore]
    public bool HasIngredients => CleanValues(IngredientsJson).Count > 0;

    [JsonIgnore]
    public bool HasAllergens => CleanValues(AllergensJson).Count > 0;

    [JsonIgnore]
    public bool HasDietaryFlags => CleanValues(DietaryFlagsJson).Count > 0;

    [JsonIgnore]
    public string IngredientsLabel => $"Ingredientes: {IngredientsText}";

    [JsonIgnore]
    public string AllergensLabel => $"Alergenos: {AllergensText}";

    [JsonIgnore]
    public string DietaryFlagsLabel => $"Etiquetas: {DietaryFlagsText}";

    private static string JoinValues(IEnumerable<string> values, string emptyText)
    {
        var clean = CleanValues(values).ToArray();

        return clean.Length == 0 ? emptyText : string.Join(", ", clean);
    }

    private static IReadOnlyList<string> CleanValues(IEnumerable<string> values)
    {
        return values
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .Select(value => value.Trim())
            .ToArray();
    }
}

public class DailyMenuDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("menuDate")]
    public DateTime MenuDate { get; set; }

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("dailyMenuItems")]
    public List<DailyMenuItemDto> DailyMenuItems { get; set; } = [];

    [JsonIgnore]
    public string MenuDateText => MenuDate == default ? string.Empty : MenuDate.ToString("dddd, dd MMMM", new System.Globalization.CultureInfo("es-ES"));

    [JsonIgnore]
    public bool HasDescription => !string.IsNullOrWhiteSpace(Description);

    [JsonIgnore]
    public bool HasItems => DailyMenuItems.Count > 0;

    [JsonIgnore]
    public int DishCount => DailyMenuItems.Count;

    [JsonIgnore]
    public string DishCountText => DishCount switch
    {
        0 => "Sin platos",
        1 => "1 plato",
        _ => $"{DishCount} platos"
    };

    [JsonIgnore]
    public int HighlightCount => DailyMenuItems.Sum(item => item.DietaryFlagsJson.Count);

    [JsonIgnore]
    public string HighlightCountText => HighlightCount switch
    {
        0 => "Sin etiquetas",
        1 => "1 etiqueta",
        _ => $"{HighlightCount} etiquetas"
    };
}
