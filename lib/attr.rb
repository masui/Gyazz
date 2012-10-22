def attr(name)
  attr = SDBM.open("#{topdir(name)}/attr",0644);
  @sortbydate = (attr['sortbydate'] == 'true' ? "checked" : "")
  @searchable = (attr['searchable'] == 'true' ? "checked" : "")

  @urlroot = app_root
  @name = name
  erb :attr
end
