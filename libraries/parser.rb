
module GroupPolicy
  module Parser
    require 'rexml/document'
    include REXML

    def get_root(directory)
      doc = Document.new(File.new(directory))
      doc.root
    end

    def get_policy(root, policy_name)
        root.elements["policies/policy[@name='#{policy_name}']"]
    end

    def has_elements(policy, element)
      if policy.elements[element]
        return true
      end
      false
    end


  end
end

include GroupPolicy::Parser
root = get_root('../spec/unit/recipes/policies/access16.admx')
print(has_elements(get_policy(root, 'L_Defaultdirection'),'elements'))