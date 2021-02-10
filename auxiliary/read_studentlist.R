#' @title Load and check the studentlist file
#'
#' @description This function loads the user generated studentlist and checks it
#'
#' @param courselocation Path to course
#'
#' @return the studentlist as data frame
#' If anything is not right, an error message is returned
#' @export

read_studentlist <- function(courselocation)
{

  #find file containing student information
  #find the one with the newest time-stamp (as per modified date)
  courselistpath = file.path(courselocation,"studentlists")
  courslistfiles = list.files(path = courselistpath, recursive=FALSE, pattern = "\\.xlsx$", full.names = TRUE)
  filenr = which.max(file.info(courselistfiles)$ctime) #find most recently changed file
  courselistfile = courslistfiles[filenr]
  courselist <- readxl::read_excel(path = courselistfile, col_types = "text")

  # The student list needs to be an Excel file with at least
  #' columns Lastname, Firstname, ID and Password.
  #' It should be based on the provided template.
  #ADD CODE HERE TO CHECK PROPER CONTENT/FORMATTING

  return(courselist)
}
