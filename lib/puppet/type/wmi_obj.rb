require 'win32ole' if Puppet.features.microsoft_windows?

Puppet::Type.newtype(:wmi_obj) do
  @keyprops = {}

  def self.keyprops(namespace, wmiclass)
    wmiclass = wmiclass.downcase.intern
    namespace = namespace.downcase.intern
    @keyprops[namespace] = {} unless @keyprops[namespace]
    unless @keyprops[namespace][wmiclass]
      klass = WIN32OLE.connect("winmgmts://./#{namespace}:#{wmiclass}")
      @keyprops[namespace][wmiclass] = klass.Properties_.each.select do |p|
        p.Qualifiers_.each.any? { |q| q.Name == 'key' && q.Value = true }
      end.map { |p| p.Name.downcase }.sort
    end
    @keyprops[namespace][wmiclass]
  end

  ensurable

  newparam(:name)
  newparam(:wmiclass) do
    munge { |val| val.downcase }
  end
  newparam(:namespace) do
    munge { |val| val.downcase }
  end
  newproperty(:props) do
    validate do |val|
      val.class == Hash or fail("'props' must be a hash")
    end
    munge do |val|
      newhash = {}
      val.each { |k,v| newhash[k.downcase] = v }
      newhash
    end
  end

  validate do
    fail "Missing required parameter 'namespace'" if self[:namespace].nil?
    fail "Missing required parameter 'wmiclass'" if self[:wmiclass].nil?
    fail "Missing required parameter 'props'" if self[:props].nil?

    keys = self[:props].map { |k,v| k.downcase }
    self.class.keyprops(self[:namespace], self[:wmiclass]).each do |keyprop|
      keys.include?(keyprop) or fail "Missing key property '#{keyprop}' for WMI class '#{self[:wmiclass]}'"
    end

    if catalog
      # namevars can't be used to prevent duplicate resources because the key properties
      # change based on the WMI class. So instead, we'll create an alias here
      # that includes all key properties for the given class plus class and namespace, which
      # together uniquely identify the WMI object.
      keyvals = self.class.keyprops(self[:namespace], self[:wmiclass]).map { |p| self[:props][p].downcase }
      catalog.alias(self, [self[:namespace], self[:wmiclass], *keyvals])
    end
  end
end
