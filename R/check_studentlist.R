#' @title Check the studentlist file
#'
#' @description This function checks a studentlist dataframe to ensure it is valid
#'
#' @param studentdf dataframe with student list information
#'
#' @return If everything is right, NULL is returned
#' If anything is not right, an error message is returned
#' @export

check_studentlist <- function(studentdf)
{

  errormsg = NULL


  # The student list needs to be an Excel file with at least
  #' columns Lastname, Firstname, ID and Password.
  #' It should be based on the provided template.
  #ADD CODE HERE TO CHECK PROPER CONTENT/FORMATTING



  return(errormsg)
}
