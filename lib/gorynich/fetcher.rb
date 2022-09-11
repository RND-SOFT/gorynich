require_relative 'fetchers/file'
require_relative 'fetchers/consul'

module Gorynich
  class Fetcher
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
          @fetcher.each do |f|
            f.fetch
          end
        else
          @fetcher.fetch
        end
      end

      raise Error, 'Config is empty' if cfg.empty?

      cfg
    end
  end
end
