def attr(name)
  attr = SDBM.open("#{topdir(name)}/attr",0644);
  @protected = (attr['protected'] == 'true' ? "checked" : "")
  @searchable = (attr['searchable'] == 'true' ? "checked" : "")

  @urlroot = URLROOT
  @srcroot = SRCROOT
  @name = name
  erb :attr
end
