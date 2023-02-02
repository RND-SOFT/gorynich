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
    end
  end
end
# :nocov:
