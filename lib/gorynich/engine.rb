module Gorynich
  class Engine < ::Rails::Engine
    isolate_namespace Gorynich

    initializer 'gorynich.add_middleware' do |app|
      app.middleware.insert_after ActionDispatch::RemoteIp, Gorynich::Head::RackMiddleware
    end
  end
end
