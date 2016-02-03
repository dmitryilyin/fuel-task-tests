notify { 'globals' :}

file { '/etc/hiera/globals.yaml' :
  ensure  => 'present',
  content => 'globals content',
}
