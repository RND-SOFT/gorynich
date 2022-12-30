require 'rails_helper'

RSpec.describe Gorynich::Config do
  before(:all) do
    file_path = "#{RSPEC_ROOT}/fixtures/fetchers/file_config.yml"

    Gorynich.configure do |config|
      config.fetcher = Gorynich::Fetchers::File.new(file_path: file_path)
    end
  end

  after(:all) do
    Gorynich.reset
  end

  subject { described_class.new }

  context '#default' do
    it { expect(subject.default).to eq('default') }
  end

  context '#fetcher' do
    it do
      expect(subject.fetcher.class).to eq(Gorynich::Fetcher)
    end
  end

  context '#databases' do
    it do
      expect(subject.databases).to eq(
        {
          'default' => {
            'adapter' => 'postgresql',
            'encoding' => 'unicode',
            'host' => 'localhost',
            'pool' => 10,
            'port' => 5432,
            'username' => 'xxx',
            'password' => 'xxx',
            'database' => 'gorynich_test_default'
          },
          'local' => {
            'adapter' => 'postgresql',
            'encoding' => 'unicode',
            'host' => 'localhost',
            'pool' => 10,
            'port' => 5432,
            'username' => 'xxx',
            'password' => 'xxx',
            'database' => 'gorynich_test_local'
          },
          'local1' => {
            'adapter' => 'postgresql',
            'encoding' => 'unicode',
            'host' => 'localhost',
            'pool' => 10,
            'port' => 5432,
            'username' => 'xxx',
            'password' => 'xxx',
            'database' => 'gorynich_test_local1'
          }
        }
      )
    end
  end

  context '#database' do
    describe 'when found tenant' do
      it do
        expect(subject.database('default')).to eq(
          {
            'adapter' => 'postgresql',
            'encoding' => 'unicode',
            'host' => 'localhost',
            'pool' => 10,
            'port' => 5432,
            'username' => 'xxx',
            'password' => 'xxx',
            'database' => 'gorynich_test_default'
          }
        )

        expect(subject.database(:default)).to eq(
          {
            'adapter' => 'postgresql',
            'encoding' => 'unicode',
            'host' => 'localhost',
            'pool' => 10,
            'port' => 5432,
            'username' => 'xxx',
            'password' => 'xxx',
            'database' => 'gorynich_test_default'
          }
        )
      end
    end

    describe 'when tenant not found' do
      it do
        expect { subject.database("default#{Faker::Lorem.word}") }.to raise_error(Gorynich::TenantNotFound)
      end
    end
  end

  context '#uris' do
    describe 'when tenant found' do
      it do
        expect(subject.uris('local')).to eq(
          ['http://localhost:3000']
        )

        expect(subject.uris(:local)).to eq(
          ['http://localhost:3000']
        )
      end
    end

    describe 'when tenant not found' do
      it do
        expect { subject.uris("default#{Faker::Lorem.word}") }.to raise_error(Gorynich::TenantNotFound)
      end
    end

    describe 'when parsing wrong config' do
      let(:file_path) { "#{RSPEC_ROOT}/fixtures/fetchers/wrong_file_config.yml" }

      it do
        expect { described_class.new(fetcher: Gorynich::Fetchers::File.new(file_path: file_path)) }.to raise_error(
          Gorynich::ConfigError
        )
      end
    end
  end

  context '#hosts' do
    describe 'when tenant found' do
      it do
        expect(subject.hosts('local')).to eq(
          ['localhost']
        )

        expect(subject.hosts(:local)).to eq(
          ['localhost']
        )
      end
    end

    describe 'when tenant not found' do
      it do
        expect { subject.hosts("default#{Faker::Lorem.word}") }.to raise_error(Gorynich::TenantNotFound)
      end
    end
  end

  context '#secrets' do
    describe 'when tenant found' do
      it do
        expect(subject.secrets('local')).to eq(
          {
            'uris' => ['http://localhost:3000']
          }
        )

        expect(subject.secrets(:local)).to eq(
          {
            'uris' => ['http://localhost:3000']
          }
        )
      end
    end

    describe 'when tenant not found' do
      it do
        expect { subject.secrets("default#{Faker::Lorem.word}") }.to raise_error(Gorynich::TenantNotFound)
      end
    end
  end

  context 'tenant_by_uri' do
    describe 'when uri found' do
      it do
        expect(subject.tenant_by_uri('http://localhost:3000')).to eq('local')
      end
    end

    describe 'when uri not found' do
      let(:uri) { Faker::Internet.url }

      it do
        expect { subject.tenant_by_uri(uri) }.to raise_error(Gorynich::UriNotFound)
      end
    end
  end

  context 'tenant_by_host' do
    describe 'when host found' do
      it do
        expect(subject.tenant_by_host('localhost')).to eq('local')
      end
    end

    describe 'when host not found' do
      let(:host) { Faker::Internet.domain_name }

      it do
        expect { subject.tenant_by_host(host) }.to raise_error(Gorynich::HostNotFound)
      end
    end
  end

  context '#config' do
    describe 'when tenant found' do
      it do
        expect(subject.config('local')).to eq(
          tenant: 'local',
          database: {
            'adapter' => 'postgresql',
            'encoding' => 'unicode',
            'host' => 'localhost',
            'pool' => 10,
            'port' => 5432,
            'username' => 'xxx',
            'password' => 'xxx',
            'database' => 'gorynich_test_local'
          },
          secrets: {
            'uris' => ['http://localhost:3000']
          }
        )

        expect(subject.config(:local)).to eq(
          tenant: 'local',
          database: {
            'adapter' => 'postgresql',
            'encoding' => 'unicode',
            'host' => 'localhost',
            'pool' => 10,
            'port' => 5432,
            'username' => 'xxx',
            'password' => 'xxx',
            'database' => 'gorynich_test_local'
          },
          secrets: {
            'uris' => ['http://localhost:3000']
          }
        )
      end
    end
  end

  context '#database_config' do
    describe 'when without env' do
      it do
        expect(subject.database_config).to include('development', 'test')
      end
    end

    describe 'when with end' do
      it do
        dev_res = subject.database_config('development')
        expect(dev_res).to include('gorynich_local')
        expect(dev_res).not_to include('gorynich_test_local')

        test_res = subject.database_config('test')
        expect(test_res).to include('gorynich_test_local')
        expect(test_res).not_to include('gorynich_local')
      end
    end

    describe 'when use in file just tenants' do
      let(:database_yml) { File.read("#{RSPEC_ROOT}/fixtures/test_database.yml") }

      subject { ::YAML.load(::ERB.new(database_yml).result) }

      it do
        expect(subject).to eq(
          {
            'development' => {
              'default' => {
                'adapter' => 'postgresql',
                'encoding' => 'unicode',
                'host' => 'localhost',
                'pool' => 10,
                'port' => 5432,
                'username' => 'xxx',
                'password' => 'xxx',
                'database' => 'gorynich_default'
              },
              'local' => {
                'adapter' => 'postgresql',
                'encoding' => 'unicode',
                'host' => 'localhost',
                'pool' => 10,
                'port' => 5432,
                'username' => 'xxx',
                'password' => 'xxx',
                'database' => 'gorynich_local'
              },
              'local1' => {
                'adapter' => 'postgresql',
                'encoding' => 'unicode',
                'host' => 'localhost',
                'pool' => 10,
                'port' => 5432,
                'username' => 'xxx',
                'password' => 'xxx',
                'database' => 'gorynich_local1'
              }
            },
            'test' => {
              'default' => {
                'adapter' => 'postgresql',
                'encoding' => 'unicode',
                'host' => 'localhost',
                'pool' => 10,
                'port' => 5432,
                'username' => 'xxx',
                'password' => 'xxx',
                'database' => 'gorynich_test_default'
              },
              'local' => {
                'adapter' => 'postgresql',
                'encoding' => 'unicode',
                'host' => 'localhost',
                'pool' => 10,
                'port' => 5432,
                'username' => 'xxx',
                'password' => 'xxx',
                'database' => 'gorynich_test_local'
              },
              'local1' => {
                'adapter' => 'postgresql',
                'encoding' => 'unicode',
                'host' => 'localhost',
                'pool' => 10,
                'port' => 5432,
                'username' => 'xxx',
                'password' => 'xxx',
                'database' => 'gorynich_test_local1'
              }
            }
          }
        )
      end
    end

    describe 'when use in file with tenants and customs configs' do
      let(:database_yml) { File.read("#{RSPEC_ROOT}/fixtures/env_test_database.yml") }

      subject { ::YAML.load(::ERB.new(database_yml).result) }

      it do
        expect(subject).to eq(
          {
            'development' => {
              'default' => {
                'adapter' => 'postgresql',
                'encoding' => 'unicode',
                'host' => 'localhost',
                'pool' => 10,
                'port' => 5432,
                'username' => 'xxx',
                'password' => 'xxx',
                'database' => 'gorynich_default'
              },
              'local' => {
                'adapter' => 'postgresql',
                'encoding' => 'unicode',
                'host' => 'localhost',
                'pool' => 10,
                'port' => 5432,
                'username' => 'xxx',
                'password' => 'xxx',
                'database' => 'gorynich_local'
              },
              'local1' => {
                'adapter' => 'postgresql',
                'encoding' => 'unicode',
                'host' => 'localhost',
                'pool' => 10,
                'port' => 5432,
                'username' => 'xxx',
                'password' => 'xxx',
                'database' => 'gorynich_local1'
              },
              'shared' => {
                'host' => 'dev'
              }
            },
            'test' => {
              'default' => {
                'adapter' => 'postgresql',
                'encoding' => 'unicode',
                'host' => 'localhost',
                'pool' => 10,
                'port' => 5432,
                'username' => 'xxx',
                'password' => 'xxx',
                'database' => 'gorynich_test_default'
              },
              'local' => {
                'adapter' => 'postgresql',
                'encoding' => 'unicode',
                'host' => 'localhost',
                'pool' => 10,
                'port' => 5432,
                'username' => 'xxx',
                'password' => 'xxx',
                'database' => 'gorynich_test_local'
              },
              'local1' => {
                'adapter' => 'postgresql',
                'encoding' => 'unicode',
                'host' => 'localhost',
                'pool' => 10,
                'port' => 5432,
                'username' => 'xxx',
                'password' => 'xxx',
                'database' => 'gorynich_test_local1'
              },
              'shared' => {
                'host' => 'test'
              }
            }
          }
        )
      end
    end
  end
end
