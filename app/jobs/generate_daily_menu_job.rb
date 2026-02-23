class GenerateDailyMenuJob
  include Sidekiq::Job

  sidekiq_options retry: 5, queue: :critical

  def perform(tenant_id, user_id = nil, date = nil)
    tenant = Tenant.find(tenant_id)
    user = User.find_by(id: user_id)
    Menus::GenerateDailyMenuService.new(tenant: tenant, user: user).call(
      date: date.present? ? Date.parse(date) : Date.current
    )
  end
end
