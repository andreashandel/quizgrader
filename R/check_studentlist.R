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


  #check that all required columns are present and have the right names
  #used to require names, turned that off to limit potential privacy issues
  #colnames = c("Lastname", "Firstname", "StudentID", "Password")
  colnames = c("StudentID", "Password")
  if (sum( !(colnames %in% colnames(studentdf)) ) >0 )
  {
    return('Your student roster sheet does not have the required columns/names.')
  }


  #check that all fields are filled
  if (sum(studentdf=="") >0 )
  {
    return('Your student roster sheet contains empty entries, please fill.')
  }


  return(errormsg)
}
