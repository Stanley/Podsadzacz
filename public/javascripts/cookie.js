function Cookie(){

}

Cookie.get = function(name) {
  var theCookie = "" + document.cookie
  var ind = theCookie.indexOf(name)
  if (ind == -1 || name == "")
    return('')

  var ind1 = theCookie.indexOf(';', ind)
  if (ind1 == -1)
    ind1=theCookie.length

  return decodeURI(theCookie.substring(ind + name.length+1, ind1))
}

Cookie.set = function(name, value, nDays) {
  var today = new Date()
  var expire = new Date()
  if(nDays == null || nDays == 0) nDays = 1

  expire.setTime(today.getTime() + 3600000*24*nDays)
  document.cookie = name + "=" + encodeURI(value)
                  + ";expires=" + expire.toGMTString()
}