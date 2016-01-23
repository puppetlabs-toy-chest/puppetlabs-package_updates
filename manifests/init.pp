class package_updates (

  Enum['daily','weekly','monthly','once'] $schedule = 'daily',

  Variant[
    Integer[0,59],
    Array[
      Integer[0,59]
    ]
  ] $minute = [0,1,2,3,4,5,6,7,8,9,],

  Integer[0,23] $hour = 3,

  Variant[
    Integer[1,12],
    Array[Integer[1,12]],
    Enum[
      'january', 'february', 'march','april','may','june',
      'july','august','september','october','november','december','all'
    ]
  ] $month = 'all',

  Variant[
    Integer[1,31],
    Array[Integer[1,31]],
    Enum['all']
  ] $monthday = 'all',

  Variant[
    Integer[0,7],
    Array[Integer[0,7]],
    Enum[
      'sunday','monday','tuesday','wednesday',
      'thursday','friday','saturday','sunday','all'
    ]
  ] $weekday  = 'all',
) {

  # If all is specified, just build an
  # array of every month day number
  $_monthday = $monthday ? {
    'all'   => range('1','31'),
    default => $monthday,
  }

  # If all is specified, just build an
  # array of every week day number
  $_weekday = $weekday ? {
    'all'   => range('1','7'),
    default => $weekday,
  }

  # If all is specified, just build an
  # array of every month number
  $_month = $month ? {
    'all'   => range('1','12'),
    default => $month
  }

  $updates_command = "puppet package updates --render-as json"

  if $::kernel != 'windows' {
    $facts_d_directory = '/opt/puppetlabs/facter/facts.d'

    cron { 'package_updates':
      command  => "${updates_command} > ${facts_d_directory}",
      minute   => $minute,
      hour     => $hour,
      month    => $_month,
      monthday => $_monthday,
      weekday  => $_weekday,
    }
  } else {
    notice('The package_updates class only supports non-Windows systems currently')
  }
}
