require_relative 'fetchers/file'
require_relative 'fetchers/consul'

module Gorynich
  class Fetcher
    attr_reader :fetcher, :namespace, :cache_expiration

    def initialize(fetcher: nil, namespace: nil, **opts)
      @fetcher = fetcher || Gorynich.configuration.fetcher
      @namespace = namespace || Gorynich.configuration.namespace
      @cache_expiration = opts.delete(:cache_expiration) { Gorynich.configuration.cache_expiration }
    end

    def fetch
      cfg = Gorynich.configuration.cache.fetch(
        %i[gorynich fetcher fetch], expires_in: @cache_expiration.seconds, namespace: @namespace
      ) do
        if @fetcher.nil?
          {}
        elsif @fetcher.is_a?(Array)
          result = {}
          @fetcher.each do |f|
            result = f.fetch
            break unless result.empty?
          end
          result
        else
          @fetcher.fetch
        end
      end

      raise Error, 'Config is empty' if cfg.empty?

      cfg
    end
  end
end
