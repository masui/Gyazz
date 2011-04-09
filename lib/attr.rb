def attr(name)
  @urlroot = URLROOT
  @srcroot = SRCROOT
  @name = name
  erb :attr
end
