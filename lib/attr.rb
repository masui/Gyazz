def attr(name)
  attr = SDBM.open("#{Gyazz.topdir(name)}/attr",0644);
  @sortbydate = (attr['sortbydate'] == 'true' ? "checked" : "")
  @searchable = (attr['searchable'] == 'true' ? "checked" : "")

  @name = name
  erb :attr
end
