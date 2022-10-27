module Gorynich
  class Current < ::ActiveSupport::CurrentAttributes
    attribute :tenant
    attribute :uri
    attribute :host
    attribute :secrets
    attribute :database

    def secrets
      super || {}
    end
  end
end
