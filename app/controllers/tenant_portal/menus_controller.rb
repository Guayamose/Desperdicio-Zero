module TenantPortal
  class MenusController < TenantPortal::BaseController
    before_action :set_menu, only: [ :show, :edit, :update, :publish ]

    def index
      @menus = tenant_scope(DailyMenu).includes(:daily_menu_items).order(menu_date: :desc)
      authorize DailyMenu
    end

    def show
      authorize @menu
    end

    def new
      @menu = current_tenant.daily_menus.new(menu_date: Date.current)
      @menu.daily_menu_items.build(position: 0)
      authorize @menu
    end

    def create
      @menu = current_tenant.daily_menus.new(menu_params.merge(created_by: current_user, generated_by: :manual))
      authorize @menu

      if @menu.save
        AuditLogger.log!(action: "menu.created", actor: current_user, tenant: current_tenant, entity: @menu, metadata: {}, ip_address: request.remote_ip)
        redirect_to tenant_menu_path(@menu), notice: "Menu creado"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @menu
      @menu.daily_menu_items.build(position: @menu.daily_menu_items.size) if @menu.daily_menu_items.empty?
    end

    def update
      authorize @menu

      if @menu.update(menu_params)
        AuditLogger.log!(action: "menu.updated", actor: current_user, tenant: current_tenant, entity: @menu, metadata: {}, ip_address: request.remote_ip)
        redirect_to tenant_menu_path(@menu), notice: "Menu actualizado"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def generate
      menu_date = parse_menu_date(params[:date])
      menu = current_tenant.daily_menus.find_or_initialize_by(menu_date: menu_date)
      authorize menu, :create?

      if request.get?
        load_generate_context(menu_date)
        return
      end

      generated_menu = Menus::GenerateDailyMenuService.new(tenant: current_tenant, user: current_user).call(
        date: menu_date,
        selected_lot_ids: selected_lot_ids
      )
      redirect_to tenant_menu_path(generated_menu), notice: "Generacion completada"
    rescue Date::Error
      redirect_to tenant_menus_path, alert: "Fecha invalida"
    end

    def publish
      authorize @menu, :publish?
      @menu.update!(status: :published)

      AuditLogger.log!(action: "menu.published", actor: current_user, tenant: current_tenant, entity: @menu, metadata: {}, ip_address: request.remote_ip)
      redirect_to tenant_menu_path(@menu), notice: "Menu publicado"
    end

    private

    def set_menu
      @menu = tenant_scope(DailyMenu).find(params[:id])
    end

    def menu_params
      raw = params.require(:daily_menu).permit(
        :menu_date,
        :title,
        :description,
        :status,
        allergens_json: [],
        daily_menu_items_attributes: [ :id, :name, :description, :position, :_destroy, { ingredients_json: [], allergens_json: [] } ]
      ).to_h

      raw["allergens_json"] = normalize_csv_array(raw["allergens_json"])

      items = raw["daily_menu_items_attributes"] || {}
      items.each_value do |item|
        item["ingredients_json"] = normalize_csv_array(item["ingredients_json"])
        item["allergens_json"] = normalize_csv_array(item["allergens_json"])
      end

      raw
    end

    def normalize_csv_array(value)
      Array(value).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?)
    end

    def parse_menu_date(raw_date)
      raw_date.present? ? Date.parse(raw_date) : Date.current
    end

    def selected_lot_ids
      Array(params[:lot_ids]).map(&:to_i).select { |id| id.positive? }.uniq
    end

    def load_generate_context(menu_date)
      @menu_date = menu_date
      @candidate_lots = Menus::GenerateDailyMenuService.prioritized_lots_for(current_tenant)
      @selected_lot_ids = selected_lot_ids
      @selected_lot_ids = @candidate_lots.map(&:id) if @selected_lot_ids.empty?
      @selected_lots = @candidate_lots.select { |lot| @selected_lot_ids.include?(lot.id) }
      @selected_lots = @candidate_lots if @selected_lots.empty?

      @ingredients_preview = Menus::GenerateDailyMenuService.ingredients_for(@selected_lots)
      @latest_generation = current_tenant.menu_generations.order(created_at: :desc).first
      @menu_for_date = current_tenant.daily_menus.find_by(menu_date: @menu_date)
    end
  end
end
