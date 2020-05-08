# frozen_string_literal: true

require 'mail'
require_relative 'assignment'

def email_name(name)
  splitted = name.split ', '
  return splitted[0] unless splitted.length > 1

  splitted[1]
end

def email_text(hw_name, submission)
  per_exercise = ''
  (0..(submission.score.length - 1)).each do |i|
    per_exercise.concat "Exercise #{i + 1}: #{submission.score[i]} pts\n"
  end

  "Dear #{email_name submission.student},\n\
This is your grade and feedback for #{hw_name}. You received a total of #{submission.total} points \
on this homework.\nThe score your received for each individual exercise is shown below:\n\n\
#{per_exercise}\n\
Comments from the instructor (if any):\n\
#{submission.comments}"
end

def print_text_to_file(hw_name, submission)
  filename = (submission.student.split ', ').join('_').gsub(' ', '_').gsub('.', '')
                                            .downcase.concat('.txt')
  File.open(filename, 'w') { |f| f.write email_text(hw_name, submission) }
end

def print_all_emails_text(assgn)
  assgn.submissions.each { |s| print_text_to_file(assgn.name, s) }
end

def gen_email(course_name, hw_name, submission, from_addr, cc_addr = '')
  mail = Mail.new do
    to      submission.email
    from    from_addr
    subject "[To: #{email_name submission.student}] Feedback for #{hw_name} (#{course_name})"
    body    email_text(hw_name, submission)
  end

  mail[:cc] = cc_addr if cc_addr != ''

  mail
end

def gen_all_emails(course_name, assgn, from_addr, cc_addr = '')
  emails = {}

  assgn.submissions.each do |s|
    mail = gen_email(course_name, assgn.name, s, from_addr, cc_addr)
    emails[s.student] = mail
  end

  emails
end

def save_all_emails(path, emails)
  emails.each do |name, mail|
    filename = File.join(path, (name.split ', ').join('_').gsub(' ', '_').gsub('.', '')
                                .downcase.concat('.mail'))
    File.open(filename, 'w') { |f| f.write mail }
  end
end

def send_all_emails(emails, smtp_conf)
  emails.each do |name, mail|
    puts "Sending email to #{name}..."
    mail.delivery_method(:smtp, smtp_conf)
    mail.deliver!
  end
end
