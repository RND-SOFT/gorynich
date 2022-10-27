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

      super(message || I18n.t('gorynich.tenant_not_found', tenant: @tenant, default: "Tenant #{@tenant} not found"))
    end
  end

  class UriNotFound < Error
    attr_reader :uri

    def initialize(uri, message = nil)
      @uri = uri

      super(message || I18n.t('gorynich.uri_not_found', uri: @tenant, default: "URI #{@uri} not found"))
    end
  end

  class HostNotFound < Error
    attr_reader :host

    def initialize(host, message = nil)
      @host = host

      super(message || I18n.t('gorynich.host_not_found', host: @host, default: "Host #{@host} not found"))
    end
  end

  class << self
    attr_accessor :configuration

    #
    # Reload app configuration
    #
    def reload
      @instance = Config.new
      @switcher = Switcher.new(config: instance)
    end

    #
    # App configuration
    #
    # @return [Gorynich::Config]
    #
    def instance
      @instance ||= Config.new
    end

    #
    # Tenant switcher
    #
    # @return [Gorynich::Switcher]
    #
    def switcher
      @switcher ||= Switcher.new(config: instance)
    end

    #
    # Block for performing actions with a tenant database
    #
    # @param [String, Symbol] tenant
    #
    def with_database(*args, &block)
      switcher.with_database(*args, &block)
    end

    #
    # Block for performing actions with a tenant database with a change in current attributes (ActiveSupport::CurrentAttributes)
    #
    # @param [String, Symbol] tenant
    #
    def with_current(*args, &block)
      switcher.with_current(*args, &block)
    end

    #
    # Block for performing actions with a tenant database with a change in current attributes (ActiveSupport::CurrentAttributes)
    #
    # @param [String, Symbol] tenant
    # @param [Hash] **opts options for Gorynich::Current
    #
    def with(*args, **opts, &block)
      switcher.with(*args, **opts, &block)
    end

    #
    # Block for performing actions with each tenant database
    #
    # @param [Array] except Array of tenants with which no actions will be performed
    #
    def with_each_tenant(**opts, &block)
      switcher.with_each_tenant(**opts, &block)
    end

    #
    # Configuration of gem
    #
    def configuration
      @configuration ||= Configuration.new
    end

    #
    # Reset to default configuration settings
    #
    def reset
      @configuration = Configuration.new
    end

    #
    # Setting up and initializing the gem
    #
    def configure
      yield(configuration)

      reload

      ::ActiveRecord::Base.include(Head::ActiveRecord)
    end
  end
end
