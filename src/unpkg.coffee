# Description:
#   Get package's unpkg url of latest version
#   and will get the message of the new version when the packges is updated
#
# Configuration:
#   HUBOT_UNPKG_NOTICE_CHANNEL {String} [#general]
#   HUBOT_UNPKG_NOTICE_MESSAGE {String} - {0}: pakcage name, {1}: packageName@version
#   HUBOT_UNPKG_WATCH_INTERVAL {Number} [10 * 60 * 1000] - interval
#
# Commands:
#   unpkg package - will get package's unpkg url of latest version
#   unpkg package -v, --version - will get package version

https = require 'https'

url = 'https://unpkg.com'

channel = process.env.HUBOT_UNPKG_NOTICE_CHANNEL or '#general'
noticeMessage = process.env.HUBOT_UNPKG_NOTICE_MESSAGE or '{0} was updated {1}'
interval = parseInt(process.env.HUBOT_UNPKG_WATCH_INTERVAL or '6000000')

if interval <

String::format = ->
  args = arguments
  return @replace /\{(\d)\}/g, ->
    args[arguments[1]]

module.exports = (robot) ->
  pkgs = robot.brain.get 'pkgs'
  if pkgs is null
    pkgs = new Set
    robot.brain.set 'pkgs', pkgs

  watchIntervalId = setInterval =>
    watchPackages()
  , interval

  robot.hear /^unpkg (.*)$/i, (msg) ->
    pkgName = msg.match[1]
    return if /(-v|--version)$/i.test pkgName
    getVersion pkgName, (version) ->
      if version
        msg.send "#{url}#{version}"
      else
        msg.send "Not found #{pkgName}"

  robot.hear /^unpkg (.*) (-v|--version)$/i, (msg) ->
    pkgName = msg.match[1]
    getVersion pkgName, (version) ->
      if version
        msg.send version.substring 1
      else
        msg.send "Not found #{pkgName}"

  getVersion = (pkgName, cb) ->
    pkg = robot.brain.get pkgName
    if pkg
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
  https.get "#{url}/#{pkgName}", (res) ->
    if res.statusCode is 302
      cb res.headers.location
    else
      cb null
