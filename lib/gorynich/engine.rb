module Gorynich
  class Engine < ::Rails::Engine
    isolate_namespace Gorynich

    initializer "gorynich.add_middleware" do |app|
      app.middleware.use Gorynich::Head::RackMiddleware
    end
  end
end
