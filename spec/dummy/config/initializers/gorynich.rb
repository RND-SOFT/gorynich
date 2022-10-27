# :nocov:
Gorynich.configure do |config|
  # config cache of gorynich
  config.cache = Rails.cache

  # config cache namespace
  # config.namespace = 'gorynich'

  # config how long your cache will be alive in seconds
  # config.cache_expiration = 30

  # config data sources
  # if it will be array then the data will be taken from the first successful fetch
  config.fetcher = Gorynich::Fetchers::File.new(file_path: Rails.root.join('config', 'gorynich_config.yml'))
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
