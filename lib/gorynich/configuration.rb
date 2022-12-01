module Gorynich
  class Configuration
    attr_accessor :cache,
                  :fetcher,
                  :namespace,
                  :cache_expiration,
                  :rack_env_handler

    def initialize
      @cache = ActiveSupport::Cache::NullStore.new
      @fetcher = nil
      @namespace = nil
      @cache_expiration = 30
      @rack_env_handler = nil
    end
  end
end
