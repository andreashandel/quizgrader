#' @title Load and read the gradelist file
#'
#' @description This function loads the gradelist file and does some formatting
#'
#' @param gradelist_folder Name of folder where all the courselist files are stored
#'
#' @return
#' Returns the gradelist as data frame
#' If anything is not right, an error message is returned.
#' @export


read_gradelist <- function(gradelist_folder)
{
  #get names of all courselistlist files, load the most recent one.
  files = list.files(path = gradelist_folder, recursive=FALSE, pattern = "gradelist.+xlsx", full.names = TRUE)
  filenr = which.max(file.info(files)$ctime) #find most recently changed file
  gradelistfile = files[filenr]
  gradelist <- readxl::read_excel(path = gradelistfile, col_types = "text")
  return(gradelist)
}
