require 'rexml/document'
include REXML

# Convert key type from ADMX to Registry Key Type


doc = Document.new(File.new('../spec/unit/recipes/policies/access16.admx'))
root = doc.root
policy = root.elements["policies/policy[@name='L_ConfigureCNGCipherChainingMode']"]

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
                 :data => policy.elements["#{child_name}/#{key_type[:value_type]}"].attributes['value']
             }]

  print(values)

end

def manage_list_keys(key_class, policy, list_type)
  (policy.elements[list_type]).each_element do |item|
    manage_policy_key(key_class, item, "value")
  end
end

def parse_boolean_keys(key_class, policy, base_key_status)
  if policy.elements["#{base_key_status}Value"]
    manage_policy_key(key_class, policy, 'enabledValue') # EnabledValue Parser
  elsif policy.elements["#{base_key_status}List"]
    manage_list_keys(key_class, policy, 'enabledList')     # enabledList Parser
  end
end

def parse_element_keys(key_class, policy, base_key_status)
  (policy.elements['elements']).each_element do |element|
    case element.name
      when "enum"
        print "enum"
      when "boolean"
        parse_boolean_keys(key_class, policy, base_key_status)
      when "decimal"
        print "boolean"
      when "text"
        print "boolean"
      when "list"
        print "boolean"
    end
  end
end

manage_element_keys("Both", policy)