#' @title Check that a file sent to this function has a valid structure for a complete quiz
#'
#' @description This function takes the name/location of a
#' file and tries to load it and check that it has a valid
#' structure and content for a quiz
#'
#' @param quizfile Path and name of file to be checked
#'
#' @return An error message if it's not a valid quiz,
#' otherwise NULL
#' @export



check_quiz <- function(quizfile)
{

  #try to load quiz file into data frame
  quizdf <- readxl::read_excel(quizfile, col_types = "text", col_names = TRUE)
  if (!is.dataframe(quizdf))
  {
    #something didn't go right, return error message to calling function
    return(quizdf)
  }

  #check columns of quiz data frame to make sure they look right
  if (colnames(quizdf) %in% c("quizid","  ",""))
  {
    return('Your quiz sheet does not have the required columns/names.')
  }

  #check that specific columns have the right contnet
  if (unique(quizdf$quizid)>1)
  {
    return('You can only have a single value for quizID')
  }

  return(NULL)

} #end function




