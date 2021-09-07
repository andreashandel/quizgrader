#' @title Check that the provided course location is a valid main quizgrader folder
#'
#' @description This function checks that a valid quiagrader folder is provided as path
#'
#' @param courselocation location of course
#'
#' @return If everything is right, NULL is returned
#' If anything is not right, an error message is returned
#' @export

check_courselocation <- function(courselocation)
{

  errormsg = NULL

  if (!fs::file_exists(fs::path(courselocation,"quizgrader.txt")))
  {
    return('The quizgrader.txt file could not be found. Make sure the path is a valid course location.')
  }
  # Could add check here to make sure first row of quizgrader.txt is the same as course folder name.

  return(errormsg)
}
