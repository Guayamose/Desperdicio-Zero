class Rack::Attack
  throttle("scan_requests_per_ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.include?("/inventory/scan")
  end

  throttle("menu_generation_per_ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.path.include?("/menus/generate")
  end

  self.throttled_responder = lambda do |request|
    [
      429,
      { "Content-Type" => "application/json" },
      [ { code: "rate_limited", message: "Too many requests", requestId: request.get_header("action_dispatch.request_id") }.to_json ]
    ]
  end
end
