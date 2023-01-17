module Gorynich
  module Head
    module ActionCable
      module Connection
        extend ::ActiveSupport::Concern

        included do
          attr_reader :host, :tenant

          def connect
            @host = env['SERVER_NAME']
            @tenant = ::Gorynich.instance.tenant_by_host(@host)
          end
        end
      end

      module Channel
        def subscribe_to_channel(*args)
          ::Gorynich.with(tenant, host: host) do
            super
          end
        end

        def unsubscribe_from_channel(*args)
          ::Gorynich.with(tenant, host: host) do
            super
          end
        end

        def perform_action(*args)
          ::Gorynich.with(tenant, host: host) do
            super
          end
        end

        def self.broadcasting_for(model)
          raise 'unable to broadcast message without tenant' if ::Gorynich::Current.tenant.nil?

          serialize_broadcasting([channel_name, ::Gorynich::Current.tenant, model])
        end
      end
    end
  end
end
