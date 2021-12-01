module Gorynich
  class Current < ::ActiveSupport::CurrentAttributes
    attribute :tenant
    attribute :config
    attribute :domain
    attribute :schema
    attribute :host
    attribute :secrets
    attribute :database

    def secrets
      super || {}
    end
  end
end
