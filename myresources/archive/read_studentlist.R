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

  #load student list
  listfiles <- fs::dir_info(fs::path(studentlist_folder))
  #load the most recent one, which is the one to be used
  filenr = which.max(listfiles$modification_time) #find most recently changed file
  studentlist <- readxl::read_xlsx(listfiles$path[filenr], col_types = "text", col_names = TRUE)

  #files = list.files(path = studentlist_folder, recursive=FALSE, pattern = "studentlist.+xlsx", full.names = TRUE)
  #filenr = which.max(file.info(files)$ctime) #find most recently changed file
  #studentlistfile = files[filenr]
  #studentlist <- readxl::read_excel(path = studentlistfile, col_types = "text")
  return(studentlist)
}
