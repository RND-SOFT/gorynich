module Gorynich
  class Engine < ::Rails::Engine
    isolate_namespace Gorynich

    initializer 'gorynich.add_middleware' do |app|
      app.middleware.insert_after ActionDispatch::RemoteIp, Gorynich::Head::RackMiddleware
      app.config.active_record.writing_role = :default
      app.config.hosts.clear
    end
  end
end
