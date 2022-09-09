require 'yaml'

module Gorynich
  module Fetchers
    class File
      attr_reader :file_path

      def initialize(file_path:)
        @file_path = file_path
      end

      def fetch
        YAML.load_file(file_path) || {}
      rescue ::StandardError
        {}
      end
    end
  end
end
