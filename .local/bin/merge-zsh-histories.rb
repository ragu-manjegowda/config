#!/usr/bin/env ruby

###############################################################################
##
## Reference    : https://unix.stackexchange.com/a/632345
## Modified by  : Ragu Manjegowda
## Github       : @ragu-manjegowda
##
###############################################################################

# Ruby script to merge zsh histories. In case of duplicates, it removes the old timestamps.
# It should do fine with multi-line commands.
# Make backups of your backups before running this script!
#
# ./merge_zsh_histories.rb zsh_history_*.bak ~/.zsh_history > merged_zsh_history
#
# source - https://unix.stackexchange.com/a/632345
#

require "optparse"

MULTILINE_COMMAND = "TO_BE_REMOVED_#{Time.now.to_i}"

options = OptionParser.new do |parser|
  parser.banner = <<~USAGE
    Usage: #{File.basename($PROGRAM_NAME)} [OPTIONS] ZSH_HISTORY...

    Merge one or more zsh extended history files, remove duplicate commands,
    and keep the newest timestamp for each duplicate command.

    Output is written to stdout, so redirect it to a new file:
      #{File.basename($PROGRAM_NAME)} zsh_history_*.bak ~/.zsh_history > merged_zsh_history
  USAGE

  parser.on("-h", "--help", "Show this help message") do
    puts parser
    exit
  end
end

options.parse!

if ARGV.empty?
  warn options
  exit 1
end

commands = Hash.new([0, 0])

ARGV.sort.each do |hist|
  warn "Parsing '#{hist}'"

  # Read the file in binary mode and handle encoding issues
  content = File.open(hist, "rb") do |file|
    file.read.encode("ASCII", "UTF-8", invalid: :replace, undef: :replace, replace: '\\\\x%02x')
  end

  content = content.gsub(/\\\n(?!:\s*\d{10,})/, MULTILINE_COMMAND)

  should_be_empty = content.each_line.grep_v(/^:/) + content.each_line.grep(/(?<!^): \d{10,}/)
  raise "Problem with those lines : #{should_be_empty}" unless should_be_empty.empty?
  content.each_line do |line|
    description, command = line.split(";", 2)
    _, time, duration = description.split(":").map(&:to_i)

    old_time, _old_duration = commands[command]
    if time > old_time
      commands[command] = [time, duration]
    end
  end
end

commands.sort_by { |_, time_duration| time_duration }.each { |command, (time, duration)|
  puts ":%11d:%d;%s" % [time, duration, command.gsub(MULTILINE_COMMAND, "\\\n")]
}
