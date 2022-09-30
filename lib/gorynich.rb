require 'gorynich/engine'

require_relative 'gorynich/version'
require_relative 'gorynich/configuration'
require_relative 'gorynich/fetcher'
require_relative 'gorynich/config'
require_relative 'gorynich/current'
require_relative 'gorynich/switcher'
require_relative 'gorynich/head'

module Gorynich
  class Error < StandardError; end

  class TenantNotFound < Error
    attr_reader :tenant

    def initialize(tenant, message = nil)
      @tenant = tenant

      super(message || "Tenant #{@tenant} not found")
    end
  end

  class UriNotFound < Error
    attr_reader :uri

    def initialize(uri, message = nil)
      @uri = uri

      super(message || "URI #{@uri} not found")
    end
  end

  class << self
    attr_accessor :configuration

    def reload
      @instance = Gorynich::Config.new
      @switcher = Switcher.new(config: instance)
    end

    def instance
      @instance ||= Gorynich::Config.new
    end

    def switcher
      @switcher ||= Switcher.new(config: instance)
    end

    def with_database(*args, &block)
      switcher.with_database(*args, &block)
    end

    def with_current(*args, &block)
      switcher.with_current(*args, &block)
    end

    def with(*args, **opts, &block)
      switcher.with(*args, **opts, &block)
    end

    def with_each_tenant(&block)
      switcher.with_each_tenant(&block)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def reset
      @configuration = Configuration.new
    end

    def configure
      yield(configuration)

      reload

      ::ActiveRecord::Base.include(Head::ActiveRecord)
    end
  end
end
