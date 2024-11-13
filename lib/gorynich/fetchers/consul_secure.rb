module Gorynich
  module Fetchers
    class ConsulSecure
      attr_reader :storage, :file_path, :consul_opts

      def initialize(storage:, file_path:, **opts)
        @storage = storage
        @file_path = file_path
        @consul_opts = opts
      end

      def fetch
        cfg = Consul.new(storage: storage, **consul_opts).fetch
        return from_file if cfg.empty?

        save_to_file(cfg)

        cfg
      rescue ::StandardError
        from_file
      end

      private

      def save_to_file(cfg)
        envs = ::Dir.glob(::Rails.root.join('config/environments/*.rb').to_s).map { |f| ::File.basename(f, '.rb') }

        ::File.open(file_path, 'w') do |f|
          f << cfg.deep_transform_keys(&:downcase).select { |k, _v| envs.include?(k) }.to_yaml.gsub(/^---/, '')
        end
      end

      def from_file
        File.new(file_path: file_path).fetch
      end
    end
  end
end
