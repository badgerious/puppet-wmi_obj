wmi_obj
=======

This puppet module can be used to create, delete, and modify WMI objects. 

Installation
-------------

Install from Puppet Forge:

    puppet module install badgerious/wmi_obj

Install from Github (do this in your modulepath):

    git clone https://github.com/badgerious/puppet-wmi_obj wmi_obj

Usage
-----

This module defines two types: `wmi_obj` and `wmi_class_purge`.

### `wmi_obj`

This type can be used to create, delete, and change the properties of WMI objects.
Uniqueness is determined by `namespace`, `wmiclass`, and some combination of `props`. Since 
the exact properties that determine uniqueness vary, these parameters are not flagged
as namevars; instead the uniqueness keys are determined dynamically based on namespace and class. 

#### Parameters

##### `ensure`

Standard ensure. 

##### `name`

A name for the resource. This does not set any useful properties, for reasons
explained above. 

##### `namespace`

WMI namespace, as would be provided to e.g. powershell's `Get-WmiObject -Namespace {namespace}`. 
This will be converted to all lowercase to simplify resource duplication detection.

##### `wmiclass`

This is the name of the WMI class, same as you would provide with e.g. powershell's `Get-WmiObject -Class {wmiclass}`.
There are various tools for exploring classes within a namespace (powershell, wbemtest.exe, CIM Studio, etc.). 
This will be converted to all lowercase to simplify resource duplication detection.

##### `props` 

This should be a hash of properties to set on the WMI object. WMI classes can mark
a subset of their properties as 'key' properties; these properties must be provided as
they are used to uniquely identify the object. 

If the WMI object has properties not specified in the hash, they will not be
managed, that is, they will be left unchanged for existing objects and will be
unset for new objects. 

Some WMI objects cannot be created without specifying certain properties even
though these properties are not marked as key properties; trying this will give
an OLE error on the puppet run. 

#### Example

```puppet

# This creates an instance of the '__EventFilter' class in the 'root\subscription' namespace. 
# This event will fire whenever a notepad.exe process is launched. 
wmi_obj { 'somename':
  ensure    => present,
  wmiclass  => '__EventFilter',
  namespace => 'root\subscription'
  props     => {
    'name' => '_puppet_guy',
    'eventnamespace' => 'root\cimv2',
    'query' => 'SELECT * FROM __InstanceCreationEvent WHERE TargetInstance ISA "Win32_Process" AND Name="notepad.exe"',
    'querylanguage' => 'WQL'
  },
}

```

### `wmi_class_purge`

Using the `resources` type to purge `wmi_obj` would be impractical, considering
the number of things in WMI. As an alternative, the `wmi_class_purge` type
allows purging of a specific class.

#### Parameters

##### `wmiclass` (namevar)

This will be set to the title of the resource if not explicitly provided. 
This parameter is the WMI class name, as in `wmi_obj`. 
This will be converted to all lowercase to simplify resource duplication detection.

##### `namespace` (namevar)

The namespace, same as in `wmi_obj`. 
This will be converted to all lowercase to simplify resource duplication detection.

##### `where`

An optional where clause to filter results. You can, for example, title all
puppet managed resources something like `_puppet_{somename}` and then apply a
where filter like `Name like "_puppet_%"` to purge only puppet created
resources. Objects not matching the where filter will be left alone. 

##### `postfilter`

This is similar to the where clause filter above. Certain properties, however,
cannot be filtered by WQL where clauses and so must be filtered after the
query has been performed. This parameter should be a hash, where keys are 
property names and values are Ruby stringified regular expressions (unfortunately
Puppet's regex syntax can be applied only in limited contexts, hence the need
for strings). For less than obvious cases (e.g. case insensitivity), craft
the regex in a Ruby prompt using `/slash/` notation and then call `#to_s` on the
regex to get the string. 

#### Example

```puppet

# This will remove all instances of '__EventFilter' whose name matches
# '_puppet_%'. 
wmi_class_purge { '__EventFilter':
  namespace => 'root\subscription',
  where     => 'Name like "_puppet_%"',
}

# This will remove all instances of '__FilterToConsumerBinding' that
# have a Filter property matching The provided regex. This type of
# filter cannot be performed with a 'where' filter (WMI doesn't allow it).
wmi_class_purge { '__FilterToConsumerBinding':
  namespace  => 'root\subscription',
  postfilter => {
    'Filter' => '(?i-mix:\.Name="_puppet_.*"$)'
  }
}

```

Compatibility
--------------

This module requires ruby 1.9+. It has been tested on 3.2.x and 3.4.x puppet master/agents. 
