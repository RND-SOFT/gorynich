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
        [404, { 'Content-Type' => 'text/txt' }, [e.message]]
      rescue Gorynich::TenantNotFound => e
        Rails.logger.error(e.inspect)
        [404, { 'Content-Type' => 'text/txt' }, [e.message]]
      rescue StandardError => e
        Rails.logger.error("Gorynich Error: #{e.inspect}")
        Rails.logger.debug(e.backtrace)
        [500, { 'Content-Type' => 'text/txt' }, ['Gorynich internal error']]
      end
    end
  end
end
