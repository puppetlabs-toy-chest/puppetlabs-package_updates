class package_updates (
  Array[String] $precommand= [],

  Enum['daily','weekly','monthly','once'] $schedule = 'daily',

  Variant[
    Integer[0,59],
    Array[
      Integer[0,59]
    ],
    Enum['all']
  ] $minute = 0,

  Variant[
    Integer[0,23],
    Array[
      Integer[0,23]
    ],
    Enum['all']
  ] $hour = 3,

  Variant[
    Integer[1,12],
    Array[Integer[1,12]],
    Array[
      Enum[
        'january', 'february', 'march','april','may','june',
        'july','august','september','october','november','december'
      ]
    ],
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
    Array[
      Enum[
        'sunday','monday','tuesday','wednesday',
        'thursday','friday','saturday','sunday'
      ]
    ],
    Enum[
      'sunday','monday','tuesday','wednesday',
      'thursday','friday','saturday','sunday','all'
    ]
  ] $weekday  = 'all',

  $puppet_path,
  $facts_d_directory,
  $tmp_path,

) {

  # If all is specified, just build an
  # array of every minute
  $_hour = $hour ? {
    'all'   => range('0','23'),
    default => $hour
  }

  # If all is specified, just build an
  # array of every minute
  $_minute = $minute ? {
    'all'   => range('0','59'),
    default => $minute
  }

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

  $updates_subcommand = "package updates --render-as json"

  if $::kernel != 'windows' {

    if $precommand != [] {
      $precmd="${join($precommand,';')};"
    } else {
      $precmd=''
    }
    # The `package updates` command takes a long time to run. Since the command is using shell
    # redirection, the target file is truncated prior to the `package updates` command being run.
    # Thus Facter will throw an error while looking up the package_updates fact if Facter is run
    # while the cron job is executing. So instead we'll output to a tmp file and mv the
    # file into place when the `package_updates` command is done executing.
    $command = "${precmd}${puppet_path} ${updates_subcommand} > ${tmp_path} && mv -f ${tmp_path} ${facts_d_directory}/"

    cron { 'package_updates':
      command  => $command,
      minute   => $_minute,
      hour     => $_hour,
      month    => $_month,
      monthday => $_monthday,
      weekday  => $_weekday,
    }
  } else {
    notice('The package_updates class only supports non-Windows systems currently')
  }
}
