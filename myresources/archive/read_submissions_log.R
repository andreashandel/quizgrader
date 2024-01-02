#' @title Load and read the submissions log file
#'
#' @description This function loads the submissions log file and does some formatting
#'
#' @param studentsubmissions_folder Name of folder where all the student submission files are stored
#'
#' @return
#' Returns the submissions log file as data frame
#' If anything is not right, an error message is returned.
#' @export


read_submissions_log <- function(studentsubmissions_folder)
{
  #get names of all submission log files, load the most recent one.
  files = list.files(path = fs::path(studentsubmissions_folder, "logs"), recursive=FALSE, pattern = "submissions_log.+xlsx", full.names = TRUE)
  filenr = which.max(file.info(files)$ctime) #find most recently changed file
  submissions_log_file = files[filenr]
  submissions_log <- readxl::read_excel(path = submissions_log_file, col_types = "text")
  return(submissions_log)
}
