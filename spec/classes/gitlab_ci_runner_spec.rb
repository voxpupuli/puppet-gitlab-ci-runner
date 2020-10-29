require 'spec_helper'

describe 'gitlab_ci_runner', type: :class do
  let(:undef_value) do
    Puppet::Util::Package.versioncmp(Puppet.version, '6.0.0') < 0 ? :undef : nil
  end

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
            'executor' => 'shell'
          },
          'runners' => {
            'test_runner' => {}
          }
        }
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.not_to contain_class('docker') }
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
      it { is_expected.to contain_file('/etc/gitlab-runner/config.toml') }

      it { is_expected.not_to contain_file_line('gitlab-runner-concurrent') }
      it { is_expected.not_to contain_file_line('gitlab-runner-check-interval') }
      it { is_expected.not_to contain_file_line('gitlab-runner-metrics_server') }
      it { is_expected.not_to contain_file_line('gitlab-runner-builds_dir') }
      it { is_expected.not_to contain_file_line('gitlab-runner-cache_dir') }

      context 'with config_path => /etc/runner.toml' do
        let(:params) do
          {
            'runner_defaults' => {},
            'runners' => {},
            'config_path' => '/etc/runner.toml'
          }
        end

        it do
          is_expected.to contain_file('/etc/runner.toml').with('ensure'  => 'file',
                                                               'replace' => 'no',
                                                               'content' => '')
        end
      end
      context 'with config permissions' do
        let(:params) do
          {
            'runner_defaults' => {},
            'runners' => {},
            'config_owner' => 'gitlab-runner',
            'config_group' => 'gitlab-runner',
            'config_mode' => '0640'
          }
        end

        it do
          is_expected.to contain_file('/etc/gitlab-runner/config.toml').with('owner' => 'gitlab-runner',
                                                                             'group' => 'gitlab-runner',
                                                                             'mode'  => '0640')
        end
      end
      context 'with manage_config_dir => true' do
        let(:params) do
          {
            'runner_defaults' => {},
            'runners' => {},
            'manage_config_dir' => true
          }
        end

        it do
          is_expected.to contain_file('/etc/gitlab-runner').with('ensure' => 'directory')
        end
      end
      context 'with config dir permissions' do
        let(:params) do
          {
            'runner_defaults' => {},
            'runners' => {},
            'manage_config_dir' => true,
            'config_owner' => 'gitlab-runner',
            'config_group' => 'gitlab-runner',
            'config_dir_mode' => '0750'
          }
        end

        it do
          is_expected.to contain_file('/etc/gitlab-runner').with('ensure' => 'directory',
                                                                 'owner' => 'gitlab-runner',
                                                                 'group' => 'gitlab-runner',
                                                                 'mode'  => '0750')
        end
      end
      context 'with concurrent => 10' do
        let(:params) do
          {
            'runner_defaults' => {},
            'runners' => {},
            'concurrent' => 10
          }
        end

        it do
          is_expected.to contain_file_line('gitlab-runner-concurrent').with('path' => '/etc/gitlab-runner/config.toml',
                                                                            'line'  => 'concurrent = 10',
                                                                            'match' => '^concurrent = \d+')
        end
      end
      context 'with check_interval => 10' do
        let(:params) do
          {
            'runner_defaults' => {},
            'runners' => {},
            'check_interval' => 10
          }
        end

        it do
          is_expected.to contain_file_line('gitlab-runner-check-interval').with('path' => '/etc/gitlab-runner/config.toml',
                                                                                'line'  => 'check_interval = 10',
                                                                                'match' => '^check_interval = \d+')
        end
      end
      context 'with metrics_server => localhost:9252' do
        let(:params) do
          {
            'runner_defaults' => {},
            'runners' => {},
            'metrics_server' => 'localhost:9252'
          }
        end

        it do
          is_expected.to contain_file_line('gitlab-runner-metrics_server').with('path' => '/etc/gitlab-runner/config.toml',
                                                                                'line'  => 'metrics_server = "localhost:9252"',
                                                                                'match' => '^metrics_server = .+')
        end
      end
      context 'with listen_address => localhost:9252' do
        let(:params) do
          {
            'runner_defaults' => {},
            'runners' => {},
            'listen_address' => 'localhost:9252'
          }
        end

        it do
          is_expected.to contain_file_line('gitlab-runner-listen-address').
            with(
              path: '/etc/gitlab-runner/config.toml',
              line: 'listen_address = "localhost:9252"',
              match: '^listen_address = .+'
            )
        end
      end
      context 'with builds_dir => /tmp/builds_dir' do
        let(:params) do
          {
            'runner_defaults' => {},
            'runners' => {},
            'builds_dir' => '/tmp/builds_dir'
          }
        end

        it do
          is_expected.to contain_file_line('gitlab-runner-builds_dir').with('path' => '/etc/gitlab-runner/config.toml',
                                                                            'line'  => 'builds_dir = "/tmp/builds_dir"',
                                                                            'match' => '^builds_dir = .+')
        end
      end
      context 'with cache_dir => /tmp/cache_dir' do
        let(:params) do
          {
            'runner_defaults' => {},
            'runners' => {},
            'cache_dir' => '/tmp/cache_dir'
          }
        end

        it do
          is_expected.to contain_file_line('gitlab-runner-cache_dir').with('path' => '/etc/gitlab-runner/config.toml',
                                                                           'line'  => 'cache_dir = "/tmp/cache_dir"',
                                                                           'match' => '^cache_dir = .+')
        end
      end
      context 'with sentry_dsn => https://123abc@localhost/1' do
        let(:params) do
          {
            'runner_defaults' => {},
            'runners' => {},
            'sentry_dsn' => 'https://123abc@localhost/1'
          }
        end

        it do
          is_expected.to contain_file_line('gitlab-runner-sentry_dsn').with('path' => '/etc/gitlab-runner/config.toml',
                                                                            'line'  => 'sentry_dsn = "https://123abc@localhost/1"',
                                                                            'match' => '^sentry_dsn = .+')
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
                  'ubuntu_focal' => {
                    'image'     => 'ubuntu',
                    'image_tag' => 'focal'
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
                  'id' => 'F6403F6544A38863DAA0B6E03F01618A51312F3F',
                  'server' => undef_value
                },
                include: {
                  'src' => false,
                  'deb' => true
                }
              )
          end
        when 'RedHat'
          os_release_version = if facts[:os]['name'] == 'Amazon'
                                 if facts[:os]['release']['major'] == '2'
                                   '7'
                                 else
                                   '6'
                                 end
                               else
                                 '$releasever'
                               end

          it do
            is_expected.to contain_yumrepo('runner_gitlab-runner').
              with(
                ensure: 'present',
                baseurl: "https://packages.gitlab.com/runner/gitlab-runner/el/#{os_release_version}/\$basearch",
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
                baseurl: "https://packages.gitlab.com/runner/gitlab-runner/el/#{os_release_version}/SRPMS",
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

      if facts[:os]['family'] == 'Debian'
        context 'with manage_repo => true and repo_keyserver => keys.gnupg.net' do
          let(:params) do
            super().merge(
              manage_repo: true,
              repo_keyserver: 'keys.gnupg.net'
            )
          end

          it { is_expected.to compile }
          it { is_expected.to contain_class('gitlab_ci_runner::repo') }

          it do
            is_expected.to contain_apt__source('apt_gitlabci').with_key('id' => 'F6403F6544A38863DAA0B6E03F01618A51312F3F', 'server' => 'keys.gnupg.net')
          end
        end
      end
    end
  end
end
