### v1.0.2
- Change perms on metadata.json, which seems not to be handled by puppet module tool correctly

### v1.0.1
- Remove some lingering ruby 1.9 syntax
- Fix (possibly inconsequential) typo 

v1.0.0
======
- Removed need for ruby 1.9+
- `wmi_class_purge` uses all key properties in the `title` field to help avoid name collisions
