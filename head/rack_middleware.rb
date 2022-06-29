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
        render_error_page(404, I18n.t('gorynich.errors.service_not_found'), e.to_s)
      rescue StandardError => e
        Rails.logger.error("Gorynich Error: #{e.inspect}")
        Rails.logger.debug(e.backtrace)
        render_error_page(500, 'Неизвестная ошибка', e.to_s)
      end

      def render_error_page(code, message, details)
        template = File.read("#{File.dirname(__FILE__)}/../views/tenant_error.html.erb")
        rendered_template = ApplicationController.render(assigns: { code: code, message: message, details: details },
                                                         inline: template)
        [code, { 'Content-Type' => 'text/html', 'Content-Length' => rendered_template.size.to_s }, [rendered_template]]
      end
    end
  end
end
