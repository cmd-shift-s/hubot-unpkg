# Description:
#   Get package's unpkg url of latest version
#   and will get the message of the new version when the packges is updated
#
# Configuration:
#   HUBOT_UNPKG_NOTICE_CHANNEL {String} [#general]
#   HUBOT_UNPKG_NOTICE_MESSAGE {String} - {0}: pakcage name, {1}: packageName@version
#   HUBOT_UNPKG_WATCH_INTERVAL {Number} [0] - interval, 0: disable
#   HUBOT_UNPKG_WATCH_LIST {String} - watch default package list
#                                     ex) vue,vuex,vue-router
#
# Commands:
#   unpkg package - get package's unpkg url of latest version
#   unpkg -l, --list - return searched all packages
#   unpkg package -v, --version - get package version
#   unpkg all -v, --version - get all watching packages version

url = 'https://unpkg.com'

channel = process.env.HUBOT_UNPKG_NOTICE_CHANNEL or '#general'
noticeMessage = process.env.HUBOT_UNPKG_NOTICE_MESSAGE or '{0} was updated : {1}'
interval = parseInt(process.env.HUBOT_UNPKG_WATCH_INTERVAL or '0')

String::format = ->
  args = arguments
  return @replace /\{(\d)\}/g, ->
    args[arguments[1]]

module.exports = (robot) ->
  pkgs = robot.brain.get 'pkgs'
  if pkgs is null
    pkgs = new Set
    robot.brain.set 'pkgs', pkgs

  # add default packages
  watchlist = process.env.HUBOT_UNPKG_WATCH_LIST or null
  if watchlist isnt null
    list = watchlist.split /[,\s]+/
    for i of list
      pkgs.add list[i]
    process.nextTick ->
      watchPackages()

  # watching setInterval
  if interval
    watchIntervalId = setInterval =>
      watchPackages()
    , interval

  robot.hear /^unpkg (.*)$/i, (msg) ->
    pkgName = msg.match[1]
    return if /(-v|--version)$/i.test(pkgName) or /(-l|--list)$/i.test(pkgName)
    getVersion pkgName, (version) ->
      if version
        msg.send "#{url}#{version}"
      else
        msg.send "Not found #{pkgName}"

  robot.hear /^unpkg (-l|--list)$/i, (msg) ->
    msg.send 'list: ' + Array.from(pkgs).join ', '

  robot.hear /^unpkg (.*) (-v|--version)$/i, (msg) ->
    pkgName = msg.match[1]
    if /^all$/i.test pkgName
      pkgs.forEach (pkg) ->
        getVersion pkg, (version) ->
          msg.send version.substring 1
    else
      getVersion pkgName, (version) ->
        if version
          msg.send version.substring 1
        else
          msg.send "Not found #{pkgName}"

  getVersion = (pkgName, cb) ->
    pkg = robot.brain.get pkgName
    if pkg and interval isnt 0
      cb pkg
    else
      getUrl pkgName, (version) ->
        if version
          if !pkgs.has pkgName
            pkgs.add pkgName
            robot.brain.set 'pkgs', pkgs
          robot.brain.set pkgName, version
          cb version
        else
          cb null

  watchPackages = ->
    pkgs.forEach (pkgName) ->
      getUrl pkgName, (version) ->
        if robot.brain.get(pkgName) isnt version
          if robot.brain.get(pkgName) isnt null
            robot.messageRoom channel, noticeMessage.format pkgName, version.substring 1
          robot.brain.set pkgName, version

  getUrl = (pkgName, cb) ->
    robot.http("#{url}/#{pkgName}").get() (err, res) ->
      if res.statusCode is 302
        cb res.headers.location
      else
        cb null
