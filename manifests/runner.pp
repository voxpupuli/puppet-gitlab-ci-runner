# @summary This configures a Gitlab CI runner.
#
# @example Add a simple runner
#   gitlab_ci_runner::runner { 'testrunner':
#     config               => {
#       'url'              => 'https://gitlab.com',
#       'token'            => '123456789abcdefgh', # Note this is different from the registration token used by `gitlab-runner register`
#       'executor'         => 'shell',
#     },
#   }
#
# @example Add a autoscaling runner with DigitalOcean as IaaS
#   gitlab_ci_runner::runner { 'autoscale-runner':
#     config => {
#      url      => 'https://gitlab.com',
#      token    => 'RUNNER_TOKEN', # Note this is different from the registration token used by `gitlab-runner register`
#      name     => 'autoscale-runner',
#      executor => 'docker+machine',
#      limit    => 10,
#      docker   => {
#        image => 'ruby:2.6',
#      },
#      machine  => {
#        OffPeakPeriods   => [
#          '* * 0-9,18-23 * * mon-fri *',
#          '* * * * * sat,sun *',
#        ],
#        OffPeakIdleCount => 1,
#        OffPeakIdleTime  => 1200,
#        IdleCount        => 5,
#        IdleTime         => 600,
#        MaxBuilds        => 100,
#        MachineName      => 'auto-scale-%s',
#        MachineDriver    => 'digitalocean',
#        MachineOptions   => [
#          'digitalocean-image=coreos-stable',
#          'digitalocean-ssh-user=core',
#          'digitalocean-access-token=DO_ACCESS_TOKEN',
#          'digitalocean-region=nyc2',
#          'digitalocean-size=4gb',
#          'digitalocean-private-networking',
#          'engine-registry-mirror=http://10.11.12.13:12345',
#        ],
#      },
#      cache    => {
#        'Type' => 's3',
#        s3     => {
#          ServerAddress => 's3-eu-west-1.amazonaws.com',
#          AccessKey     => 'AMAZON_S3_ACCESS_KEY',
#          SecretKey     => 'AMAZON_S3_SECRET_KEY',
#          BucketName    => 'runner',
#          Insecure      => false,
#        },
#      },
#     },
#   }
#
# @param config
#   Hash with configuration options.
#   See https://docs.gitlab.com/runner/configuration/advanced-configuration.html for all possible options.
#   If you omit the 'name' configuration, we will automatically use the $title of this define class.
#
define gitlab_ci_runner::runner (
  Hash $config,
) {
  include gitlab_ci_runner

  $config_path = $gitlab_ci_runner::config_path

  # Use title parameter if config hash doesn't contain one.
  $_config     = $config['name'] ? {
    undef   => merge($config, { name => $title }),
    default => $config,
  }

  $__config = { runners => [ $_config ], }

  concat::fragment { "${config_path} - ${title}":
    target  => $config_path,
    order   => 2,
    content => inline_template("<%= require 'toml-rb'; TomlRB.dump(@__config) %>"),
  }
}
