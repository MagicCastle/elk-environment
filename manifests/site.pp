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
  package { "opendistroforelasticsearch-${version}": }

  $instances = lookup('terraform.instances')
  $host_template = @(END)
127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
<% @instances.each do |key, values| -%>
<%= values['local_ip'] %> <%= key %> <% if values['tags'].include?('puppet') %>puppet<% end %>
<% end -%>
END

}

node default {
  include base
}

