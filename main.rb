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

if $PROGRAM_NAME == __FILE__
  if ARGV.length.empty?
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

  puts '\nPreparing emails...'

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

  if course_title == ''
    print 'Title of the course: '
    course_title = STDIN.gets.chomp
  end

  if sender_email == ''
    print 'Your email address: '
    sender_email = STDIN.gets.chomp
  end

  if cc_email == ''
    cc_list = []

    loop do
      print 'Any more email addresses to cc? Enter one at a time. If none, just press enter: '
      cc_new = STDIN.gets.chomp
      break if cc_new == ''
    end

    cc_email = cc_list.join(', ')
  end

  emails = gen_all_emails(course_title, assgn, sender_email, cc_email)
  save_all_emails(ARGV[0], emails) unless ARGV.length < 2 || ARGV[1] != '-v'

  # if there's no SMTP config then interactively ask
  if smtp_conf.nil?
    smtp_conf = {}

    print 'SMTP server address: '
    smtp_conf[:address] = STDIN.gets.chomp
    print 'SMTP port: '
    smtp_conf[:port] = STDIN.gets.chomp.to_i
    print 'SMTP username: '
    smtp_conf[:user_name] = STDIN.gets.chomp

    # only support PLAIN, which should be good for most people (maybe not outlook)
    loop do
      print 'Authentication (login) required? (y/n) '
      auth = STDIN.gets.chomp

      if auth == 'y'
        smtp_conf[:authentication] = 'plain'

        loop do
          print 'STARTTLS? (y/n)'
          starttls = STDIN.get.chomp

          if starttls == 'y'
            smtp_conf[:enable_starttls_auto] = true
            break
          elsif starttls == 'f'
            smtp_conf[:enable_starttls_auto] = false
            break
          else
            puts 'Please answer y or n!'
          end
        end

        loop do
          print 'TLS on a dedicated port? (y/n)'
          starttls = STDIN.get.chomp

          if starttls == 'y'
            smtp_conf[:tls] = true
            break
          elsif starttls == 'f'
            smtp_conf[:tls] = false
            break
          else
            puts 'Please answer y or n!'
          end
        end

        break
      elsif auth == 'n'
        smtp_conf[:authentication] = nil
        break
      else
        puts 'Please answer y or n!'
      end
    end
  end

  unless smtp_conf[:authentication].nil?
    cli = HighLine.new
    password = cli.ask('Password for sending email: ') { |q| q.echo = false }
    smtp_conf[:password] = password
  end

  unless ARGV.length < 2 || ARGV[1] != '-v'
    puts 'Review SMTP settings:'
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

    loop do
      print 'Does this look good? (y/n) '
      ans = STDIN.gets.chomp

      if ans == 'y'
        puts 'OK, proceeding to send emails...'
        break
      elsif ans == 'n'
        puts 'OK, aborting send...'
        exit 1
      else
        puts 'Please answer y or n!'
      end
    end
  end

  send_all_emails(emails, smtp_conf)
end
