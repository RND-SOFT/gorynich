module Gorynich
  module Head
    module ActiveJob
      extend ::ActiveSupport::Concern

      included do
        around_perform do |_job, block|
          Gorynich.with(Gorynich::Current.tenant, uri: Gorynich::Current.uri) do |current|
            block.call
          end
        end

        around_enqueue do |_job, block|
          Gorynich.with_database(Gorynich.instance.default) do
            block.call
          end
        end
      end
    end
  end
end
