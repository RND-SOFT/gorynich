module Gorynich
  class Current < ::ActiveSupport::CurrentAttributes
    attribute :tenant
    attribute :domain
    attribute :secrets
    attribute :database

    def secrets
      super || {}
    end
  end
end
