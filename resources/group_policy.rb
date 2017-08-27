resource_name :group_policy

property :policy_name, Boolean, default: FALSE
property :admx_path, String
property :configured, Boolean, default: FALSE
property :enabled, Boolean default: FALSE

include GroupPolicy::Parser

action :apply do
  if :configured
    'This Group Policy will be configured'
    "Enabled     : #{enabled}"
    "ADMX Path   : #{admx_path}"
    "Policy Name : #{admx_path}"

    root = get_root(:admx_path)

    if get_root(:admx_path)
      if :enabled
        if
      elsif :disabled

      end
    else
      "Invalid ADMX Path"
    end


  else
    'This Group Policy will not be configured'
    "Enabled     : #{enabled}"
    "ADMX Path   : #{admx_path}"
    "Policy Name : #{admx_path}"
  end
end
