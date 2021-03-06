# Set up the master with user accounts, environments, etc
class classroom::master (
  $jvm_tuning_profile = $classroom::params::jvm_tuning_profile,
) {
  assert_private('This class should not be called directly')

  # Workaround for pip
  file {'/usr/bin/pip-python':
    ensure => link,
    target => '/usr/bin/pip',
  }

  # Install the Gitea hosted git repository service
  include classroom::master::gitea

  # Add the installer files for student agents
  # These files are cached by the build, so this will work offline
  include pe_repo::platform::el_6_i386
  include pe_repo::platform::windows_x86_64

  # Anything that needs to be top scope
  file { "${classroom::codedir}/environments/production/manifests/classroom.pp":
    ensure => file,
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '0644',
    source => 'puppet:///modules/classroom/classroom.pp',
  }

  # if configured to do so, configure repos & environments on the master. This
  # overrides the resource in the puppet_enterprise module and allows us to have
  # different users updating their own repositories.
  if $classroom::manage_repos {
    $environmentspath = "${classroom::codedir}/environments"

    # 2015.2.x manages the environmentpath but doesn't allow users to write
    if versioncmp($::pe_server_version,'2015.3.0') < 0 {
      File <| title == $environmentspath |> {
        mode => '1777',
      }
    }
    # 2015.3.x doesn't manage the environmentpath
    else {
      file { $environmentspath:
        ensure => directory,
        mode   => '1777',
      }
    }

    include classroom::master::repositories
  }

  # Ensure that time is set appropriately
  include classroom::master::time

  # Configure Hiera and install a Hiera data file to control PE configuration
  class { 'classroom::master::tuning':
    jvm_tuning_profile => $jvm_tuning_profile,
  }

  # make sure we have a deployment user
  include classroom::master::deployer

  # Setup Windows Powershell Scripts
  include classroom::master::windows

  # Now create all of the users who've checked in
  Classroom::User <<||>>
  # But prevent students from overwriting the login ssh key
  user { 'training':
    ensure => present,
  }

  # Add files required for labs (mostly for offline mode)
  include classroom::master::lab_files

  # Configure performance logging
  include classroom::master::perf_logging

}
