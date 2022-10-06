Gorynich.configure do |config|
  config.cache = Rails.cache
  config.fetcher = Gorynich::Fetchers::File.new(file_path: Rails.root.join('config', 'gorynich_config.yml'))
end

ActiveSupport.on_load(:action_cable_connection) do
  include Gorynich::Head::ActionCable::Connection
end

ActiveSupport.on_load(:action_cable_channel) do
  include Gorynich::Head::ActionCable::Channel
end

ActiveSupport.on_load(:active_job) do
  include Gorynich::Head::ActiveJob
end
