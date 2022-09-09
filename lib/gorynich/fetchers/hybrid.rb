require_relative 'file'
require_relative 'consul'

module Gorynich
  module Fetchers
    class Hybrid
      def initialize(**opts)
        file_path = opts.delete(:file_path)
        storage = opts.delete(:storage)

        @consul_fetcher = Consul.new(storage: storage, **opts)
        @file_fetcher = File.new(file_path: file_path)
      end

      def fetch
        cfg = @consul_fetcher.fetch
        cfg = @file_fetcher.fetch if cfg.empty?

        cfg
      end
    end
  end
end
