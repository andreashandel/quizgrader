#' @title Compute overall quiz stats for each student
#'
#' @description This function
#'
#' @param studentid
#' @param quizid
#'
#' @return
#' If things went well, a vector containing student stats.
#' Otherwise an error message is returned.
#' @export




#######################################################
#compute student stats
#for a given submission, look up student's previous submissions
#and return average score and number of submitted quizzes
compute_student_stats <- function(studentid, quizid, classlist)
{

  #pull out all columns containing grades for this student
  #those must have 'grade' in their name
  allquizgrades = classlist[studentid,grepl("grade", colnames(classlist))]

  #figure out column of current quiz, remove all future quizzes
  thisquiz = which(names(allquizgrades) == paste0(quizid,'_grade'))

  #contains vector of quiz grades
  quizgrades = allquizgrades[1:thisquiz]

  # compute average of past quizzes
  # for quizzes that are past that don't have an entry, enter a 0
  numeric_grades = quizgrades
  numeric_grades[quizgrades==""] <- 0
  # with that 0 substitution, conversion to numeric should work
  # if it doesn't the average will have an NA
  # which indicates something went wrong
  gradeaverage = mean(as.numeric(numeric_grades))
  # compute total number quizzes done so far
  totalquizzes = length(quizgrades)
  # determine number of submitted quizzes
  gradesubmissions = sum(quizgrades != "")

  # return everything as vector
  student_stats = c(gradeaverage=gradeaverage,gradesubmissions=gradesubmissions,totalquizzes=totalquizzes)

  return(student_stats)


}
