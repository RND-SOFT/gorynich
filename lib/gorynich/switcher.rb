module Gorynich
  class Switcher
    DATABASE_RETRY_LIMIT = 2

    def initialize(config:)
      @config = config
    end

    #
    # Hander for rack middleware's variables
    #
    # @param [Hash] env middleware's variables
    #
    # @return [[String, Hash]] tenant, options
    #
    def analyze(env)
      return Gorynich.configuration.rack_env_handler.call(env) unless Gorynich.configuration.rack_env_handler.nil?

      host = env['SERVER_NAME']
      tenant = Gorynich.instance.tenant_by_host(host)
      uri = Gorynich.instance.uri_by_host(host, tenant)
      [tenant, { host: host, uri: uri }]
    end

    #
    # Connect to database
    #
    # @param [String, Symbol] tenant Tenant (database role)
    #
    def with_database(tenant)
      retries ||= 0
      ::ActiveRecord::Base.connected_to role: tenant.to_sym do
        ::ActiveRecord::Base.connection_pool.with_connection do
          yield(tenant)
        end
      end
    rescue ::ActiveRecord::ConnectionNotEstablished => e
      config = ::Gorynich.instance
      config.actualize

      raise TenantNotFound, tenant unless config.tenants.include?(tenant.to_s)
      if (retries += 1) < DATABASE_RETRY_LIMIT
        ActiveRecord::Base.connection_handler.establish_connection(
          config.database(tenant), role: tenant.to_sym
        )

        retry
      end

      raise e
    end

    def with_current(tenant, **opts, &block)
      Gorynich::Current.set(@config.config(tenant.to_s).merge(opts)) do
        block.call(Gorynich::Current.instance) if block.present?
      end
    end

    def with(tenant, **opts, &block)
      with_database(tenant) do
        with_current(tenant, **opts, &block)
      end
    end

    def with_each_tenant(except: [], &block)
      except = except.map(&:to_s)
      @config.tenants.reject { |v| except.include?(v) }.each do |tenant|
        with(tenant, &block)
      end
    end
  end
end
