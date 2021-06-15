#' @title Load and read the studentlist file
#'
#' @description This function loads the studentlist file and does some formatting
#'
#' @param studentlist_folder Name of folder where the studentlist file is stored
#'
#' @return
#' Returns the studentlist as data frame
#' If anything is not right, an error message is returned.
#' @export


read_studentlist <- function(studentlist_folder)
{
  #get names of all studentlist files, load the most recent one.
  files = list.files(path = studentlist_folder, recursive=FALSE, pattern = "studentlist.+xlsx", full.names = TRUE)
  filenr = which.max(file.info(files)$ctime) #find most recently changed file
  studentlistfile = files[filenr]
  studentlist <- readxl::read_excel(path = studentlistfile, col_types = "text")
  return(studentlist)
}
