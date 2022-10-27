module Gorynich
  class Configuration
    attr_accessor :cache,
                  :fetcher,
                  :namespace,
                  :cache_expiration

    def initialize
      @cache = ActiveSupport::Cache::MemoryStore.new
      @fetcher = nil
      @namespace = nil
      @cache_expiration = 30
    end
  end
end
