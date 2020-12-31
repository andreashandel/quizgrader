#' @title Load and read the courselist file
#'
#' @description This function loads the courselist and does some formatting
#'
#' @param courselist_folder Name of folder where all the courselist files are stored
#'
#' @return
#' Returns the courselist as data frame
#' If anything is not right, an error message is returned.
#' @export


#needs to be a tsv file with columns "lastname" (containing last name), "email" and "password"

#further columns contain grades for each assignment
#they should be of form quizname_duedate/quizname_submitdate/quizname_grade
#all column names should be lower case for consistency
#other columns can be there but are ignored
read_classlist <- function(courselist_folder)
{
  #get names of all courselistlist files, load the most recent one.
  files = list.files(path = courselist_folder, recursive=FALSE, pattern = "courselist.+xlsx", full.names = TRUE)
  filenr = which.max(file.info(files)$ctime) #find most recently changed file
  courselistfile = files[filenr]
  courselist <- readxl::read_excel(path = courselistfile, col_types = "text")
  return(courselist)
}
