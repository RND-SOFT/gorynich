require 'rails_helper'

RSpec.describe Gorynich::Fetchers::File do
  let(:file_path) { "#{RSPEC_ROOT}/fixtures/fetchers/file_config.yml" }

  subject { described_class.new(file_path: file_path) }

  context '#file_path' do
    it do
      expect(subject.file_path).to eq(file_path)
    end
  end

  context '#fetch' do
    describe 'when file not exists' do
      let(:file_path) { Faker::Lorem.word }

      it do
        expect { subject.fetch }.to raise_error(Errno::ENOENT)
      end
    end

    describe 'when file exists' do
      it do
        result = subject.fetch
        expect(result.class).to eq(Hash)
        expect(result).to include('development', 'test')
      end
    end
  end
end
