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

property :storage_system, String
property :storage_pool, String
property :snapshot_pool, String

default_action :create

action_class do
  include OneviewCookbook::Helper
  include OneviewCookbook::ResourceBase

  # Loads the VolumeTemplate with all the external resources (if needed)
  # @return [OneviewSDK::VolumeTemplate] Loaded VolumeTemplate resource
  def load_resource_with_associated_resources
    item = load_resource
    raise "Unspecified property: 'storage_system'. Please set it before attempting this action." unless storage_system
    raise "Unspecified property: 'storage_pool'. Please set it before attempting this action." unless storage_pool
    item['provisioning']['capacity'] = item['provisioning']['capacity'].to_s if item['provisioning'] && item['provisioning']['capacity']
    item = load_storage_system(item)

    # item.set_storage_pool(OneviewSDK::StoragePool.new(item.client, name: storage_pool)) if storage_pool
    # Ruby SDK issue workaround:
    sp = OneviewSDK::StoragePool.find_by(item.client, name: storage_pool, storageSystemUri: item['storageSystemUri']).first
    raise "Storage Pool '#{storage_pool}' not found for Storage System '#{storage_system}'" unless sp
    item['provisioning']['storagePoolUri'] = sp['uri']

    item.set_snapshot_pool(OneviewSDK::StoragePool.new(item.client, name: snapshot_pool)) if snapshot_pool
    item
  end

  # Loads Storage System in the given VolumeTemplate resource.
  # The property storage_system needs to be used in the recipe for this code to load the Storage System.
  # Hostname or storage system name can be used
  # @param [OneviewSDK::VolumeTemplate] item VolumeTemplate to add the Storage System
  # @return [OneviewSDK::VolumeTemplate] VolumeTemplate with Storage System parameters updated
  def load_storage_system(item)
    storage_system_resource = OneviewSDK::StorageSystem.new(item.client, credentials: { ip_hostname: storage_system })
    unless storage_system_resource.exists?
      storage_system_resource = OneviewSDK::StorageSystem.new(item.client, name: storage_system)
    end
    raise "Storage system '#{storage_system}' not found" unless storage_system_resource.retrieve!
    item.set_storage_system(storage_system_resource)
    item
  end
end

action :create do
  create_or_update(load_resource_with_associated_resources)
end

action :create_if_missing do
  create_if_missing(load_resource_with_associated_resources)
end

action :delete do
  delete
end
