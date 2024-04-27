module Gorynich
  class Configuration
    #
    # Cache dummy
    #
    class NullStore
      def fetch(*args, **kwargs, &block)
        block.call
      end
    end

    attr_accessor :cache,
                  :fetcher,
                  :namespace,
                  :cache_expiration,
                  :rack_env_handler

    def initialize
      @cache = NullStore.new
      @fetcher = nil
      @namespace = nil
      @cache_expiration = 30
      @rack_env_handler = nil
    end
  end
end
