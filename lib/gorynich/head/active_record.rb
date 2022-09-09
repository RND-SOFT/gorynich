module Gorynich
  module Head
    module ActiveRecord
      extend ActiveSupport::Concern

      included do
        module ::GlobalID::Locator
          class << self
            def original_locate(gid, options = {})
              if (gid = GlobalID.parse(gid)) && find_allowed?(gid.model_class, options[:only])
                locator_for(gid).locate gid
              end
            end

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
