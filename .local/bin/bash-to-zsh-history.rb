#!/usr/bin/env ruby

###############################################################################
##
## Author       : Ragu Manjegowda
## Github       : @ragu-manjegowda
## Reference    : https://gist.github.com/muendelezaji/c14722ab66b505a49861b8a74e52b274
##
###############################################################################

# This is how you would use it:
# $ ruby bash-to-zsh-hist.rb ~/.bash_history >> ~/.zsh_history

require 'time'

def main(bash_history_file)
  timestamp = nil
  unique_commands = Set.new

  # Read the file in binary mode to avoid Unicode errors
  lines = []
  File.open(bash_history_file, "rb") do |f|
    f.each_line do |line|
      lines << line.encode("ASCII", "UTF-8", invalid: :replace, undef: :replace, replace: '\\\\x%02x')
    end
  end

  lines.each do |line|
    line = line.chomp.strip  # Remove trailing spaces

    next if line.empty?  # Skip empty lines
    next if unique_commands.include?(line)  # Skip duplicates

    unique_commands.add(line)

    if line.start_with?('#') && timestamp.nil?
      t = line[1..-1]
      if t.match?(/^\d+$/)
        timestamp = t
        next
      end
    else
      puts ": #{timestamp || Time.now.to_i}:0;#{line}"
      timestamp = nil
    end
  end
end

if ARGV.empty?
  puts "Usage: ruby bash-to-zsh-hist.rb <path_to_bash_history>"
else
  main(ARGV[0])
end
