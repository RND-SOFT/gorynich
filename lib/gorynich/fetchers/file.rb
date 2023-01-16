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
        data = ::ERB.new(::File.read(file_path)).result

        ::YAML.load(data, aliases: true) || {}
      rescue ArgumentError
        ::YAML.load(data) || {}
      end
    end
  end
end
