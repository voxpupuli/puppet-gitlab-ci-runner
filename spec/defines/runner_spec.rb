require 'spec_helper'

describe 'gitlab_ci_runner::runner' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'testrunner' }

      context 'with simple shell runner' do
        let(:params) do
          {
            config: {
              url: 'https://gitlab.com',
              token: '123456789abcdefgh',
              executor: 'shell'
            }
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          verify_concat_fragment_exact_contents(
            catalogue,
            '/etc/gitlab-runner/config.toml - testrunner',
            [
              '[[runners]]',
              'name = "testrunner"',
              'url = "https://gitlab.com"',
              'token = "123456789abcdefgh"',
              'executor = "shell"'
            ]
          )
        end
      end

      context 'with autoscaling runner with DigitalOcean as IaaS' do
        let(:params) do
          {
            config: {
              url: 'https://gitlab.com',
              token: '123456789abcdefgh',
              name: 'autoscale-runner',
              executor: 'docker+machine',
              limit: 10,
              docker: {
                image: 'ruby:2.6'
              },
              machine: {
                OffPeakPeriods: [
                  '* * 0-9,18-23 * * mon-fri *',
                  '* * * * * sat,sun *'
                ],
                OffPeakIdleCount: 1,
                OffPeakIdleTime: 1200,
                IdleCount: 5,
                IdleTime: 600,
                MaxBuilds: 100,
                MachineName: 'auto-scale-%s',
                MachineDriver: 'digitalocean',
                MachineOptions: [
                  'digitalocean-image=coreos-stable',
                  'digitalocean-ssh-user=core',
                  'digitalocean-access-token=DO_ACCESS_TOKEN',
                  'digitalocean-region=nyc2',
                  'digitalocean-size=4gb',
                  'digitalocean-private-networking',
                  'engine-registry-mirror=http://10.11.12.13:12345'
                ]
              },
              cache: {
                Type: 's3',
                s3: {
                  ServerAddress: 's3-eu-west-1.amazonaws.com',
                  AccessKey: 'AMAZON_S3_ACCESS_KEY',
                  SecretKey: 'AMAZON_S3_SECRET_KEY',
                  BucketName: 'runner',
                  Insecure: false
                }
              }
            }
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          verify_concat_fragment_exact_contents(
            catalogue,
            '/etc/gitlab-runner/config.toml - testrunner',
            [
              '[[runners]]',
              'url = "https://gitlab.com"',
              'token = "123456789abcdefgh"',
              'name = "autoscale-runner"',
              'executor = "docker+machine"',
              'limit = 10',
              '[runners.docker]',
              'image = "ruby:2.6"',
              '[runners.machine]',
              'OffPeakPeriods = ["* * 0-9,18-23 * * mon-fri *", "* * * * * sat,sun *"]',
              'OffPeakIdleCount = 1',
              'OffPeakIdleTime = 1200',
              'IdleCount = 5',
              'IdleTime = 600',
              'MaxBuilds = 100',
              'MachineName = "auto-scale-%s"',
              'MachineDriver = "digitalocean"',
              'MachineOptions = ["digitalocean-image=coreos-stable", "digitalocean-ssh-user=core", "digitalocean-access-token=DO_ACCESS_TOKEN", "digitalocean-region=nyc2", "digitalocean-size=4gb", "digitalocean-private-networking", "engine-registry-mirror=http://10.11.12.13:12345"]',
              '[runners.cache]',
              'Type = "s3"',
              '[runners.cache.s3]',
              'ServerAddress = "s3-eu-west-1.amazonaws.com"',
              'AccessKey = "AMAZON_S3_ACCESS_KEY"',
              'SecretKey = "AMAZON_S3_SECRET_KEY"',
              'BucketName = "runner"',
              'Insecure = false'
            ]
          )
        end
      end

      context 'with name not included in config' do
        let(:params) do
          {
            config: {
            }
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          verify_concat_fragment_exact_contents(
            catalogue,
            '/etc/gitlab-runner/config.toml - testrunner',
            [
              '[[runners]]',
              'name = "testrunner"'
            ]
          )
        end
      end

      context 'with name included in config' do
        let(:params) do
          {
            config: {
              name: 'foo-runner'
            }
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          verify_concat_fragment_exact_contents(
            catalogue,
            '/etc/gitlab-runner/config.toml - testrunner',
            [
              '[[runners]]',
              'name = "foo-runner"'
            ]
          )
        end
      end
    end
  end
end
