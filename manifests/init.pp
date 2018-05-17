# This module manages timezone settings
#
# @param timezone
#     The name of the timezone.
#
# @param ensure
#     Ensure if present or absent.
#
# @param autoupgrade
#     Upgrade package automatically, if there is a newer version.
#
# @param package
#     Name of the package.
#     Only set this, if your platform is not supported or you know, what you're doing.
#
# @param config_file
#     Main configuration file.
#     Only set this, if your platform is not supported or you know, what you're doing.
#
# @param zoneinfo_dir
#     Source directory of zoneinfo files.
#     Only set this, if your platform is not supported or you know, what you're doing.
#     Default: auto-set, platform specific
#
# @param hwutc
#     Is the hardware clock set to UTC? (true or false)
#
# @param notify_services
#     List of services to notify
#
# @example
#   class { 'timezone':
#     timezone => 'Europe/Berlin',
#   }
#
class timezone (
  String                   $timezone                       = 'Etc/UTC',
  Enum['present','absent'] $ensure                         = 'present',
  Optional[Boolean]        $hwutc                          = undef,
  Boolean                  $autoupgrade                    = false,
  Optional[Array[String]]  $notify_services                = undef,
  Optional[String]         $package                        = undef,
  String                   $zoneinfo_dir                   = '/usr/share/zoneinfo/',
  String                   $localtime_file                 = '/etc/localtime',
  Optional[String]         $timezone_file                  = undef,
  Optional[String]         $timezone_file_template         = 'timezone/clock.erb',
  Optional[Boolean]        $timezone_file_supports_comment = undef,
  Optional[String]         $timezone_update                = undef
) {

  notice("timezone file = $timezone_file")
  case $ensure {
    /(present)/: {
      if $autoupgrade == true {
        $package_ensure = 'latest'
      } else {
        $package_ensure = 'present'
      }
      $localtime_ensure = 'link'
      $timezone_ensure = 'file'
    }
    /(absent)/: {
      # Leave package installed, as it is a system dependency
      $package_ensure = 'present'
      #$localtime_ensure = 'absent'
      $timezone_ensure = 'absent'
    }
    default: {
      fail('ensure parameter must be present or absent')
    }
  }

  file { $localtime_file:
    ensure => $localtime_ensure,
    source => "file://${zoneinfo_dir}/${timezone}",
    links  => follow,
    notify => $notify_services,
  }

  if $timezone_file {
    file { $timezone_file:
      ensure  => $timezone_ensure,
      content => template($timezone_file_template),
      notify  => $notify_services,
    }
    if $ensure == 'present' and $timezone_update {
      $e_command = $facts['os']['family'] ? {
        /(Suse|Archlinux)/ => "${timezone_update} ${timezone}",
        default            => $timezone_update,
      }
      notice("timezone file cmd ($e_command)")
      exec { 'update_timezone':
        command     => $e_command,
        path        => '/usr/bin:/usr/sbin:/bin:/sbin',
        subscribe   => File[$timezone_file],
        refreshonly => true,
      }
    }
  }


}
