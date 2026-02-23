class AuditLogger
  def self.log!(action:, actor:, tenant:, entity:, metadata: {}, ip_address: nil)
    AuditLog.create!(
      action: action,
      actor: actor,
      tenant: tenant,
      entity_type: entity.class.name,
      entity_id: entity.id,
      metadata_json: metadata,
      ip_address: ip_address
    )
  end
end
