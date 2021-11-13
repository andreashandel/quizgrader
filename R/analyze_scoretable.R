#' @title Generate a score table for all quizzes in the course
#'
#' @description This function creates a dataframe showing scores for each quiz and student in the course.
#' For multiple allowed attempts, only the highest score is shown.
#' This table is useful for grading, less so for analysis of individual students or quizzes.
#' This is a helper function called by the quizmanager app.
#'
#' @param courselocation parent folder for the course
#'
#' @return
#' If things went well, a dataframe containing a table with scores for all students and quizzes.
#' @export


analyze_scoretable <- function(courselocation)
{

  # read latest log file
  listfiles <- fs::dir_info(fs::path(courselocation, "studentsubmissions", "logs"))
  #load the most recent one, which is the one to be used
  filenr = which.max(listfiles$modification_time) #find most recently changed file
  submissions_log <- readxl::read_xlsx(listfiles$path[filenr], col_types = "text", col_names = TRUE)

  #turn columns into the right types
  df1 <- submissions_log %>% dplyr::mutate(Attempt = as.numeric(Attempt), Score = as.numeric(Score),
                                           n_Questions = as.numeric(n_Questions), n_Correct = as.numeric(n_Correct),
                                           Submit_Date = as.Date(Submit_Date), QuizDueDate = as.Date(QuizDueDate))


  # get only the max score for each quiz in case there were multiple attempts allowed
  # that last slice command is there in case someone has multiple submissions with the same score
  # then remove the attempt column
  df2 <- df1 %>% dplyr::group_by(QuizID, StudentID) %>% dplyr::filter(Score == max(Score)) %>% dplyr::slice( n = 1) %>% dplyr::select(-Attempt)

  # change to wide format for display
  df3 <- df2 %>% tidyr::pivot_wider(id_cols = c(StudentID), names_from = QuizID, values_from = Score)

  return(df3)
}
