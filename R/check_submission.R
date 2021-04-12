#' @title Check that a data frame sent to this function has a valid structure for student submitted quiz
#'
#' @description This function takes the data frame or tibble
#' that is supposed to contain a valid quiz submission
#' and checks that structure and content are valid
#'
#' @param quizdf Data frame of quiz that needs to be checked
#' @param quizid ID of quiz based on file name, needs to match quizid column entry in spreadsheet
#'
#' @return An error message if it's not a valid quiz data frame,
#' otherwise NULL
#' @export



check_submission <- function(quizdf, quizid)
{

  errormsg = NULL

  colnames = c("QuizID","QuestionID",	"Question",	"Instruction",	"Answer")

  #check that all required columns are present and have the right names
  #if other columns are present, they are ignored
  if (sum( !(colnames %in% colnames(quizdf)) ) >0 )
  {
    return('Your quiz sheet does not have the required columns/names.')
  }

  #check that QuizID is ok
  #only letters and numbers and underscore, can't be empty
  pattern = "^[a-zA-Z0-9_]*$"
  idtext = quizdf$QuizID[1]
  if (!grepl(pattern,idtext) | nchar(idtext)==0 )
  {
    return('Your QuizID is not valid. Please do not modify the originally provided value.')
  }

  if (idtext != quizid)
  {
    return('Your QuizID does not match file name. Please do not modify the original file name or QuizID value.')
  }


  #check that QuestionID is ok
  #only letters and numbers and underscore, each entry unique, can't be empty
  pattern = "^[a-zA-Z0-9_]*$"
  idtext = quizdf$QuestionID
  if ( sum(!grepl(pattern,idtext))>0 | sum(duplicated(idtext))>0 | min(nchar(idtext))==0)
  {
    return('Your QuestionID is not valid. Please do not modify the originally provided values.')
  }

  #if all answers are blank, flag that and don't let a student submit
  if (sum(quizdf$Answer=="") == nrow(quizdf))
  {
    return("All answers are missing. Please, make sure you submit your answers.")
  }



  #if none of the ckecks above failed, return an empty error message
  return(NULL)

} #end function




