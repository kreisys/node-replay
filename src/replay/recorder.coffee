passThrough = require("./pass_through")

cleanHeaders = (headers, only = null)->
  cleanedHeaders = {}
  cleanedHeaders[name] = value for name, value of headers when !only or match(name, only)
  cleanedHeaders

# Returns true if header name matches one of the regular expressions.
match = (name, regexps)->
  for regexp in regexps
    if regexp.test(name)
      return true
  return false

recorded = (settings)->
  catalog = settings.catalog
  capture = passThrough(true)
  return (request, callback)->
    request.headers = cleanHeaders(request.headers, settings.headers)

    host = request.url.hostname
    if request.url.port && request.url.port != "80"
      host += ":#{request.url.port}"
    # Look for a matching response and replay it.
    matchers = catalog.find(host)
    if matchers
      for matcher in matchers
        response = matcher(request)
        if response
          callback null, response
          return

    # Do not record this host.
    if settings.isIgnored(request.url.hostname)
      callback null
      return

    # In recording mode capture the response and store it.
    if settings.mode == "record"
      capture request, (error, response)->
        return callback error if error
        catalog.save host, request, response, (error)->
          callback error, response
      return
   
    # Not in recording mode, pass control to the next proxy.
    callback null

module.exports = recorded
