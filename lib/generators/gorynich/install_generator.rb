# :nocov:
require 'rails/generators/base'

module Gorynich
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)
    
      desc 'Creates a Gorynich initializer'
    
      def copy_initializer
        template 'gorynich.rb', Rails.root.join('config', 'initializers', 'gorynich.rb')
      end

      def copy_config
        template 'gorynich_config.yml', Rails.root.join('config', 'gorynich_config.yml.test')
      end

      def copy_database_config
        copy_file 'database.yml', Rails.root.join('config', 'database.yml.test')
      end
    end
  end
end
# :nocov:
