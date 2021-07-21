module Gorynich
  class Fetcher
    attr_reader :prefix, :file, :version, :redis_ns

    def initialize(prefix: 'advisers', file: '/tmp/planner.json', expiration: 30, local: false)
      @prefix = prefix
      @file = file.to_s
      @version = 0
      @expiration = expiration.to_i
      @local = local
      @redis_ns = @prefix.to_s.gsub(/[^\w]/, '_').gsub(/_+/, '_')
    end

    # Взять конфиг и обновить локальный файловый кеш на всякий случай.
    def fetch
      Rails.cache.fetch [:gorynich, :fetcher, :fetch], expires_in: @expiration.seconds,
                                                       namespace: "#{@redis_ns}default" do
        get_config
      end.tap do |cfg|
        if cfg != @old_cfg
          @version += 1
          @cfg = cfg
          update_file(cfg)
        end
      end
    end

    # Берём конфиг из разных источников с приоритетами
    def get_config # rubocop:disable Metrics/AbcSize, Naming/AccessorMethodName
      cfg = if Rails.env.test?
              from_file.presence
            else
              # Берём всегда из консула
              begin
                # Если в консуле нет - из долговременного кеша
                from_consul.presence || from_cache
              rescue StandardError => e
                Rails.logger.warn "Unable to fetch config from consul: #{e}"
                # При исключении тоже из кеша
                from_cache
              end.presence
            end

      # Если нигде найти конфиг не удалось - берём из файла
      cfg ||= from_file.presence

      raise "Config is empty: #{cfg.inspect}" if cfg.blank?

      cfg
    rescue StandardError => e
      Rails.logger.error "Unable to fetch config: #{e}"
      raise
    end

    def update_file(cfg)
      return if @timestamp && @timestamp > 5.minutes.ago && cfg.present?

      Tempfile.open(File.basename(file), File.dirname(file)) do |f|
        f.write(JSON.pretty_generate(cfg))
        f.close
        File.rename(f.path, file)
      end
      @timestamp = Time.zone.now
    end

    def from_consul
      return nil if @local

      Rails.logger.debug { "Fetching config from consul: #{Diplomat.configuration.url || :none}... from #{@prefix}" }
      cfg = Diplomat::Kv.get_all(@prefix, convert_to_hash: true)
      if cfg.present?
        cfg = cfg.dig(*@prefix.split('/'))
        raise 'Invalid config in consul' unless cfg.is_a?(Hash)

        Rails.cache.write(%i[gorynich fetcher cache], cfg, namespace: "#{@redis_ns}default")
        Rails.logger.debug { "Fetching config from consul OK: #{cfg.keys.count}" }
        return cfg
      end

      Rails.logger.debug 'Fetching config from consul FAILED'
      nil
    end

    def from_cache
      Rails.logger.debug 'Fetching config from cache...'
      cfg = Rails.cache.read(%i[gorynich fetcher cache], namespace: "#{@redis_ns}default")
      if cfg.present?
        raise 'Invalid config in cache' unless cfg.is_a?(Hash)

        Rails.logger.debug { "Fetching config from cache OK: #{cfg.keys.count}" }
        return cfg
      end

      Rails.logger.debug 'Fetching config from cache FAILED'
      nil
    end

    def from_file
      Rails.logger.debug { "Fetching config from file: #{file}..." }
      cfg = JSON.parse(File.read(file))
      if cfg.present?
        raise 'Invalid config in file' unless cfg.is_a?(Hash)

        Rails.logger.debug { "Fetching config from file OK: #{cfg.keys.count}" }
        return cfg
      end

      Rails.logger.debug 'Fetching config from file FAILED'
      nil
    end
  end
end
