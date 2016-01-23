class package_updates::pe_master {
  pe_ini_setting { 'set package update catalog terminus':
    section => 'master',
    setting => 'catalog_terminus',
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    value   => 'package_updates',
    notify  => Service['pe-puppetserver'],
  }
}
