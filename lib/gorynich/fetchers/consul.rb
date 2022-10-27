require 'diplomat'

module Gorynich
  module Fetchers
    class Consul
      attr_reader :storage, :consul_opts

      def initialize(storage:, **opts)
        @storage = storage
        @consul_opts = opts
      end

      def fetch
        config = ::Diplomat::Kv.get_all(storage, convert_to_hash: true, **consul_opts)
        config.dig(*storage.split('/')) || {}
      end
    end
  end
end
