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

    def with_current(tenant, **opts)
      current = @config.current_config(tenant).merge(opts)
      Gorynich::Current.set(**current.merge(opts)) do
        @config.around_tentant.call(Gorynich::Current.instance) do
          yield(Gorynich::Current.instance)
        end
      end
    end

    def with(tenant, **opts, &block)
      with_database(tenant) do
        with_current(tenant, opts, &block)
      end
    end

    def with_each_tenant(&block)
      @config.tenants.each do |tenant|
        with(tenant, &block)
      end
    end
  end
end
