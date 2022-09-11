module Gorynich
  class Switcher
    def initialize(config:, &block)
      @config = config
      @analyzer = block
    end

    def analyze(env)
      tenant, opts = @analyzer.call(env)
      [tenant, opts || {}]
    end

    def with_database(tenant)
      ::ActiveRecord::Base.connected_to role: tenant do
        yield(tenant)
      end
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
