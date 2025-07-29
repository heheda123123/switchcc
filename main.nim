import os, strutils, algorithm
from strutils import split, startsWith, endsWith, contains, toLowerAscii
from os import getHomeDir, joinPath, dirExists, fileExists, walkFiles, copyFile, removeFile
from algorithm import sorted

type
  ConfigFile = object
    filename: string
    suffix: string
    path: string

proc getClaudeDir(): string =
  joinPath(getHomeDir(), ".claude")

proc scanConfigFiles(): seq[ConfigFile] =
  let claudeDir = getClaudeDir()
  if not dirExists(claudeDir):
    return @[]
  
  var configs: seq[ConfigFile] = @[]
  for filepath in walkFiles(joinPath(claudeDir, "settings.json.*")):
    let filename = extractFilename(filepath)
    if filename.startsWith("settings.json.") and not filename.endsWith(".backup"):
      let suffix = filename[14..^1]  # Remove "settings.json." prefix
      configs.add(ConfigFile(
        filename: filename,
        suffix: suffix,
        path: filepath
      ))
  
  return configs

proc calculateMatchScore(target: string, candidate: string): int =
  let targetLower = target.toLowerAscii()
  let candidateLower = candidate.toLowerAscii()
  
  # Exact match gets highest score
  if targetLower == candidateLower:
    return 1000
  
  # Prefix match gets high score
  if candidateLower.startsWith(targetLower):
    return 500 + (100 - candidate.len)
  
  # Contains match gets medium score
  if candidateLower.contains(targetLower):
    return 200 + (100 - candidate.len)
  
  # No match
  return 0

proc findBestMatch(configs: seq[ConfigFile], targetSuffix: string): ConfigFile =
  if configs.len == 0:
    raise newException(ValueError, "No configuration files found")
  
  var bestConfig = configs[0]
  var bestScore = calculateMatchScore(targetSuffix, bestConfig.suffix)
  
  for config in configs[1..^1]:
    let score = calculateMatchScore(targetSuffix, config.suffix)
    if score > bestScore:
      bestScore = score
      bestConfig = config
  
  if bestScore == 0:
    raise newException(ValueError, "No matching configuration found for: " & targetSuffix)
  
  return bestConfig

proc switchConfig(targetConfig: ConfigFile) =
  let claudeDir = getClaudeDir()
  let currentSettingsPath = joinPath(claudeDir, "settings.json")
  let backupPath = joinPath(claudeDir, "settings.json.backup")
  
  # Backup current settings.json if it exists
  if fileExists(currentSettingsPath):
    copyFile(currentSettingsPath, backupPath)
    echo "Backed up current settings to settings.json.backup"
  
  # Copy target config to settings.json
  copyFile(targetConfig.path, currentSettingsPath)
  echo "Switched to configuration: " & targetConfig.suffix

proc listConfigs(configs: seq[ConfigFile]) =
  echo "Available configurations:"
  for config in configs.sorted(proc(a, b: ConfigFile): int = cmp(a.suffix, b.suffix)):
    echo "  " & config.suffix

proc main() =
  let args = commandLineParams()
  
  if args.len == 0:
    let configs = scanConfigFiles()
    if configs.len == 0:
      echo "No configuration files found in ~/.claude/"
      echo "Expected format: settings.json.<suffix>"
      quit(1)
    listConfigs(configs)
    quit(0)
  
  if args.len != 1:
    echo "Usage: scc <suffix>"
    echo "       scc           (list all configurations)"
    quit(1)
  
  let targetSuffix = args[0]
  
  try:
    let configs = scanConfigFiles()
    let bestMatch = findBestMatch(configs, targetSuffix)
    switchConfig(bestMatch)
  except ValueError as e:
    echo "Error: " & e.msg
    quit(1)
  except OSError as e:
    echo "File operation error: " & e.msg
    quit(1)
  except Exception as e:
    echo "Unexpected error: " & e.msg
    quit(1)

when isMainModule:
  main()
