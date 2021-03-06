# This is a wrapper class to include all the bits needed for Fundamentals
#
class classroom::course::windows (
  $offline            = $classroom::params::offline,
  $manage_yum         = $classroom::params::manage_yum,
  $time_servers       = $classroom::params::time_servers,
  $jvm_tuning_profile = $classroom::params::jvm_tuning_profile,
  $event_id           = undef,
  $event_pw           = undef,
  $version            = undef,
) inherits classroom::params {
  # just wrap the classroom class
  class { 'classroom':
    offline            => $offline,
    role               => $role,
    manage_yum         => $manage_yum,
    time_servers       => $time_servers,
    jvm_tuning_profile => $jvm_tuning_profile,
  }

  if $role == 'master' {
    class { 'classroom::master::showoff':
      course             => 'WindowsEssentials',
      event_id           => $event_id,
      event_pw           => $event_pw,
      version            => $version,
    }
  }

  if $::osfamily == 'Windows' {
    include classroom::windows
  }
}
