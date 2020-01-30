# @summary This module installs and configures Gitlab CI Runners.
#
# @example Simple runner registration
#		class { 'gitlab_ci_runner':
#		  runners => {
#		 	 example_runner => {
#		 		 'registration-token' => 'gitlab-token',
#		 		 'url'                => 'https://gitlab.com',
#		 		 'tag-list'           => 'docker,aws',
#		 	 },
#		  },
#		}
#
# @param runners
#   Hashkeys are used as $title in runners.pp. The subkeys have to be named as the parameter names from ´gitlab-runner register´ command cause they're later joined to one entire string using 2 hyphen to look like shell command parameters. See ´https://docs.gitlab.com/runner/register/#one-line-registration-command´ for details.
# @param runner_defaults
#   A hash with defaults which will be later merged with $runners.
# @param xz_package_name
#   The name of the 'xz' package. Needed for local docker installations.
# @param concurrent
#   Limits how many jobs globally can be run concurrently. The most upper limit of jobs using all defined runners. 0 does not mean unlimited!
# @param log_level
#   Log level (options: debug, info, warn, error, fatal, panic). Note that this setting has lower priority than level set by command line argument --debug, -l or --log-level
# @param log_format
#   Log format (options: runner, text, json). Note that this setting has lower priority than format set by command line argument --log-format
# @param check_interval
#   defines the interval length, in seconds, between new jobs check. The default value is 3; if set to 0 or lower, the default value will be used.
# @param sentry_dsn
#   Enable tracking of all system level errors to sentry.
# @param listen_address
#   Address (<host>:<port>) on which the Prometheus metrics HTTP server should be listening.
# @param manage_docker
#   If docker should be installs (uses the puppetlabs-docker).
# @param manage_repo
#   If the repository should be managed.
# @param package_ensure
#   The package 'ensure' state.
# @param package_name
#   The name of the package.
# @param repo_base_url
#   The base repository url.
# @param repo_keyserver
#   The keyserver which should be used to get the repository key.
# @param config_path
#   The path to the config file of Gitlab runner.
#
class gitlab_ci_runner (
  String                                 $xz_package_name, # Defaults in module hieradata
  Hash                                   $runners                  = {},
  Hash                                   $runner_defaults          = {},
  Optional[Integer]                      $concurrent               = undef,
  Optional[Gitlab_ci_runner::Log_level]  $log_level                = undef,
  Optional[Gitlab_ci_runner::Log_format] $log_format               = undef,
  Optional[Integer]                      $check_interval           = undef,
  Optional[String]                       $sentry_dsn               = undef,
  Optional[Pattern[/.*:.+/]]             $listen_address           = undef,
  Boolean                                $manage_docker            = false,
  Boolean                                $manage_repo              = true,
  String                                 $package_ensure           = installed,
  String                                 $package_name             = 'gitlab-runner',
  Stdlib::HTTPUrl                        $repo_base_url            = 'https://packages.gitlab.com',
  Optional[Stdlib::Fqdn]                 $repo_keyserver           = undef,
  String                                 $config_path              = '/etc/gitlab-runner/config.toml',
){
  if $manage_docker {
    # workaround for cirunner issue #1617
    # https://gitlab.com/gitlab-org/gitlab-ci-multi-runner/issues/1617
    ensure_packages($xz_package_name)

    $docker_images = {
      ubuntu_trusty => {
        image     => 'ubuntu',
        image_tag => 'trusty',
      },
    }

    include docker
    class { 'docker::images':
      images => $docker_images,
    }
  }

  if $manage_repo {
    contain gitlab_ci_runner::repo
  }

  contain gitlab_ci_runner::install
  contain gitlab_ci_runner::config
  contain gitlab_ci_runner::service

  Class['gitlab_ci_runner::install']
  -> Class['gitlab_ci_runner::config']
  ~> Class['gitlab_ci_runner::service']

  $runners.each |$runner_name,$config| {
    $_config = merge($runner_defaults, $config)
    $title   = $_config['name'] ? {
      undef   => $runner_name,
      default => $_config['name'],
    }

    gitlab_ci_runner::runner { $title:
      config  => $_config - ['ensure', 'name'],
      require => Class['gitlab_ci_runner::config'],
      notify  => Class['gitlab_ci_runner::service'],
    }
  }
}
