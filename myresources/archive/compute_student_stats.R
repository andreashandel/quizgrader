#' @title Compute overall quiz stats for each student
#'
#' @description This function
#'
#' @param studentid id of student
#' @param quizid id of quiz
#' @param gradelist gradelist data frame
#'
#' @return
#' If things went well, a vector containing student stats.
#' Otherwise an error message is returned.
#' @export




#######################################################
#compute student stats
#for a given submission, look up student's previous submissions
#and return average score and number of submitted quizzes
compute_student_stats <- function(studentid, quizid, gradelist)
{

  log_files <- list.files(path = studentsubmissions_folder,
                          pattern = paste0("log_", studentid, ".*?[.]txt"),
                          recursive = TRUE,
                          full.names = TRUE
                          )

  log_keys <- strsplit(gsub(".*?log_(.*?)[.]txt", "\\1", log_files), split = "_")


  log_df <- dplyr::bind_cols(setNames(data.frame(t(sapply(log_keys, c)))[-3], nm = c("StudentID", "QuizID", "Attempt")),
                             file = log_files)




  #pull out all columns containing grades for this student
  #those must have 'grade' in their name
  studentrow = which(gradelist[,"StudentID"] == studentid)
  allquizgrades = gradelist[studentrow,grepl("Grade", colnames(gradelist))]

  #figure out column of current quiz, remove all future quizzes
  thisquiz = which(names(allquizgrades) == paste0(quizid,'_Grade'))

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
