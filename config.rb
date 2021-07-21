module Gorynich
  class Config
    attr_reader :fetcher, :data, :tenants, :default, :around_tentant

    def initialize(fetcher:, default: :default, around_tentant: nil)
      @fetcher = fetcher
      @version = 0
      @default = default
      @around_tentant = around_tentant || proc { |current, &block| block.call(current) }
      @mx = Mutex.new
    end

    def actualize
      @fetcher.fetch.tap do |cfg|
        Rails.logger.debug { "fetcher actualize cfg #{cfg.inspect}" }
        if @fetcher.version != @version
          update_config(cfg)
          @version = @fetcher.version
        end
        return self
      end
    end

    def transform(cfg)
      cfg = cfg.deep_transform_keys { |k| k.to_s.downcase }.tap do |cfg_tap|
        unless cfg_tap.key?(@default)
          cfg_tap[@default] = {
            'db_config' => {
              'adapter' => 'postgresql',
              'host' => ENV.fetch('DATABASE_HOST', 'db'),
              'port' => ENV.fetch('DATABASE_PORT', 5432),
              'database' => ENV.fetch('DATABASE_NAME', 'sentinel_ror_development'),
              'encoding' => 'unicode',
              'pool' => ENV.fetch('DATABASE_POOL', 10),
              'username' => ENV.fetch('DATABASE_USER', 'postgres'),
              'password' => ENV.fetch('DATABASE_PASS', '')

            },
            'secrets' => {}
          }
        end
      end

      # FORCE "DEFAULT" to be FIRST tenant
      { @default => cfg[@default] }.merge(cfg)
    end

    def update_config(cfg) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      cfg = transform(cfg)

      d = { secrets: {}.with_indifferent_access, databases: {}.with_indifferent_access,
            domains: {}.with_indifferent_access, tbd: {}.with_indifferent_access, current_config: {} }
      d[:config] = cfg.deep_transform_keys { |k| k.to_s.downcase }
      d[:tenants] = d[:config].keys

      d[:tenants].each do |tenant|
        d[:secrets][tenant] = OpenStruct.new(d[:config][tenant].fetch('secrets', {}.with_indifferent_access))
        d[:databases][tenant] = OpenStruct.new(d[:config][tenant].fetch('db_config').with_indifferent_access)
        d[:domains][tenant] = (d[:secrets][tenant].domains || '').split(/[|\ ,]/)

        d[:domains][tenant].each do |domain|
          d[:tbd][domain] = tenant
        end
        d[:current_config][tenant] = {
          tenant: tenant,
          config: d[:config][tenant],
          secrets: d[:secrets][tenant],
          database: d[:databases][tenant],
          domain: d[:domains][tenant].first
        }
      end

      @mx.synchronize do
        @data = d
        @tenants = @data[:tenants]
        @secrets = @data[:secrets]
        @domains = @data[:domains]
        @databases = @data[:databases]
        @domains = @data[:domains]
        @tbd = @data[:tbd]
        @current_config = d[:current_config]
      end
    end

    def config(tenant)
      data[:config].fetch(tenant)
    rescue StandardError
      raise Gorynich::TenantNotFound, tenant
    end

    def secrets(tenant)
      @secrets.fetch(tenant)
    rescue StandardError
      raise Gorynich::TenantNotFound, tenant
    end

    def database(tenant)
      @databases.fetch(tenant)
    rescue StandardError
      raise Gorynich::TenantNotFound, tenant
    end

    def domains(tenant)
      @domains.fetch(tenant)
    rescue StandardError
      raise Gorynich::TenantNotFound, tenant
    end

    def current_config(tenant)
      @current_config.fetch(tenant)
    rescue StandardError
      raise Gorynich::TenantNotFound, tenant
    end

    def tenant_by_domain(domain)
      @tbd.fetch(domain)
    rescue StandardError
      raise Gorynich::DomainNotFound, domain
    end

    def connects_to_config(default: :default)
      actualize
      tenants.each_with_object({ default: default }) do |tenant, cfg|
        cfg[tenant.to_sym] = tenant.to_sym
      end
    end
  end
end
