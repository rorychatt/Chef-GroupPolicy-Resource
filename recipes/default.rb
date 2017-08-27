#
# Cookbook:: Chef-GroupPolicy-Resource
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

group_policy "Configured" do
  action :apply
  policy_name "mypolicy"
  admx_path "Path/To/Policy"
  configured TRUE
  enabled TRUE
end

group_policy "Not_Configured" do
  action :apply
  policy_name "Not Configured"
  admx_path "Path/To/Policy"
  configured FALSE
  enabled FALSE
end