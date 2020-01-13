require 'spec_helper'

describe 'gitlab_ci_runner', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        # Workaround a puppet-spec issue Debian 9
        # https://github.com/rodjek/rspec-puppet/issues/629
        facts.merge(
          operatingsystemmajrelease: '9'
        )
      end
      let(:params) do
        {
          'runner_defaults' => {
            'url' => 'https://git.example.com/ci',
            'registration-token' => '1234567890abcdef',
            'executor' => 'docker',
            'docker-image' => 'ubuntu:trusty'
          },
          'runners' => {
            'test_runner' => {}
          }
        }
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('docker::images') }
      it { is_expected.to contain_package('gitlab-runner') }
      it { is_expected.to contain_service('gitlab-runner') }
      it { is_expected.to contain_class('gitlab_ci_runner::install') }
      it do
        is_expected.to contain_class('gitlab_ci_runner::config').
          that_requires('Class[gitlab_ci_runner::install]').
          that_notifies('Class[gitlab_ci_runner::service]')
      end
      it { is_expected.to contain_class('gitlab_ci_runner::service') }

      it do
        is_expected.to contain_concat('/etc/gitlab-runner/config.toml').
          with(
            ensure: 'present',
            owner: 'root',
            group: 'root',
            mode: '0444',
            ensure_newline: true
          )
      end

      it do
        is_expected.to contain_concat__fragment('/etc/gitlab-runner/config.toml - header').
          with(
            target: '/etc/gitlab-runner/config.toml',
            order: 0,
            content: '# MANAGED BY PUPPET'
          )
      end

      context 'with concurrent => 10' do
        let(:params) do
          {
            'concurrent' => 10
          }
        end

        it do
          is_expected.to contain_concat__fragment('/etc/gitlab-runner/config.toml - global options').
            with(
              target: '/etc/gitlab-runner/config.toml',
              order: 1,
              content: %r{concurrent = 10}
            )
        end
      end

      context 'with log_level => error' do
        let(:params) do
          {
            'log_level' => 'error'
          }
        end

        it do
          is_expected.to contain_concat__fragment('/etc/gitlab-runner/config.toml - global options').
            with(
              target: '/etc/gitlab-runner/config.toml',
              order: 1,
              content: %r{log_level = "error"}
            )
        end
      end

      context 'with log_format => json' do
        let(:params) do
          {
            'log_format' => 'json'
          }
        end

        it do
          is_expected.to contain_concat__fragment('/etc/gitlab-runner/config.toml - global options').
            with(
              target: '/etc/gitlab-runner/config.toml',
              order: 1,
              content: %r{log_format = "json"}
            )
        end
      end

      context 'with check_interval => 6' do
        let(:params) do
          {
            'check_interval' => 6
          }
        end

        it do
          is_expected.to contain_concat__fragment('/etc/gitlab-runner/config.toml - global options').
            with(
              target: '/etc/gitlab-runner/config.toml',
              order: 1,
              content: %r{check_interval = 6}
            )
        end
      end

      context 'with sentry_dsn => https://123abc@localhost/1' do
        let(:params) do
          {
            'sentry_dsn' => 'https://123abc@localhost/1'
          }
        end

        it do
          is_expected.to contain_concat__fragment('/etc/gitlab-runner/config.toml - global options').
            with(
              target: '/etc/gitlab-runner/config.toml',
              order: 1,
              content: %r{sentry_dsn = "https://123abc@localhost/1"}
            )
        end
      end

      context 'with listen_address => localhost:9252' do
        let(:params) do
          {
            'listen_address' => 'localhost:9252'
          }
        end

        it do
          is_expected.to contain_concat__fragment('/etc/gitlab-runner/config.toml - global options').
            with(
              target: '/etc/gitlab-runner/config.toml',
              order: 1,
              content: %r{listen_address = "localhost:9252"}
            )
        end
      end

      context 'with ensure => present' do
        let(:params) do
          super().merge(
            'runners' => {
              'test_runner' => {
                'ensure' => 'present'
              }
            }
          )
        end

        it { is_expected.to contain_gitlab_ci_runner__runner('test_runner') }
        it { is_expected.to contain_exec('Register_runner_test_runner').with('command' => %r{/usr/bin/[^ ]+ register }) }
        it { is_expected.not_to contain_exec('Register_runner_test_runner').with('command' => %r{--ensure=}) }
      end

      context 'with ensure => absent' do
        let(:params) do
          super().merge(
            'runners' => {
              'test_runner' => {
                'ensure' => 'absent'
              }
            }
          )
        end

        it { is_expected.to contain_gitlab_ci_runner__runner('test_runner') }
        it { is_expected.to contain_exec('Unregister_runner_test_runner').with('command' => %r{/usr/bin/[^ ]+ unregister }) }
        it { is_expected.not_to contain_exec('Unregister_runner_test_runner').with('command' => %r{--ensure=}) }
      end

      context 'with manage_repo => true' do
        let(:params) do
          super().merge(
            manage_repo: true
          )
        end

        it { is_expected.to compile }
        it { is_expected.to contain_class('gitlab_ci_runner::repo') }

        case facts[:os]['family']
        when 'Debian'
          it do
            is_expected.to contain_apt__source('apt_gitlabci').
              with(
                comment: 'GitlabCI Runner Repo',
                location: "https://packages.gitlab.com/runner/gitlab-runner/#{facts[:lsbdistid].downcase}/",
                repos: 'main',
                key: {
                  'id' => '1A4C919DB987D435939638B914219A96E15E78F4',
                  'server' => 'keys.gnupg.net'
                },
                include: {
                  'src' => false,
                  'deb' => true
                }
              )
          end
        when 'RedHat'
          it do
            is_expected.to contain_yumrepo('runner_gitlab-runner').
              with(
                ensure: 'present',
                baseurl: "https://packages.gitlab.com/runner/gitlab-runner/el/\$releasever/\$basearch",
                descr: 'runner_gitlab-runner',
                enabled: '1',
                gpgcheck: '0',
                gpgkey: 'https://packages.gitlab.com/gpg.key',
                repo_gpgcheck: '1',
                sslcacert: '/etc/pki/tls/certs/ca-bundle.crt',
                sslverify: '1'
              )
          end

          it do
            is_expected.to contain_yumrepo('runner_gitlab-runner-source').
              with(
                ensure: 'present',
                baseurl: "https://packages.gitlab.com/runner/gitlab-runner/el/\$releasever/SRPMS",
                descr: 'runner_gitlab-runner-source',
                enabled: '1',
                gpgcheck: '0',
                gpgkey: 'https://packages.gitlab.com/gpg.key',
                repo_gpgcheck: '1',
                sslcacert: '/etc/pki/tls/certs/ca-bundle.crt',
                sslverify: '1'
              )
          end
        end
      end
    end
  end
end
