# @summary Manages the configuration of Gitlab runner
#
# @api private
#
class gitlab_ci_runner::config (
  $config_path    = $gitlab_ci_runner::config_path,
  $config_owner      = $gitlab_ci_runner::config_owner,
  $config_group      = $gitlab_ci_runner::config_group,
  $config_mode       = $gitlab_ci_runner::config_mode,
  $manage_config_dir = $gitlab_ci_runner::manage_config_dir,
  $config_dir_mode   = $gitlab_ci_runner::config_dir_mode,
  $concurrent     = $gitlab_ci_runner::concurrent,
  $check_interval = $gitlab_ci_runner::check_interval,
  $metrics_server = $gitlab_ci_runner::metrics_server,
  $listen_address = $gitlab_ci_runner::listen_address,
  $builds_dir     = $gitlab_ci_runner::builds_dir,
  $cache_dir      = $gitlab_ci_runner::cache_dir,
  $sentry_dsn     = $gitlab_ci_runner::sentry_dsn,
  $package_name   = $gitlab_ci_runner::package_name,
) {
  assert_private()

  file { $config_path: # ensure config exists
    ensure  => 'file',
    replace => 'no',
    content => '',
    owner   => $config_owner,
    group   => $config_group,
    mode    => $config_mode,
  }

  if $manage_config_dir {
    $_config_dir = dirname($config_path)

    file { $_config_dir:
      ensure => 'directory',
      owner  => $config_owner,
      group  => $config_group,
      mode   => $config_dir_mode,
    }
  }

  if $concurrent {
    file_line { 'gitlab-runner-concurrent':
      path  => $config_path,
      line  => "concurrent = ${concurrent}",
      match => '^concurrent = \d+',
    }
  }

  if $check_interval {
    file_line { 'gitlab-runner-check-interval':
      path  => $config_path,
      line  => "check_interval = ${check_interval}",
      match => '^check_interval = \d+',
    }
  }

  if $metrics_server {
    file_line { 'gitlab-runner-metrics_server':
      path  => $config_path,
      line  => "metrics_server = \"${metrics_server}\"",
      match => '^metrics_server = .+',
    }
  }

  if $listen_address {
    file_line { 'gitlab-runner-listen-address':
      path  => $config_path,
      line  => "listen_address = \"${listen_address}\"",
      match => '^listen_address = .+',
    }
  }

  if $builds_dir {
    file_line { 'gitlab-runner-builds_dir':
      path  => $config_path,
      line  => "builds_dir = \"${builds_dir}\"",
      match => '^builds_dir = .+',
    }
  }

  if $cache_dir {
    file_line { 'gitlab-runner-cache_dir':
      path  => $config_path,
      line  => "cache_dir = \"${cache_dir}\"",
      match => '^cache_dir = .+',
    }
  }

  if $sentry_dsn {
    file_line { 'gitlab-runner-sentry_dsn':
      path  => $config_path,
      line  => "sentry_dsn = \"${sentry_dsn}\"",
      match => '^sentry_dsn = .+',
    }
  }
}
