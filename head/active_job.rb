# rubocop:disable Layout/LineLength
module Gorynich
  module Head
    module ActiveJob
      extend ::ActiveSupport::Concern

      included do # rubocop:disable Metrics/BlockLength
        attr_reader :current_domain, :current_tenant

        def serialize
          super.merge(domain: Gorynich::Current.domain, tenant: Gorynich::Current.tenant)
        end

        def deserialize(job_data)
          super
          @current_domain = job_data.fetch(:domain)
          @current_tenant = job_data.fetch(:tenant)
        end

        around_perform do |job, block|
          Gorynich.with(job.current_tenant, domain: job.current_domain) do |current|
            ::ActiveJob::Base.logger.tagged("Tenant(#{current.tenant})") do
              ::ActiveJob::Base.logger.debug do
                current_database = ::ActiveRecord::Base.connection.execute('SELECT current_database();').first['current_database']
                "Perform on: database #{current_database} db: #{current.database['database']} domain: #{current.domain}"
              end
              block.call
            end
          end
        end

        around_enqueue do |_job, block|
          Gorynich.with_database(Gorynich.instance.default) do
            ::ActiveJob::Base.logger.debug do
              current_database = ::ActiveRecord::Base.connection.execute('SELECT current_database();').first['current_database']
              "Enqueue to database #{current_database}. For tenant #{Gorynich::Current.tenant} domain: #{Gorynich::Current.domain}"
            end
            block.call
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
