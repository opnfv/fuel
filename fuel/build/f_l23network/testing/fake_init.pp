$fuel_settings = parseyaml($astute_settings_yaml)

if $::fuel_settings['nodes'] {
  $nodes_hash = $::fuel_settings['nodes']
  $extras_hash = $::fuel_settings['opnfv']['hosts']

  class {'l23network::hosts_file':
    nodes  => $nodes_hash,
    extras => $extras_hash
  }

  include l23network::hosts_file
}
