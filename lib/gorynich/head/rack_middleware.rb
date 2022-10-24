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

        tenant, opts =
          Gorynich.switcher.analyze(env) do
            host = env['SERVER_NAME']
            tenant = Gorynich.instance.tenant_by_host(host)
            uri = Gorynich.instance.uri_by_host(host, tenant)
            [tenant, { host: host, uri: uri }]
          end

        Gorynich.with(tenant, **opts) do
          if Rails.logger.respond_to?(:tagged)
            Rails.logger.tagged("Tenant(#{tenant})") { @app.call(env) }
          else
            @app.call(env)
          end
        end
      rescue Gorynich::UriNotFound => e
        Rails.logger.error(e.inspect)
        [404, { 'Content-Type' => 'text/txt', 'charset' => 'UTF-8' }, [e.message]]
      rescue Gorynich::HostNotFound => e
        Rails.logger.error(e.inspect)
        [404, { 'Content-Type' => 'text/txt', 'charset' => 'UTF-8' }, [e.message]]
      rescue Gorynich::TenantNotFound => e
        Rails.logger.error(e.inspect)
        [404, { 'Content-Type' => 'text/txt', 'charset' => 'UTF-8' }, [e.message]]
      rescue StandardError => e
        Rails.logger.error("Gorynich Error: #{e.inspect}")
        Rails.logger.debug(e.backtrace)
        [500, { 'Content-Type' => 'text/txt', 'charset' => 'UTF-8' }, [I18n.t(
          'gorynich.internal_error', default: 'Gorynich internal error'
        )]]
      end
    end
  end
end
