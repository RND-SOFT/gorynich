require 'erb'
require 'yaml'

module Gorynich
  module Fetchers
    class File
      attr_reader :file_path

      def initialize(file_path:)
        @file_path = file_path
      end

      def fetch
        ::YAML.load(::ERB.new(::File.read(file_path)).result) || {}
      rescue ::StandardError
        {}
      end
    end
  end
end
