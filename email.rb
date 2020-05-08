require 'mail'
require_relative 'assignment'

def email_name(name)
  splitted = name.split ", "

  if splitted.length > 1 then
    return splitted[1]
  else
    return splitted[0]
  end
end

def email_text(hw_name, submission)
  per_exercise = ""
  for i in 0..(submission.score.length-1) do
    per_exercise.concat "Exercise #{i+1}: #{submission.score[i]} pts\n"
  end

  txt = "Dear #{email_name submission.student},\n\  
This is your grade and feedback for #{hw_name}. You received a total of #{submission.total} points \
on this homework.\nThe score your received for each individual exercise is shown below:\n\n\
#{per_exercise}\n\
Comments from the instructor (if any):\n\
#{submission.comments}"

  return txt
end

def print_text_to_file(hw_name, submission)
  filename = (submission.student.split ", ").join("_").gsub(" ", "_").gsub(".", "").downcase.concat(".txt")
  File.open(filename, 'w') { |f|
    f.write email_text(hw_name, submission)
  }
end

def print_all_emails_text(assgn)
  for s in assgn.submissions do
    print_text_to_file(assgn.name, s)
  end
end

def gen_email(course_name, hw_name, submission, from_addr, cc_addr="")
  mail = Mail.new do
    to      submission.email
    from    from_addr
    subject "[To: #{email_name submission.student}] Feedback for #{hw_name} (#{course_name})"
    body    email_text(hw_name, submission)
  end

  if cc_addr != "" then
    mail[:cc] = cc_addr
  end
  
  return mail
end

def gen_all_emails(course_name, assgn, from_addr, cc_addr="")
  emails = {}
  
  for s in assgn.submissions do
    mail = gen_email(course_name, assgn.name, s, from_addr, cc_addr)
    emails[s.student] = mail
  end

  return emails
end

def save_all_emails(path, emails)
  emails.each do |name, mail|
    filename = File.join(path, (name.split ", ").join("_").gsub(" ", "_").gsub(".", "").downcase.concat(".mail"))
    File.open(filename, 'w') { |f|
      f.write mail
    }
  end
end

def send_all_emails(emails, smtp_conf)
  emails.each do |name, mail|
    puts "Sending email to #{name}..."
    mail.delivery_method(:smtp, smtp_conf)
    mail.deliver!
  end
end
