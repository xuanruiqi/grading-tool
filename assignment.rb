# frozen_string_literal: true

# An assignment, has submissions
class Assignment
  # @name: name of the assignment
  # @num_exercises: total number of exercises
  # @max_points: an array of numbers, each is the max number of points on an
  #              exercise. The length of this array must be equal to
  #              @num_exercises.
  # @submissions: an array of submissions

  def initialize(name, num_exercises, max_points, submissions)
    @name = name
    @num_exercises = num_exercises
    @max_points = max_points
    @total_max_points = @max_points.reduce :+
    @submissions = submissions
  end

  attr_reader :name, :num_exercises, :max_points, :total_max_points, :submissions

  def add_submission(submission)
    if submission.score.length != @num_exercises
      raise "Invalid homework: #{submission.student}'s homework has the wrong" \
            'number of exercises!'
    end

    (0..(@max_points.length - 1)).each do |i|
      next if submission.score[i] <= @max_points[i] # +1 to fix the indexing

      raise "Invalid homework: on exercise #{i + 1}, #{submission.student} got a higher " \
            'score than the maximum possible!'
    end

    @submissions = @submissions << submission
  end

  def list_scores
    @submissions.map(&:total)
  end

  def num_perfect
    list_scores.filter { |s| s == @total_max_points }.length
  end

  def num_fail
    list_scores.filter { |s| s < @total_max_points * 0.6 }.length
  end

  def avg
    list_scores.reduce(:+) / @submissions.length
  end

  # https://stackoverflow.com/questions/14859120/calculating-median-in-ruby/14859546
  def median
    sorted = list_scores.sort
    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  def report
    puts "The total number of points on this assignment is #{@total_max_points}."
    puts "There are a total of #{@submissions.length} submissions."
    puts "The highest score is #{list_scores.max}. #{num_perfect} students attained perfect scores."
    puts "The lowest score is #{list_scores.min}. #{num_fail} sutdents did not attain at least 60%."
    puts format('The average score is %<avg>0.2f, and the median score is %<median>0.2f.',
                avg: avg, median: median)
  end

  def full_report
    report
    puts ''

    sorted = @submissions.sort_by(&:student)

    sorted.each { |s| puts "#{s.student}: #{s.total}" }
  end
end

# A submission to an assignment
class Submission
  # @student: name of student
  # @email: email address of student
  # @score: an array of numbers, each is the score that the student earned on an exercise.
  #         The length of this array must be equal to @num_exercises in the Assignment the
  #         Submission belongs to.
  # @comments: a string which is the comment to be sent to the student
  def initialize(student, email, score, comments)
    @student = student
    @email = email
    @score = score
    @total = @score.reduce :+
    @comments = comments
  end

  attr_reader :student, :email, :score, :total, :comments
end
