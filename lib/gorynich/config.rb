module Gorynich
  class Config
    attr_reader :fetcher,
                :tenants,
                :databases,
                :default,
                :domains,
                :secrets,
                :hosts

    def initialize(**opts)
      @default = 'default'
      @fetcher = opts.fetch(:fetcher, Fetcher.new)
      @mx = Mutex.new

      actualize
    end

    def actualize
      cfg = fetcher.fetch.fetch(Rails.env)

      @mx.synchronize do
        @tenants = tenants_from_config(cfg)
        @databases = databases_from_config(cfg)
        @secrets = secrets_from_config(cfg)
        @domains = domains_from_config(@secrets)
        @hosts = hosts_from_config(@secrets)
      end
    end

    def database(tenant)
      databases.fetch(tenant.to_s)
    rescue StandardError
      raise TenantNotFound, tenant
    end

    def domains_by_tenant(tenant)
      domains.fetch(tenant.to_s)
    rescue StandardError
      raise TenantNotFound, tenant
    end

    def hosts_by_tenant(tenant)
      hosts.fetch(tenant.to_s)
    rescue StandardError
      raise TenantNotFound, tenant
    end

    def secrets_by_tenant(tenant)
      secrets.fetch(tenant.to_s)
    rescue StandardError
      raise TenantNotFound, tenant
    end

    def tenant_by_domain(domain)
      tenant = domains.select { |t, d| t if d.include?(domain) }.keys.first
      raise DomainNotFound, domain if tenant.nil?

      tenant
    end

    def config(tenant)
      {
        tenant: tenant.to_s,
        database: database(tenant),
        secrets: secrets_by_tenant(tenant)
      }
    end

    def database_config(env = nil)
      cfg = fetcher.fetch

      result =
        if env.nil?
          cfg.to_h do |env, tenant_cfg|
            [
              env,
              tenant_cfg.to_h { |t, c| [t, c.fetch('db_config')] }
            ]
          end
        else
          cfg.fetch(env).to_h { |t, c| [t, c.fetch('db_config')] }
        end

      result.to_yaml
    end

    def connects_to_config
      actualize
      tenants.to_h { |t| [t.to_sym, t.to_sym] }
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

    def hosts_from_config(secrets)
      secrets.to_h { |tenant, secrets| [tenant, secrets.fetch('hosts', [])] }
    end

    def domains_from_config(secrets)
      secrets.to_h do |tenant, secrets|
        domains = secrets.fetch('hosts', []).map { |host| URI(host).host }
        [tenant, domains]
      end
    end
  end
end
