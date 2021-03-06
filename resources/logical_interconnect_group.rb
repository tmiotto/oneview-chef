# (c) Copyright 2016 Hewlett Packard Enterprise Development LP
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.

OneviewCookbook::ResourceBaseProperties.load(self)

property :interconnects, Array, default: []
property :uplink_sets, Array, default: []

default_action :create

action_class do
  include OneviewCookbook::Helper
  include OneviewCookbook::ResourceBase

  def load_lig(item)
    interconnects.each do |location|
      parsed_location = convert_keys(location, :to_sym)
      item.add_interconnect(parsed_location[:bay], parsed_location[:type])
    end
    uplink_sets.each do |uplink_info|
      parsed_uplink_info = convert_keys(uplink_info, :to_sym)
      up = OneviewSDK::LIGUplinkSet.new(item.client, parsed_uplink_info[:data])
      parsed_uplink_info[:networks].each do |network_name|
        net = case up[:networkType]
              when 'Ethernet'
                OneviewSDK::EthernetNetwork.new(item.client, name: network_name)
              when 'FibreChannel'
                OneviewSDK::FCNetwork.new(item.client, name: network_name)
              else
                raise "Type #{up[:networkType]} not supported"
              end
        raise "#{up[:networkType]} #{network_name} not found" unless net.retrieve!
        up.add_network(net)
      end
      parsed_uplink_info[:connections].each { |link| up.add_uplink(link[:bay], link[:port]) }
      item.add_uplink_set(up)
    end
    item
  end
end

action :create do
  create_or_update(load_lig(load_resource))
end

action :create_if_missing do
  create_if_missing(load_lig(load_resource))
end

action :delete do
  delete
end
