module Task
  def self.debug(msg)
    puts msg if ENV['SPEC_PUPPET_DEBUG']
  end

  def self.hiera_data_yaml_files
    hiera_config.fetch(:hierarchy, []).map do |element|
      File.join astute_yaml_directory_path, "#{element}.yaml"
    end
  end

  def self.status_report_template
    <<-'eos'
<%= '=' * 80 %>
Node:     <%= fqdn or '?' %>
OS:       <%= current_os context %>
Role:     <%= role or '?' %>

YAML:     <%= astute_yaml_path %>
Spec:     <%= current_spec context %>
Manifest: <%= manifest_path %>
<% if ENV['SPEC_CATALOG_CHECK'] -%>
Catalog:  <%= catalog_dump_file_path context %>
<% end -%>

Hiera:
<% hiera_data_yaml_files.each do |element| -%>
* <%= element %>
<% end -%>
<%= '=' * 80 %>
    eos
  end

  def self.status_report(context)
    ERB.new(status_report_template, nil, '-').result(binding)
  end
end
