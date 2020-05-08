require 'yaml'
require_relative 'assignment'

# Read a config file and generate an Assignment object, with no submissions
def read_config(filename)
  conf = File.open(filename, 'r') { |f|
    YAML.load f
  }
  
  if conf["score"].length != conf["num_exercises"] then
    raise "Invalid homework config: you claimed that there are #{conf[:num_exercises]} exercises, " \
          "but you listed #{conf[:score].length} exercises!"
  end

  assgn = Assignment.new(conf["assignment"], conf["num_exercises"], conf["score"], [])
  
  return assgn
end

def read_submission(filename)
  hw = File.open(filename, 'r') { |f|
    YAML.load f
  }
  submission = Submission.new(hw["name"], hw["email"], hw["score"], hw["comments"])
  
  return submission
end
