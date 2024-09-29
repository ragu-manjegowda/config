#!/usr/bin/env ruby

###############################################################################
##
## Author       : Ragu Manjegowda
## Github       : @ragu-manjegowda
##
###############################################################################

# -*- coding: utf-8 -*-

def main(zsh_history_file)
  # Check if the Zsh history file exists
  unless File.exist?(zsh_history_file)
    puts "File not found: #{zsh_history_file}"
    exit 1
  end

  # Read Zsh history
  File.foreach(zsh_history_file) do |line|
    # Match Zsh history format: : timestamp:duration; command
    if line =~ /^:\s*(\d+):\d+;\s*(.*)$/
      command = $2.strip

      # Output the command in Bash history format
      puts "#{command}"
    end
  end
end

if ARGV.empty?
  puts "Usage: ruby zsh-to-bash-hist.rb <path_to_zsh_history>"
else
  main(ARGV[0])
end

