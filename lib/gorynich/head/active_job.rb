module Gorynich
  module Head
    module ActiveJob
      extend ::ActiveSupport::Concern

      included do
        attr_reader :current_uri, :current_tenant

        def serialize
          super.merge(uri: Gorynich::Current.uri, tenant: Gorynich::Current.tenant)
        end

        def deserialize(job_data)
          super
          @current_uri = job_data.fetch(:uri)
          @current_tenant = job_data.fetch(:tenant)
        end

        around_perform do |job, block|
          Gorynich.with(
            job.current_tenant || Gorynich::Current.tenant,
            uri: job.current_uri || Gorynich::Current.uri
          ) do |_current|
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
