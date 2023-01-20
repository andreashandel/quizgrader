#' @title Find and load the most recent log file
#'
#' @description Determines the most recent log file at time of function call
#' and loads it.
#' This is used by both the quizgrader and quizmanager parts of the package
#'
#' @param courselocation parent folder for the course
#'
#' @return
#' If things went well, a dataframe containing the entries of the latest log file.
#' Otherwise an error message is returned.
#' @export



#######################################################
# this function calls summarize_course, compile_submissions and compile_submission_logs


load_logfile <- function(courselocation)
{

  # read latest log file
  listfiles <- fs::dir_info(fs::path(courselocation, "studentsubmissions", "logs"))
  #load the most recent one, which is the one to be used
  filenr = which.max(listfiles$modification_time) #find most recently changed file
  submissions_log <- readxl::read_xlsx(listfiles$path[filenr], col_types = "text", col_names = TRUE)

  return(submissions_log)

}
