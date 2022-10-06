module Gorynich
  module Head
    module ActionCable
      module Connection
        extend ::ActiveSupport::Concern

        included do
          def connect
            self.host = env['SERVER_NAME']
            self.tenant = ::Gorynich.instance.tenant_by_host(host)
            super
          end
        end
      end

      module Channel
        extend ::ActiveSupport::Concern

        included do
          def subscribe_to_channel(*args)
            Gorynich.with(tenant, domain: domain) do
              super
            end
          end

          def unsubscribe_from_channel(*args)
            Gorynich.with(tenant, domain: domain) do
              super
            end
          end

          def perform_action(*args)
            Gorynich.with(tenant, domain: domain) do
              super
            end
          end

          def self.broadcasting_for(model)
            raise 'unable to broadcast message without tenant' if Gorynich::Current.tenant.nil?

            serialize_broadcasting([channel_name, Gorynich::Current.tenant, model])
          end
        end
      end
    end
  end
end
