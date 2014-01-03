require 'win32ole' if Puppet.features.microsoft_windows?

Puppet::Type.type(:wmi_obj).provide(:wmi_obj) do
  def exists?
    whereclause = self.class.resource_type.keyprops(@resource[:namespace], @resource[:wmiclass]).map do |prop|
      "#{prop}='#{@resource[:props][prop]}'"
    end.join(" AND ")

    wmi = WIN32OLE.connect("winmgmts://./#{@resource[:namespace]}")
    @obj = wmi.ExecQuery("SELECT * FROM #{@resource[:wmiclass]} WHERE #{whereclause}").each.first
    ! @obj.nil?
  end

  def set_props(obj, newprops)
    newprops.each do |prop, val|
      obj.send("#{prop}=", val)
    end
  end

  def create
    klass = WIN32OLE.connect("winmgmts://./#{@resource[:namespace]}:#{@resource[:wmiclass]}")
    obj = klass.SpawnInstance_
    set_props(obj, @resource[:props])
    obj.Put_
  end

  def destroy
    @obj.Delete_
  end

  def props
    current_props = {}
    @resource[:props].each_key do |prop|
      current_props[prop] = @obj.send(prop)
    end
    current_props
  end

  def props=(newprops)
    set_props(@obj, newprops)
    @obj.Put_
  end
end
