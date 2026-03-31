using DesperdicioZero.Maui.Models;
using DesperdicioZero.Maui.Services;

namespace DesperdicioZero.Maui.Pages;

public partial class MenusPage : ContentPage
{
    private readonly AppState _state;
    private readonly List<MenuItemInput> _draftItems = [];
    private List<DailyMenuDto> _menus = [];
    private DailyMenuDto? _editingMenu;

    public MenusPage() : this(ServiceHelper.GetRequiredService<AppState>())
    {
    }

    public MenusPage(AppState state)
    {
        InitializeComponent();
        _state = state;
        MenuDatePicker.Date = DateTime.Today;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadMenusAsync();
    }

    private async Task LoadMenusAsync()
    {
        try
        {
            RefreshControl.IsRefreshing = true;
            _menus = await _state.Api.GetMenusAsync();
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
        var query = MenuSearchEntry.Text?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(query))
        {
            MenusList.ItemsSource = _menus.OrderByDescending(m => m.MenuDate).ToList();
            return;
        }

        MenusList.ItemsSource = _menus
            .Where(m =>
                m.Title.Contains(query, StringComparison.OrdinalIgnoreCase)
                || (m.Status ?? string.Empty).Contains(query, StringComparison.OrdinalIgnoreCase)
                || (m.GeneratedBy ?? string.Empty).Contains(query, StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(m => m.MenuDate)
            .ToList();
    }

    private void SyncDraftList()
    {
        DishDraftList.ItemsSource = null;
        DishDraftList.ItemsSource = _draftItems.ToList();
    }

    private MenuInput BuildMenuInput()
    {
        return new MenuInput
        {
            MenuDate = MenuDatePicker.Date,
            Title = MenuTitleEntry.Text?.Trim() ?? string.Empty,
            Description = MenuDescriptionEditor.Text,
            AllergensCsv = MenuAllergensEntry.Text ?? string.Empty,
            Items = _draftItems.Select((item, idx) => new MenuItemInput
            {
                Id = item.Id,
                Name = item.Name,
                Description = item.Description,
                Position = idx,
                Servings = 1,
                Repetitions = 1,
                IngredientsCsv = item.IngredientsCsv,
                AllergensCsv = item.AllergensCsv,
                Destroy = false
            }).ToList()
        };
    }

    private void ResetEditor()
    {
        _editingMenu = null;
        MenuEditorTitle.Text = "Nuevo menú";
        MenuDatePicker.Date = DateTime.Today;
        MenuTitleEntry.Text = string.Empty;
        MenuDescriptionEditor.Text = string.Empty;
        MenuAllergensEntry.Text = string.Empty;
        DishNameEntry.Text = string.Empty;
        _draftItems.Clear();
        SyncDraftList();
    }

    private void LoadMenuIntoEditor(DailyMenuDto menu)
    {
        _editingMenu = menu;
        MenuEditorTitle.Text = $"Editar menú #{menu.Id}";
        MenuDatePicker.Date = menu.MenuDate;
        MenuTitleEntry.Text = menu.Title;
        MenuDescriptionEditor.Text = menu.Description;
        MenuAllergensEntry.Text = string.Join(", ", menu.AllergensJson);

        _draftItems.Clear();
        foreach (var item in menu.DailyMenuItems.OrderBy(i => i.Position))
        {
            _draftItems.Add(new MenuItemInput
            {
                Id = item.Id,
                Name = item.Name,
                Description = item.Description,
                Position = item.Position,
                IngredientsCsv = string.Join(", ", item.IngredientsJson),
                AllergensCsv = string.Join(", ", item.AllergensJson)
            });
        }

        SyncDraftList();
    }

    private void OnAddDishClicked(object sender, EventArgs e)
    {
        var name = DishNameEntry.Text?.Trim();
        if (string.IsNullOrWhiteSpace(name))
        {
            return;
        }

        _draftItems.Add(new MenuItemInput
        {
            Name = name,
            Position = _draftItems.Count
        });

        DishNameEntry.Text = string.Empty;
        SyncDraftList();
    }

    private void OnRemoveDishClicked(object sender, EventArgs e)
    {
        if (sender is not Button button || button.CommandParameter is not MenuItemInput item)
        {
            return;
        }

        _draftItems.Remove(item);
        SyncDraftList();
    }

    private async void OnSaveMenuClicked(object sender, EventArgs e)
    {
        try
        {
            var input = BuildMenuInput();
            if (string.IsNullOrWhiteSpace(input.Title))
            {
                await DisplayAlert("Validación", "El título del menú es obligatorio.", "OK");
                return;
            }

            if (_editingMenu is null)
            {
                var created = await _state.Api.CreateMenuAsync(input);
                LoadMenuIntoEditor(created);
            }
            else
            {
                var updated = await _state.Api.UpdateMenuAsync(_editingMenu.Id, input);
                LoadMenuIntoEditor(updated);
            }

            await LoadMenusAsync();
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private async void OnGenerateClicked(object sender, EventArgs e)
    {
        try
        {
            var generated = await _state.Api.GenerateMenuAsync(MenuDatePicker.Date);
            LoadMenuIntoEditor(generated);
            await LoadMenusAsync();
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private void OnResetMenuClicked(object sender, EventArgs e)
    {
        ResetEditor();
    }

    private void OnEditMenuClicked(object sender, EventArgs e)
    {
        if (sender is not Button button || button.CommandParameter is not DailyMenuDto menu)
        {
            return;
        }

        LoadMenuIntoEditor(menu);
    }

    private async void OnPublishMenuClicked(object sender, EventArgs e)
    {
        if (sender is not Button button || button.CommandParameter is not DailyMenuDto menu)
        {
            return;
        }

        try
        {
            await _state.Api.PublishMenuAsync(menu.Id);
            await LoadMenusAsync();

            if (_editingMenu?.Id == menu.Id)
            {
                var refreshed = _menus.FirstOrDefault(m => m.Id == menu.Id);
                if (refreshed is not null)
                {
                    LoadMenuIntoEditor(refreshed);
                }
            }
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private async void OnDeleteMenuClicked(object sender, EventArgs e)
    {
        if (sender is not Button button || button.CommandParameter is not DailyMenuDto menu)
        {
            return;
        }

        var confirm = await DisplayAlert("Eliminar", $"¿Eliminar menú '{menu.Title}'?", "Sí", "No");
        if (!confirm)
        {
            return;
        }

        try
        {
            await _state.Api.DeleteMenuAsync(menu.Id);
            if (_editingMenu?.Id == menu.Id)
            {
                ResetEditor();
            }

            await LoadMenusAsync();
        }
        catch (Exception ex)
        {
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private async void OnRefreshing(object sender, EventArgs e)
    {
        await LoadMenusAsync();
    }

    private void OnMenuSearchChanged(object sender, TextChangedEventArgs e)
    {
        ApplyFilter();
    }
}
