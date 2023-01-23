module Gorynich
  class Config
    attr_reader :fetcher,
                :tenants,
                :databases,
                :hosts,
                :uris,
                :default

    #
    # Create instance of config
    #
    # @param [Fetcher] fetcher data loader
    #
    def initialize(**opts)
      @default = 'default'
      @fetcher = opts.fetch(:fetcher, Fetcher.new)
      @mx = Mutex.new

      actualize
    end

    #
    # Update configs from data source
    #
    def actualize
      cfg = fetcher.fetch.fetch(Rails.env)

      @mx.synchronize do
        @tenants = tenants_from_config(cfg)
        @databases = databases_from_config(cfg)
        @secrets = secrets_from_config(cfg)
        @uris = uris_from_config(@secrets)
        @hosts = hosts_from_config(@secrets)
      end
    end

    #
    # Database config
    #
    # @param [String, Symbol] tenant
    #
    # @return [Hash]
    #
    def database(tenant)
      databases.fetch(tenant.to_s)
    rescue StandardError
      raise TenantNotFound, tenant
    end

    %i[uris hosts secrets].each do |name|
      define_method(name) do |tenant = nil|
        values = instance_variable_get("@#{name}")
        return values if tenant.nil?

        values.fetch(tenant.to_s)
      rescue StandardError
        raise TenantNotFound, tenant
      end
    end

    #
    # Find tenant by URI
    #
    # @param [String] uri
    #
    # @return [String]
    #
    def tenant_by_uri(uri)
      uri = URI(uri)
      search_tenant = uris.select do |tenant, tenant_uris|
        tenant if tenant_uris.map { |t_uri| URI(t_uri) }.include?(uri)
      end.keys.first

      raise UriNotFound, uri.host if search_tenant.nil?

      search_tenant
    end

    #
    # Find tenant by host
    #
    # @param [String] host
    #
    # @return [String]
    #
    def tenant_by_host(host)
      tenant = hosts.select { |t, h| t if h.include?(host) }.keys.first
      raise HostNotFound, host if tenant.nil?

      tenant
    end

    #
    # Find URI by host
    #
    # @param [String] host
    # @param [String, Symbol] tenant tenant of config (optional)
    #
    # @return [String]
    #
    def uri_by_host(host, tenant = nil)
      tenant ||= tenant_by_host(host)
      tenant_uris = uris(tenant)
      search_uri = tenant_uris.select { |uri| uri.include?(host) }.first

      raise UriNotFound, search_uri.host if search_uri.nil?

      search_uri
    end

    #
    # Full config from data source by tenant
    #
    # @param [String, Symbol] tenant
    #
    # @return [Hash]
    #
    def config(tenant)
      {
        tenant: tenant.to_s,
        database: database(tenant),
        secrets: secrets(tenant)
      }
    end

    #
    # Database config for database.yml
    #
    # @param [String] env enviroment
    # @param [Boolean] with_ignore ignore if there is no configuration for the environment
    #
    # @return [String] yaml result
    #
    def database_config(env = nil, fail_ignore: false)
      envs = Dir.glob(Rails.root.join('config/environments/*.rb').to_s).map { |f| File.basename(f, '.rb') }
      cfg = fetcher.fetch.extract!(*envs)

      result =
        if env.nil?
          cfg.to_h do |cfg_env, tenant_cfg|
            [
              cfg_env,
              tenant_cfg.to_h { |t, c| [t, c.fetch('db_config')] }
            ]
          end
        else
          if fail_ignore && cfg.fetch(env, nil).nil?
            { env => nil}
          else
            {
              env => cfg.fetch(env).to_h { |t, c| [t, c.fetch('db_config')] }
            }
          end
        end

      result.to_yaml.gsub('---', '')
    end

    #
    # For connection to ActiveRecord
    #
    # @return [Hash]
    #
    def connects_to_config
      actualize
      tenants.each_with_object({ default: :default }) do |tenant, cfg|
        cfg[tenant.to_sym] = tenant.to_sym
      end
    end

    private

    def databases_from_config(cfg)
      cfg.to_h { |tenant, config| [tenant, config.fetch('db_config')] }
    end

    def tenants_from_config(cfg)
      available_tenants = cfg.keys
      raise TenantNotFound, default unless available_tenants.include?(default)

      available_tenants
    end

    def secrets_from_config(cfg)
      cfg.to_h { |tenant, config| [tenant, config.fetch('secrets', {})] }
    end

    def uris_from_config(secrets_by_tenant)
      secrets_by_tenant.to_h { |tenant, secrets| [tenant, processed_uris(secrets)] }
    end

    def hosts_from_config(secrets_by_tenant)
      secrets_by_tenant.to_h do |tenant, secrets|
        hosts = processed_uris(secrets).map { |uri| URI(uri).host }
        [tenant, hosts]
      end
    end

    # consul KV can store only array into json string, so need to parse
    def processed_uris(secrets)
      secrets_uris = secrets.fetch('uris', [])
      is_array = secrets_uris.is_a?(Array)
      return secrets_uris if is_array && secrets_uris.empty?

      if is_array
        validate_uris(secrets_uris)
        return secrets_uris
      end

      secrets_uris = JSON.parse(secrets_uris)
      validate_uris(secrets_uris)
      secrets_uris
    rescue JSON::ParserError => e
      raise ConfigError, 'URI parse error. Must be an array of URI'
    end

    def valid_url?(uri)
      uri = URI.parse(uri)
      !!uri.host && !!uri.scheme
    rescue URI::InvalidURIError
      false
    end

    def validate_uris(secrets_uris)
      secrets_uris.each { |uri| raise ConfigError, 'URI parse error. Must be an array of URI' unless valid_url?(uri) }
    end
  end
end
