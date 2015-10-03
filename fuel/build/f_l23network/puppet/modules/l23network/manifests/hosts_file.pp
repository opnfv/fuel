class l23network::hosts_file (
  $nodes,
  $extras=[],
  $hosts_file = "/etc/hosts"
) {

  # OPNFV addition: Add additional lines in /etc/hosts through Astute additions

  $host_resources = nodes_to_hosts($nodes)
  $extras_host_resources = extras_to_hosts($extras)
  Host {
    ensure => present,
    target => $hosts_file
  }

  create_resources(host, $host_resources)
  create_resources(host, $extras_host_resources)
}
