require 'win32ole' if Puppet.features.microsoft_windows?

Puppet::Type.newtype(:wmi_class_purge) do
  def self.title_patterns
    [[/^(.*)$/, [[:wmiclass, proc{|x| x}]]]]
  end

  newparam(:wmiclass) do
    isnamevar
    munge { |val | val.downcase }
  end
  newparam(:namespace) do
    isnamevar
    munge { |val| val.downcase }
  end
  newparam(:where) do
    defaultto(:undef)
  end
  newparam(:postfilter) do
    defaultto(:undef)
    validate do |val|
      case val
      when :undef, Hash
      else
        fail "'postfilter' must be a hash"
      end
    end
    munge do |hash|
      if hash == :undef
        :undef
      else
        hash.each { |prop, val| hash[prop] = Regexp.new(val) }
      end
    end
  end

  self::PURGE_CLASS = Puppet::Type.type(:wmi_obj)

  def generate
    keyprops = self.class::PURGE_CLASS.keyprops(self[:namespace], self[:wmiclass])

    wmi = WIN32OLE.connect("winmgmts://./#{self[:namespace]}")
    query = "SELECT * FROM #{self[:wmiclass]}"
    if self[:where] != :undef
      query += " WHERE #{self[:where]}"
    end
    instances = wmi.ExecQuery(query).each.to_a
    if self[:postfilter] != :undef
      instances.select! do |obj|
        self[:postfilter].all? { |prop, val| val === obj.send(prop) }
      end
    end
    instances.map! do |obj|
      hash = {}
      keyprops.map { |prop| hash[prop] =  obj.send(prop) }
      hash
    end

    resources = catalog.resources.select do |r| 
      r.class == self.class::PURGE_CLASS && r[:namespace] == self[:namespace] && r[:wmiclass] == self[:wmiclass]
    end.map do |r|
      hash = {}
      keyprops.map { |prop| hash[prop] = r[:props][prop] }
      hash
    end

    (instances - resources).map do |props|
      r = self.class::PURGE_CLASS.new(title: props.map { |k,v| "#{k}=#{v}" }.join(':'),
                                      namespace: self[:namespace], 
                                      wmiclass: self[:wmiclass], 
                                      props: props,
                                      ensure: :absent)
      r.purging
      r
    end
  end
end
