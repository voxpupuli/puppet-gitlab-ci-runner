require 'spec_helper_acceptance'

describe 'gitlab_ci_runner::runner define' do
  context 'simple runner' do
    it 'idempotently with no errors' do
      pp = <<-EOS
      gitlab_ci_runner::runner { 'testrunner':
        config => {
          'url'      => 'https://gitlab.com',
          'token'    => '123456789abcdefgh',
          'executor' => 'shell',
        },
      }
      EOS

      shell('/opt/puppetlabs/puppet/bin/gem install toml-rb')
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe package('gitlab-runner') do
      it { is_expected.to be_installed }
    end

    describe service('gitlab-runner') do
      it { is_expected.to be_running }
      it { is_expected.to be_enabled }
    end

    describe file('/etc/gitlab-runner/config.toml') do
      it { is_expected.to contain '[[runners]]' }
      it { is_expected.to contain 'name = "testrunner"' }
      it { is_expected.to contain 'url = "https://gitlab.com"' }
      it { is_expected.to contain 'token = "123456789abcdefgh"' }
      it { is_expected.to contain 'executor = "shell"' }
    end
  end

  context 'autoscaling runner with DigitalOcean as IaaS' do
    it 'idempotently with no errors' do
      pp = <<-EOS
      gitlab_ci_runner::runner { 'autoscale-runner':
        config => {
         url      => 'https://gitlab.com',
         token    => '123456789abcdefgh',
         name     => 'autoscale-runner',
         executor => 'docker+machine',
         limit    => 10,
         docker   => {
           image => 'ruby:2.6',
         },
         machine  => {
           'OffPeakPeriods'   => [
             '* * 0-9,18-23 * * mon-fri *',
             '* * * * * sat,sun *',
           ],
           'OffPeakIdleCount' => 1,
           'OffPeakIdleTime'  => 1200,
           'IdleCount'        => 5,
           'IdleTime'         => 600,
           'MaxBuilds'        => 100,
           'MachineName'      => 'auto-scale-%s',
           'MachineDriver'    => 'digitalocean',
           'MachineOptions'   => [
             'digitalocean-image=coreos-stable',
             'digitalocean-ssh-user=core',
             'digitalocean-access-token=DO_ACCESS_TOKEN',
             'digitalocean-region=nyc2',
             'digitalocean-size=4gb',
             'digitalocean-private-networking',
             'engine-registry-mirror=http://10.11.12.13:12345',
           ],
         },
         cache    => {
           'Type' => 's3',
           s3     => {
             'ServerAddress' => 's3-eu-west-1.amazonaws.com',
             'AccessKey'     => 'AMAZON_S3_ACCESS_KEY',
             'SecretKey'     => 'AMAZON_S3_SECRET_KEY',
             'BucketName'    => 'runner',
             'Insecure'      => false,
           },
         },
        },
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe package('gitlab-runner') do
      it { is_expected.to be_installed }
    end

    describe service('gitlab-runner') do
      it { is_expected.to be_running }
      it { is_expected.to be_enabled }
    end

    describe file('/etc/gitlab-runner/config.toml') do
      it { is_expected.to contain '[[runners]]' }
      it { is_expected.to contain 'url = "https://gitlab.com"' }
      it { is_expected.to contain 'token = "123456789abcdefgh"' }
      it { is_expected.to contain 'name = "autoscale-runner"' }
      it { is_expected.to contain 'executor = "docker+machine"' }
      it { is_expected.to contain 'limit = 10' }
      it { is_expected.to contain '[runners.docker]' }
      it { is_expected.to contain 'image = "ruby:2.6"' }
      it { is_expected.to contain '[runners.machine]' }
      it { is_expected.to contain 'OffPeakPeriods = ["* * 0-9,18-23 * * mon-fri *", "* * * * * sat,sun *"]' }
      it { is_expected.to contain 'OffPeakIdleCount = 1' }
      it { is_expected.to contain 'OffPeakIdleTime = 1200' }
      it { is_expected.to contain 'IdleCount = 5' }
      it { is_expected.to contain 'IdleTime = 600' }
      it { is_expected.to contain 'MaxBuilds = 100' }
      it { is_expected.to contain 'MachineName = "auto-scale-%s"' }
      it { is_expected.to contain 'MachineDriver = "digitalocean"' }
      it { is_expected.to contain 'MachineOptions = ["digitalocean-image=coreos-stable", "digitalocean-ssh-user=core", "digitalocean-access-token=DO_ACCESS_TOKEN", "digitalocean-region=nyc2", "digitalocean-size=4gb", "digitalocean-private-networking", "engine-registry-mirror=http://10.11.12.13:12345"]' }
      it { is_expected.to contain '[runners.cache]' }
      it { is_expected.to contain 'Type = "s3"' }
      it { is_expected.to contain '[runners.cache.s3]' }
      it { is_expected.to contain 'ServerAddress = "s3-eu-west-1.amazonaws.com"' }
      it { is_expected.to contain 'AccessKey = "AMAZON_S3_ACCESS_KEY"' }
      it { is_expected.to contain 'SecretKey = "AMAZON_S3_SECRET_KEY"' }
      it { is_expected.to contain 'BucketName = "runner"' }
      it { is_expected.to contain 'Insecure = false' }
    end
  end
end
