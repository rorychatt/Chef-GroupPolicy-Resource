resource_name :group_policy

property :policy_name, Boolean, default: false
property :admx_path, String
property :configured, Boolean, default: false
property :enabled, Boolean default: false

extend MyResourceHelperFunctions

action_class do
  require 'rexml/document'
  include REXML

  def get_root(directory)
    doc = Document.new(File.new(directory))
    doc.root
  end

  def get_policy(root, policy_name)
    root.elements["policies/policy[@name='#{policy_name}']"]
  end

  def has_child(element, child_name)
    if element.elements[child_name]
      return true
    end
    false
  end

  def convert_key_value_type(element)
    if element.elements['decimal']
      if element.elements['decimal'].attributes['storeAsText'] == 'true'
        return { :converted_type => 'REG_SZ' , :value_type => 'decimal' }
      else
        return { :converted_type => 'REG_DWORD' , :value_type => 'decimal' }
      end
    elsif element.elements['string']
      return { :converted_type => 'REG_SZ' , :value_type => 'string' }
    elsif element.elements['delete']
      return { :converted_type => 'delete' , :value_type => 'delete' }
    end
    return 'ERROR: INVALID TYPE'
  end

  # Creates a base key if the ADMX defines a "enabledValue" or "disabledValue" element
  def manage_policy_key(key_class, policy, child_name)

    key_type = convert_key_value_type(policy.elements[child_name])
    values =  [{
                   :name => policy.attributes['valueName'],
                   :type => key_type[:converted_type],
                   :data => policy.elements["enabledValue/#{key_type[:value_type]}"].attributes['value']
               }]

    if key_type[:value_type] == 'delete'
      delete_policy_key_values(key_class, values, policy.attributes['key'])
    else
      create_policy_key_values(key_class, values, policy.attributes['key'])
    end

  end

  def parse_boolean_keys(key_class, policy, base_key_status)
    if policy.elements["#{base_key_status}Value"]
      manage_policy_key(key_class, policy, 'enabledValue') # EnabledValue Parser
    elsif policy.elements["#{base_key_status}List"]
      manage_list_keys(key_class, policy, 'enabledList')     # enabledList Parser
    end
  end

  def manage_list_keys(key_class, policy, list_type)
    (policy.elements[list_type]).each_element do |item|
      manage_policy_key(key_class, item, "value")
    end
  end


  def create_policy_key_values(key_class, values, key_path)

    # APPLIES, but Not useful in its current form
    # TODO: Give a way to specify a user type.
    if key_class == 'User' || key_class == 'Both'
      registry_key "HKEY_CURRENT_USER\\#{key_path}" do
        values values
        action :create
      end
    end

    # Applies Machine Group Policies
    if key_class == 'Machine' || key_class == 'Both'
      registry_key "HKEY_LOCAL_MACHINE\\#{key_path}" do
        values values
        action :create
      end
    end

  end

  # Delete Key values from Hive
  def delete_policy_key_values(key_class, values, key_path)

    # APPLIES, but Not useful in its current form
    # TODO: Give a way to specify a user type.
    if key_class == 'User' || key_class == 'Both'
      registry_key "HKEY_CURRENT_USER\\#{key_path}" do
        values values
        action :delete
      end
    end

    # Applies Machine Group Policies
    if key_class == 'Machine' || key_class == 'Both'
      registry_key "HKEY_LOCAL_MACHINE\\#{key_path}" do
        values values
        action :delete
      end
    end

  end

  # Delete Key from Hive
  def delete_policy_key(key_class, key_path)

    # APPLIES, but Not useful in its current form
    # TODO: Give a way to specify a user type.
    if key_class == 'User' || key_class == 'Both'
      registry_key "HKEY_CURRENT_USER\\#{key_path}" do
        action :delete_key
      end
    end

    # Applies Machine Group Policies
    if key_class == 'Machine' || key_class == 'Both'
      registry_key "HKEY_LOCAL_MACHINE\\#{key_path}" do
        action :delete_key
      end
    end

  end

  def key_value_type(policy, element)
    policy.elements[element]
  end
end


action :apply do
  if :configured
    'This Group Policy will be configured'
    "Enabled     : #{enabled}"
    "ADMX Path   : #{admx_path}"
    "Policy Name : #{policy_name}"

    # Is the path provided valid?
    root = get_root(:admx_path)
    if get_root(:admx_path)
      # Only apply if Configured = True. Configured = False won't undo existing configuration (like normal GP)
      if :configured

        policy = get_policy(root, policy_name)
        key_class = policy.attributes["class"]

        if :enabled
          parse_boolean_keys(key_class, policy, 'enabled')
          # Elements Parser

        else
          parse_boolean_keys(key_class, policy, 'disabled')
          # Elements Parser

        end
      end
    else
      "Invalid ADMX Path"
    end


  else
    'This Group Policy will not be configured'
    "Enabled     : #{enabled}"
    "ADMX Path   : #{admx_path}"
    "Policy Name : #{policy_name}"
  end
end
