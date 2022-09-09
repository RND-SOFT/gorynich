Rails.application.middleware.tap do |middleware|
  middleware.insert_before ActionDispatch::RemoteIp, Gorynich::Head::RackMiddleware
end
