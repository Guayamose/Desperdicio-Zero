class Current < ActiveSupport::CurrentAttributes
  attribute :user, :tenant, :request_id
end
