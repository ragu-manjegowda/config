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

MULTILINE_COMMAND = "TO_BE_REMOVED_#{Time.now.to_i}"

commands = Hash.new([0,0])
seen_commands = Set.new

ARGV.sort.each do |hist|
  $stderr.puts "Parsing '#{hist}'"

  # Read the file in binary mode and handle encoding issues
  content = File.open(hist, "rb") do |file|
    file.read.encode("ASCII", "UTF-8", invalid: :replace, undef: :replace, replace: '\\\\x%02x')
  end

  content = File.read(hist).gsub(/\\\n(?!:\s*\d{10,})/, MULTILINE_COMMAND)
  should_be_empty = content.each_line.grep_v(/^:/) + content.each_line.grep(/(?<!^): \d{10,}/)
  raise "Problem with those lines : #{should_be_empty}" unless should_be_empty.empty?
  content.each_line do |line|
    description, command = line.split(';', 2)
    _, time, duration = description.split(':').map(&:to_i)

    # Check if the command has already been processed
    next if seen_commands.include?(command)
    seen_commands.add(command)

    old_time, _old_duration = commands[command]
    if time > old_time
      commands[command] = [time, duration]
    end
  end
end

commands.sort_by{|_, time_duration| time_duration}.each{|command, (time, duration)|
  puts ':%11d:%d;%s' % [time, duration, command.gsub(MULTILINE_COMMAND, "\\\n")]
}
