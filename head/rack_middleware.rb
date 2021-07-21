# connects_to database:
module Gorynich
  module Head
    class RackMiddleware
      def initialize(app)
        @app = app
      end

      def call(env) # rubocop:disable Metrics/AbcSize
        @config ||= Gorynich.instance
        @config.actualize

        tenant, opts = Gorynich.switcher.analyze(env)

        Gorynich.with(tenant, opts) do
          if Rails.logger.respond_to?(:tagged)
            Rails.logger.tagged("Tenant(#{tenant})") { @app.call(env) }
          else
            @app.call(env)
          end
        end
      rescue Gorynich::DomainNotFound, Gorynich::TenantNotFound => e
        Rails.logger.error(e.inspect)
        file = File.read('public/tenant_error.html')
        [404, { 'Content-Type' => 'text/html', 'Content-Length' => file.size.to_s }, [file]]
      rescue StandardError => e
        Rails.logger.error("Gorynich Error: #{e.inspect}")
        Rails.logger.debug(e.backtrace)
        file = File.read('public/tenant_error.html')
        [404, { 'Content-Type' => 'text/html', 'Content-Length' => file.size.to_s }, [file]]
      end
    end
  end
end
