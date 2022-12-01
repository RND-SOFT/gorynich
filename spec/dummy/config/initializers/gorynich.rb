# :nocov:
Gorynich.configure do |config|
  # config cache of gorynich
  config.cache = Rails.cache

  config.rack_env_handler =
    lambda do |env|
      host = env['SERVER_NAME']
      tenant = Gorynich.instance.tenant_by_host(host)
      uri = Gorynich.instance.uri_by_host(host, tenant)
      [tenant, { host: host, uri: uri }]
    end

  # config cache namespace
  # config.namespace = 'gorynich'

  # config how long your cache will be alive in seconds
  # config.cache_expiration = 30
end

# Add cable head
# ActiveSupport.on_load(:action_cable_connection) do
#   include Gorynich::Head::ActionCable::Connection
# end
#
# ActiveSupport.on_load(:action_cable_channel) do
#   include Gorynich::Head::ActionCable::Channel
# end

# Add active job head
# ActiveSupport.on_load(:active_job) do
#   include Gorynich::Head::ActiveJob
# end
# :nocov:
