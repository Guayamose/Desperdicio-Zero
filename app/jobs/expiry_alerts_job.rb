class ExpiryAlertsJob
  include Sidekiq::Job

  sidekiq_options retry: 2, queue: :default

  def perform
    Tenant.find_each do |tenant|
      expired = tenant.inventory_lots.available.where("expires_on < ?", Date.current)
      expired.update_all(status: InventoryLot.statuses[:expired], updated_at: Time.current)

      next if expired.empty?

      AuditLog.create!(
        tenant: tenant,
        action: "inventory.expired_marked",
        entity_type: "InventoryLot",
        entity_id: nil,
        metadata_json: { count: expired.count }
      )
    end
  end
end
