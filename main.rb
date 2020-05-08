#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'highline'
require_relative 'processing'
require_relative 'email'

def find_course_config
  # first search in local directory
  filename = ''

  if File.file? 'course.yaml'
    filename = 'course.yaml'
  elsif File.file? File.join(Dir.home, 'course.yaml')
    filename = File.join(Dir.home, 'course.yaml')
  elsif File.file? File.join(Dir.home, '.config', 'course.yaml')
    filename = File.join(Dir.home, '.config', 'course.yaml')
  end

  filename
end

def prompt_smtp(cli)
  smtp_conf = {}

  smtp_conf[:address] = cli.ask 'SMTP server address: '
  smtp_conf[:port] = cli.ask('SMTP port: ', Integer)
  smtp_conf[:user_name] = cli.ask 'SMTP username: '

  # only support PLAIN, which should be good for most people (maybe not outlook)

  auth_req = cli.ask('Authentication (login) required? (y/n) ') { |a| a.validate = /y|n/ }

  if auth_req == 'y'
    smtp_conf[:authentication] = 'plain'
    smtp_conf[:enable_starttls_auto] = (cli.ask('STARTTLS? (y/n) ') { |a| a.validate = /y|n/ }) == yes
    smtp_conf[:tls] = (cli.ask('TLS on a dedicated port? (y/n) ') { |a| a.validate = /y|n/ }) == yes
  else
    smtp_conf[:authentication] = nil
  end

  smtp_conf
end

if $PROGRAM_NAME == __FILE__
  if ARGV.empty?
    puts 'Usage: send [path to folder containing grading files] [-v]'
    puts 'Use -v only if you want a full report, showing the score of each student.'
    puts 'All other command line options are ignored.'
    exit 0
  end

  assgn = load_assignment(ARGV[0])
  if ARGV.length < 2 || ARGV[1] != '-v'
    assgn.report
  else
    assgn.full_report
    # print_all_emails_text assgn
  end

  puts "\nPreparing emails..."

  course_title = ''
  sender_email = ''
  cc_email = ''
  smtp_conf = nil

  course_config_path = find_course_config
  if course_config_path != ''
    conf = File.open(course_config_path, 'r') { |f| YAML.safe_load f }
    course_title = conf['course_name']
    sender_email = conf['send_email']
    cc_email = conf['cc'].join(', ')
    smtp_conf = conf['smtp'].transform_keys(&:to_sym)
  end
  # If any of the above fields is null, ask for course title, sender email, etc., interactively

  cli = HighLine.new
  
  course_title = 'Title of the course: ' if course_title == ''
  sender_email = cli.ask 'Your email address: ' if sender_email == ''

  if cc_email == ''
    cc_list = []

    loop do
      cc_new = cli.ask 'Any more email addresses to cc? Enter one at a time. ' \
                       'If none, just press enter: '
      break if cc_new == ''
    end

    cc_email = cc_list.join(', ')
  end

  emails = gen_all_emails(course_title, assgn, sender_email, cc_email)
  save_all_emails(ARGV[0], emails) unless ARGV.length < 2 || ARGV[1] != '-v'

  # if there's no SMTP config then interactively create one
  smtp_conf = prompt_smtp cli if smtp_conf.nil?

  unless smtp_conf[:authentication].nil?
    cli = HighLine.new
    password = cli.ask('Password for sending email: ') { |q| q.echo = false }
    smtp_conf[:password] = password
  end

  unless ARGV.length < 2 || ARGV[1] != '-v'
    puts "\nReview SMTP settings:"
    puts "SMTP server: #{smtp_conf[:address]}"
    puts "SMTP port: #{smtp_conf[:port]}"
    puts "SMTP username: #{smtp_conf[:user_name]}"

    if smtp_conf[:authentication].nil?
      puts 'No authentication.'
    else
      puts "SMTP authentication method: #{smtp_conf[:authentication]}"
      puts 'Password not displayed due to security reasons.' unless smtp_conf[:password] == ''
    end

    puts 'STARTTLS enabled.' if smtp_conf[:enable_starttls_auto] == true
    puts 'TLS on a dedicated port enabled.' if smtp_conf[:tls] == true
    puts ''

    cont = cli.ask('Does this look good? (y/n) ') { |a| a.validate = /y|n/ }

    if cont == 'y'
      puts 'OK, proceeding to send emails...'
    else
      puts 'OK, aborting send...'
      exit 1
    end
  end

  send_all_emails(emails, smtp_conf)
end
