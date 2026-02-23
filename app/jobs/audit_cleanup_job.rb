class AuditCleanupJob
  include Sidekiq::Job

  sidekiq_options retry: 1, queue: :low

  RETENTION_PERIOD = 24.months

  def perform
    AuditLog.where("created_at < ?", RETENTION_PERIOD.ago).delete_all
  end
end
