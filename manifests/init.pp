class package_updates (
  $minute   = undef,
  $hour     = 3,
  $month    = undef,
  $monthday = undef,
  $weekday  = undef,
) {
  cron { 'package_updates':
    command  => 'puppet package updates --render-as json  > /etc/puppetlabs/facter/facts.d/package_updates.json',
    minute   => $minute,
    hour     => $hour,
    month    => $month,
    monthday => $monthday,
    weekday  => $weekday,
  }
}
