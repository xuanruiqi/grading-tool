#!/usr/bin/env ruby
require_relative 'processing'

if $PROGRAM_NAME == __FILE__ then
  if ARGV.length < 1 then
    puts "Usage: report [path to folder containing grading files]"
    exit 0
  end

  assgn = load_assignment(ARGV[0])
  assgn.full_report
end
