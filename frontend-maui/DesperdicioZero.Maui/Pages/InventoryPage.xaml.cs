using DesperdicioZero.Maui.Models;
using DesperdicioZero.Maui.Services;

namespace DesperdicioZero.Maui.Pages;

public partial class InventoryPage : ContentPage
{
    private readonly AppState _state;
    private List<InventoryLotDto> _lots = [];
    private InventoryLotDto? _editing;

    public InventoryPage() : this(ServiceHelper.GetRequiredService<AppState>())
    {
    }

    public InventoryPage(AppState state)
    {
        InitializeComponent();
        _state = state;

        UnitPicker.ItemsSource = new List<string> { "kg", "g", "l", "ml", "unit" };
        StatusPicker.ItemsSource = new List<string> { "available", "reserved", "consumed", "discarded", "expired" };
        SourcePicker.ItemsSource = new List<string> { "donation", "purchase", "other" };

        UnitPicker.SelectedItem = "unit";
        StatusPicker.SelectedItem = "available";
        SourcePicker.SelectedItem = "donation";
        ExpiresPicker.Date = DateTime.Today.AddDays(7);
        ReceivedPicker.Date = DateTime.Today;
        QuantityEntry.Text = "1";
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadLotsAsync();
    }

    private async Task LoadLotsAsync()
    {
        try
        {
            RefreshControl.IsRefreshing = true;
            _lots = await _state.Api.GetInventoryLotsAsync();
            ApplyFilter();
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

    private void ApplyFilter()
    {
        var query = SearchEntry.Text?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(query))
        {
            LotsList.ItemsSource = _lots.OrderBy(l => l.ExpiresOn).ToList();
            return;
        }

        LotsList.ItemsSource = _lots
            .Where(l =>
                (l.Product.Name ?? string.Empty).Contains(query, StringComparison.OrdinalIgnoreCase)
                || l.Status.Contains(query, StringComparison.OrdinalIgnoreCase)
                || l.Id.ToString().Contains(query, StringComparison.OrdinalIgnoreCase))
            .OrderBy(l => l.ExpiresOn)
            .ToList();
    }

    private InventoryLotInput BuildInput()
    {
        if (!decimal.TryParse(QuantityEntry.Text, out var quantity))
        {
            throw new InvalidOperationException("La cantidad es inválida.");
        }

        return new InventoryLotInput
        {
            Barcode = BarcodeEntry.Text?.Trim(),
            ProductName = ProductNameEntry.Text?.Trim(),
            Quantity = quantity,
            Unit = UnitPicker.SelectedItem?.ToString() ?? "unit",
            Status = StatusPicker.SelectedItem?.ToString() ?? "available",
            Source = SourcePicker.SelectedItem?.ToString() ?? "donation",
            ExpiresOn = ExpiresPicker.Date,
            ReceivedOn = ReceivedPicker.Date,
            Notes = NotesEditor.Text
        };
    }

    private async void OnSaveClicked(object sender, EventArgs e)
    {
        try
        {
            var input = BuildInput();

            if (_editing is null)
            {
                await _state.Api.CreateInventoryLotAsync(input);
            }
            else
            {
                await _state.Api.UpdateInventoryLotAsync(_editing.Id, input);
            }

            ResetForm();
            await LoadLotsAsync();
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private async void OnScanClicked(object sender, EventArgs e)
    {
        try
        {
            var barcode = BarcodeEntry.Text?.Trim();
            if (string.IsNullOrWhiteSpace(barcode))
            {
                await DisplayAlert("Escaneo", "Introduce un código de barras para consultar.", "OK");
                return;
            }

            var product = await _state.Api.ScanBarcodeAsync(barcode, "camera");
            if (product is null)
            {
                await DisplayAlert("Escaneo", "No se pudo resolver el código en la API.", "OK");
                return;
            }

            ProductNameEntry.Text = product.Name;
            await DisplayAlert("Escaneo", $"Producto detectado: {product.Name}", "OK");
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private void OnResetClicked(object sender, EventArgs e)
    {
        ResetForm();
    }

    private void ResetForm()
    {
        _editing = null;
        EditorTitle.Text = "Nuevo lote";
        BarcodeEntry.Text = string.Empty;
        ProductNameEntry.Text = string.Empty;
        QuantityEntry.Text = "1";
        UnitPicker.SelectedItem = "unit";
        StatusPicker.SelectedItem = "available";
        SourcePicker.SelectedItem = "donation";
        ExpiresPicker.Date = DateTime.Today.AddDays(7);
        ReceivedPicker.Date = DateTime.Today;
        NotesEditor.Text = string.Empty;
    }

    private void OnEditClicked(object sender, EventArgs e)
    {
        if (sender is not Button button || button.CommandParameter is not InventoryLotDto lot)
        {
            return;
        }

        _editing = lot;
        EditorTitle.Text = $"Editar lote #{lot.Id}";
        BarcodeEntry.Text = lot.Product.Barcode;
        ProductNameEntry.Text = lot.Product.Name;
        QuantityEntry.Text = lot.Quantity.ToString();
        UnitPicker.SelectedItem = lot.Unit;
        StatusPicker.SelectedItem = lot.Status;
        SourcePicker.SelectedItem = lot.Source;
        ExpiresPicker.Date = lot.ExpiresOn;
        ReceivedPicker.Date = lot.ReceivedOn ?? DateTime.Today;
        NotesEditor.Text = lot.Notes;
    }

    private async void OnDeleteClicked(object sender, EventArgs e)
    {
        if (sender is not Button button || button.CommandParameter is not InventoryLotDto lot)
        {
            return;
        }

        var confirm = await DisplayAlert("Eliminar", $"¿Eliminar lote #{lot.Id}?", "Sí", "No");
        if (!confirm)
        {
            return;
        }

        try
        {
            await _state.Api.DeleteInventoryLotAsync(lot.Id);
            if (_editing?.Id == lot.Id)
            {
                ResetForm();
            }

            await LoadLotsAsync();
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private async void OnRefreshing(object sender, EventArgs e)
    {
        await LoadLotsAsync();
    }

    private void OnSearchChanged(object sender, TextChangedEventArgs e)
    {
        ApplyFilter();
    }
}
