#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'processing'

if $PROGRAM_NAME == __FILE__
  if ARGV.empty?
    puts 'Usage: report [path to folder containing grading files]'
    exit 0
  end

  assgn = load_assignment(ARGV[0])
  assgn.full_report
end
