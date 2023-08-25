require_relative 'fetchers/file'
require_relative 'fetchers/consul'
require_relative 'fetchers/consul_secure'

module Gorynich
  class Fetcher
    attr_reader :fetcher, :namespace, :cache_expiration

    #
    # Create instance of fetcher
    #
    # @param [Object] fetcher data source
    # @param [String, Symbol] namespace cache namespace
    # @param [Integer] cache_expiration how long your cache will be alive
    #
    def initialize(fetcher: nil, namespace: nil, cache_expiration: nil)
      @fetcher = fetcher || Gorynich.configuration.fetcher
      @namespace = namespace || Gorynich.configuration.namespace
      @cache_expiration = cache_expiration || Gorynich.configuration.cache_expiration
    end

    #
    # Load data from source
    #
    # @return [Hash]
    #
    def fetch
      cfg = Gorynich.configuration.cache.fetch(
        %i[gorynich fetcher fetch], expires_in: @cache_expiration.seconds, namespace: @namespace
      ) do
        if @fetcher.nil?
          {}
        elsif @fetcher.is_a?(Array)
          result = {}
          @fetcher.each do |f|
            result =
              begin
                f.fetch
              rescue ::StandardError
                {}
              end
            break unless result.empty?
          end
          result
        else
          @fetcher.fetch
        end
      end

      raise Error, 'Config is empty' if cfg.empty?

      cfg.deep_transform_keys(&:downcase)
    end
  end
end
