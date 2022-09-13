require 'rails_helper'

RSpec.describe Gorynich::Fetchers::Consul do
  let(:storage) { Faker::Lorem.word }

  context '#storage' do
    subject { described_class.new(storage: storage) }

    it do
      expect(subject.storage).to eq(storage)
    end
  end

  context '#consul_opts' do
    let(:consul_opts) { { Faker::Lorem.word => Faker::Lorem.word } }

    subject { described_class.new(storage: storage, **consul_opts) }

    it do
      expect(subject.consul_opts).to eq(consul_opts)
    end
  end

  context '#fetch' do
    let(:consul_host) { Faker::Internet.url }
    let(:consul_opts) { { http_addr: consul_host } }

    def consul_request(response, code = 200)
      stub_request(:get, "#{consul_host}/v1/kv/est?recurse=true").to_return(
        status: code,
        body: response
      )
    end

    subject { described_class.new(storage: storage, **consul_opts) }

    describe 'when consul return data' do
      let(:response) { [].to_json }

      before(:each) do
        consul_request(response)
      end

      it do
        expect(subject.fetch.class).to eq(Hash)
      end
    end
  end
end
