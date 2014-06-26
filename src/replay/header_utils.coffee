# Parse headers from header_lines.  Optional argument `only` is an array of
# regular expressions; only headers matching one of these expressions are
# parsed.  Returns a object with name/value pairs.
parseHeaders = exports.parse = (filename, header_lines, only = null)->
  headers = Object.create(null)
  for line in header_lines
    continue if line == ""
    [_, name, value] = line.match(/^(.*?)\:\s+(.*)$/)
    continue if only && !match(name, only)

    key = (name || "").toLowerCase()
    value = (value || "").trim().replace(/^"(.*)"$/, "$1")
    if Array.isArray(headers[key])
      headers[key].push value
    else if headers[key]
      headers[key] = [headers[key], value]
    else
      headers[key] = value
  return headers


# Write headers to the File object.  Optional argument `only` is an array of
# regular expressions; only headers matching one of these expressions are
# written.
writeHeaders = exports.write = (file, headers, only = null)->
  for name, value of pruneHeaders(headers, only)
    if Array.isArray(value)
      for item in value
        file.write "#{name}: #{item}\n"
    else
      file.write "#{name}: #{value}\n"

pruneHeaders = exports.prune = (headers, only = null)->
  prunedHeaders = {}
  prunedHeaders[name] = value for name, value of headers when !only or match(name, only)
  prunedHeaders

# Returns true if header name matches one of the regular expressions.
match = (name, regexps)->
  for regexp in regexps
    if regexp.test(name)
      return true
  return false