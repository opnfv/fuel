#
# array_or_string_to_array.rb
#

module Puppet::Parser::Functions
  newfunction(:extras_to_hosts, :type => :rvalue, :doc => <<-EOS
              convert extras array passed from Astute into
              hash for puppet `host` create_resources call
    EOS
  ) do |args|
    hosts=Hash.new
    extras=args[0]
    extras.each do |extras|
      hosts[extras['name']]={:ip=>extras['address'],:host_aliases=>[extras['fqdn']]}
      notice("Generating extras host entry #{extras['name']} #{extras['address']} #{extras['fqdn']}")
    end
    return hosts
  end
end

# vim: set ts=2 sw=2 et :
