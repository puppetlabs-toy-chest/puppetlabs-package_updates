class package_updates (
  $minute   = undef,
  $hour     = 3,
  $month    = undef,
  $monthday = undef,
  $weekday  = undef,
) {
  if $::kernel != 'windows' {

    # This is dumb but we must count on this directory existing
    # and it may be managed somewhere else
    exec { 'create facts.d':
      command => 'mkdir -p /etc/puppetlabs/facter/facts.d/',
      path    => '/bin:/usr/bin',
      creates => '/etc/puppetlabs/facter/facts.d/',
    }

    cron { 'package_updates':
      command  => 'puppet package updates --render-as json > /etc/puppetlabs/facter/facts.d/package_updates.json',
      minute   => $minute,
      hour     => $hour,
      month    => $month,
      monthday => $monthday,
      weekday  => $weekday,
    }
  } else {
    notice('The package_updates class only supports non-Windows systems currently')
  }
}
