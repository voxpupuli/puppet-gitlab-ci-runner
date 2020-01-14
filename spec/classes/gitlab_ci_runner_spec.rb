require 'spec_helper'

describe 'gitlab_ci_runner', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
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

      it { is_expected.not_to contain_class('docker::images') }
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

      # puppetlabs-docker doesn't support CentOS 6 anymore.
      unless facts[:os]['name'] == 'CentOS' && facts[:os]['release']['major'] == '6'
        context 'with manage_docker => true' do
          let(:params) do
            {
              manage_docker: true
            }
          end

          it { is_expected.to compile }

          it { is_expected.to contain_class('docker') }
          it do
            is_expected.to contain_class('docker::images').
              with(
                images: {
                  'ubuntu_trusty' => {
                    'image'     => 'ubuntu',
                    'image_tag' => 'trusty'
                  }
                }
              )
          end
        end
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
