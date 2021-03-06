#
# Cookbook Name:: slurm
# Recipe:: _debian
#
# Copyright 2015, Jonathan Klinginsmith
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

slurm_hash = node['slurm']

slurm_sysconfdir = slurm_hash.fetch('sysconfdir', '/etc/slurm-llnl')

slurm_control_machine = slurm_hash['control_machine']
slurm_control_addr = slurm_hash['control_addr']

slurm_user = slurm_hash['user']
slurm_group = slurm_hash['group']

slurm_node_list = slurm_hash['node_list']

packages = %w(slurm-llnl munge)
packages.each do |pkg|
  package pkg do
    action :install
  end
end

# TODO: Determine how we want to create the munge.key file.
cookbook_file '/etc/munge/munge.key' do
  source 'munge.key'
  mode '0400'
  owner 'munge'
  group 'munge'
end

## TODO: Determine how we want to populate NodeName values.
# Create the slurm.conf file.
template "#{File.join(slurm_sysconfdir, 'slurm.conf')}" do
  source 'slurm.conf.erb'
  mode '0644'
  variables(
    control_machine: slurm_control_machine,
    control_addr: slurm_control_addr,
    node_list: slurm_node_list)
end

# Make sure the /var/log directory has the sticky bit set
directory '/var/log' do
  owner 'root'
  group 'syslog'
  mode 01755
  action :create
end

# Create the log directory. This is found in the slurm.conf file.
directory '/var/log/slurm' do
  owner slurm_user
  group slurm_group
  mode 00755
  action :create
end

services = %w(munge slurm-llnl)
services.each do |srvc|
  service srvc do
    action [:enable, :start]
  end
end
