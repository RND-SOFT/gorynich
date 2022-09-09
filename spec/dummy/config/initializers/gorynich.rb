Gorynich.configure do |config|
  config.cache = Rails.cache
  config.fetcher = Gorynich::Fetchers::File.new(file_path: Rails.root.join('config', 'gorynich_config.yml'))
end
