# connects_to database:
module Gorynich
  module Head
    class RackMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        @config ||= Gorynich.instance
        @config.actualize

        tenant, opts = Gorynich.switcher.analyze(env)

        Gorynich.with(tenant, **opts) do
          if Rails.logger.respond_to?(:tagged)
            Rails.logger.tagged("Tenant(#{tenant})") { @app.call(env) }
          else
            @app.call(env)
          end
        end
      rescue Gorynich::UriNotFound => e
        Rails.logger.error(e.inspect)
        [404, { 'Content-Type' => 'text/plain', 'charset' => 'UTF-8' }, [e.message]]
      rescue Gorynich::HostNotFound => e
        Rails.logger.error(e.inspect)
        [404, { 'Content-Type' => 'text/plain', 'charset' => 'UTF-8' }, [e.message]]
      rescue Gorynich::TenantNotFound => e
        Rails.logger.error(e.inspect)
        [404, { 'Content-Type' => 'text/plain', 'charset' => 'UTF-8' }, [e.message]]
      end
    end
  end
end
