module Gorynich
  class Engine < ::Rails::Engine
    isolate_namespace Gorynich

    initializer 'gorynich.add_middleware' do |app|
      after_middleware = Rails.env.development? ? ActionDispatch::Reloader : ActionDispatch::RemoteIp
      app.middleware.insert_after after_middleware, Gorynich::Head::RackMiddleware
      app.config.active_record.writing_role = :default
      app.config.hosts.clear
    end
  end
end
