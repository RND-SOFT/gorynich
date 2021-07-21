module Gorynich
  module Head
    module ActiveRecord
      extend ActiveSupport::Concern

      included do # rubocop:disable Metrics/BlockLength
        module ::GlobalID::Locator # rubocop:disable Lint/ConstantDefinitionInBlock, Style/ClassAndModuleChildren
          class << self
            alias original_locate locate

            def locate(gid, options = {})
              gid = GlobalID.parse(gid)
              return original_locate(gid, options) unless gid

              tenant = gid.params['tenant']
              if tenant && tenant != Gorynich::Current.tenant
                Gorynich.with(tenant) do
                  original_locate(gid, options)
                end
              else
                original_locate(gid, options)
              end
            end
          end
        end

        connects_to database: Gorynich.instance.connects_to_config

        def cache_key(*args)
          "#{Gorynich::Current.tenant}:#{super}"
        end

        def to_global_id(options = {})
          options[:tenant] ||= Gorynich::Current.tenant
          super
        end

        alias_method :to_gid, :to_global_id
      end
    end
  end
end
