#' @title Generate a table of the log file for all quizzes in the course
#'
#' @description This function creates a dataframe summarizing the quizzes and submissions in the course.
#' This is used by the quizmanager part of the package
#'
#' @param courselocation parent folder for the course
#'
#' @return
#' If things went well, a dataframe containing a summary of all quizzes.
#' Otherwise an error message is returned.
#' @export



#######################################################
# this function calls summarize_course, compile_submissions and compile_submission_logs


analyze_log <- function(courselocation)
{

  # read latest log file
  listfiles <- fs::dir_info(fs::path(courselocation, "studentsubmissions", "logs"))
  #load the most recent one, which is the one to be used
  filenr = which.max(listfiles$modification_time) #find most recently changed file
  submissions_log <- readxl::read_xlsx(listfiles$path[filenr], col_types = "text", col_names = TRUE)

  overview_table <- dplyr::select(submissions_log, -n_Questions, -n_Correct) |>
                                        dplyr::arrange(QuizID, StudentID)

  return(overview_table)


}
