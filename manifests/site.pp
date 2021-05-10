class base {
  include epel
  package { 'java-11-openjdk-devel': }
  package { ['wget', 'unzip']: }

  yumrepo { 'elasticsearch-7.x':
    descr    => 'Elasticsearch repository for 7.x packages',
    baseurl  => 'https://artifacts.elastic.co/packages/oss-7.x/yum',
    gpgcheck => 1,
    gpgkey   => 'https://artifacts.elastic.co/GPG-KEY-elasticsearch',
    enabled  => 1,
  }

  yumrepo { 'opendistroforelasticsearch-artifacts-repo':
    descr    => 'Release RPM artifacts of OpenDistroForElasticsearch',
    baseurl  => 'https://d3g5vo6xdbdb9a.cloudfront.net/yum/noarch/',
    gpgcheck => 1,
    gpgkey   => 'https://d3g5vo6xdbdb9a.cloudfront.net/GPG-KEY-opendistroforelasticsearch',
    enabled  => 1,
  }

  $version = '1.13.2'
  package { 'elasticsearch':
    name => "opendistroforelasticsearch-${version}"
  }

  $instances = lookup('terraform.instances')
  $host_template = @(END)
127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
<% @instances.each do |key, values| -%>
<%= values['local_ip'] %> <%= key %> <% if values['tags'].include?('puppet') %>puppet<% end %>
<% end -%>
END

  file { '/etc/hosts':
    ensure  => file,
    content => inline_template($host_template)
  }

  $tags =  lookup("terraform.instances.${::hostname}.tags")
  $cluster_name = lookup('terraform.data.cluster_name')
  $is_master = 'master' in $tags
  $is_data = 'data' in $tags
  $is_ingest = 'ingest' in $tags
  $master_ips = lookup("terraform.tag_ip.master")

  file { '/etc/elasticsearch/elasticsearch.yml':
    owner   => 'root',
    group   => 'elasticsearch',
    content => @("END"),
cluster.name: ${cluster_name}
node.name: ${hostname}
node.master: ${is_master}
node.data: ${is_data}
node.ingest: ${is_ingest}
network.host: ${::ipaddress}
discovery.seed_hosts: ${master_ips}
path.logs: /var/log/elasticsearch
opendistro_security.disabled: true
END
    mode    => '0660',
    require => Package['elasticsearch']
  }

  service { 'elasticsearch':
    ensure => running,
    enable => true,
    subscribe => [
      File['/etc/elasticsearch/elasticsearch.yml'],
    ]
  }
}

node default {
  include base
}

