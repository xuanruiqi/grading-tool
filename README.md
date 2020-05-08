# Automated Grading Tool
A makeshift automated grading tool creating in the middle of stay-at-home season for online grading. 
Put the grades in YAML files and the tool generates reports, emails, etc. for grade management & sending to students.

## Usage
First, install Ruby using [RVM](https://rvm.io/), and do `bundle install` in the current directory. Create a config
file with the following syntax, and put it in the current directory, the home directory, or `~/.config` (the tool searches 
exactly in this order):

```yaml
course_name: Makeshift Grading
send_email: Xuanrui Qi <me@xuanruiqi.com> # Your email address
cc: # People to CC on grade emails
  - Xuanrui Qi <xuanrui@nagoya-u.jp>
smtp: # SMTP server configuration
  ...
```
For the SMTP server configuration, see [this page](https://www.rubydoc.info/gems/mail/Mail/SMTP) for the available fields.
However, don't enter your password in clear text here. This tool will prompt you for the password each time.

make a folder for each assignment. Then, make an "assignment configuration" with this syntax:

```yaml
assignment: Name of assignment
num_exercises: 4 # Total number of exercises
score: # Max. number of points on each exercise
  - 10
  - 10
  - 10
  - 10
```

Then, for each submission, create a file with this syntax:

```yaml
name: Model Student
email: modelstudent@modeluniversity.edu
score: # Number of points received for each exercise
  - 8
  - 9
  - 9
  - 8
comments: >-
  Additional comments to the student.
```

Finally, `./send [path-to-folder] [-v]` to send students their grades, and `./report [path-to-folder]` to see a (simple) grade report. 

## WIP
  * We can only handle one course at this time. Can we fix this?
  * Refactor the code to use `highline` for all prompts.
  * Currently, we can't handle parts of exercises. Need to make score nested.
  * You must enter the student's email in each submission file. This needs to be fixed.
  * Grade management, interfacing with spreadsheets/CSV.

# Author
Xuanrui Qi [me@xuanruiqi.com](mailto:me@xuanruiqi.com)

# License
MIT License.
