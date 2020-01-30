# @summary Manages the configuration of Gitlab runner
#
# @api private
#
class gitlab_ci_runner::config (
  $config_path    = $gitlab_ci_runner::config_path,
  $concurrent     = $gitlab_ci_runner::concurrent,
  $log_level      = $gitlab_ci_runner::log_level,
  $log_format     = $gitlab_ci_runner::log_format,
  $check_interval = $gitlab_ci_runner::check_interval,
  $sentry_dsn     = $gitlab_ci_runner::sentry_dsn,
  $listen_address = $gitlab_ci_runner::listen_address,
  $package_name   = $gitlab_ci_runner::package_name,
) {
  assert_private()

  concat { $config_path:
    ensure         => present,
    owner          => 'root',
    group          => 'root',
    mode           => '0444',
    ensure_newline => true,
  }

  $global_options = {
    concurrent     => $concurrent,
    log_level      => $log_level,
    log_format     => $log_format,
    check_interval => $check_interval,
    sentry_dsn     => $sentry_dsn,
    listen_address => $listen_address,
  }.filter |$key, $val| { $val =~ NotUndef }

  concat::fragment { "${config_path} - header":
    target  => $config_path,
    order   => 0,
    content => '# MANAGED BY PUPPET',
  }

  concat::fragment { "${config_path} - global options":
    target  => $config_path,
    order   => 1,
    content => inline_template("<%= require 'toml-rb'; TomlRB.dump(@global_options) %>"),
  }
}
