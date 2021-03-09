#' @title Check that a data frame sent to this function has a valid structure for a complete quiz
#'
#' @description This function takes the data frame or tibble
#' that is supposed to contain a valid completed quiz
#' and checks that structure and content are valid
#'
#' @param quizdf Data frame of quiz that needs to be checked
#'
#' @return An error message if it's not a valid quiz data frame,
#' otherwise NULL
#' @export



check_quiz <- function(quizdf)
{

  errormsg = NULL

  colnames = c("QuizID","QuestionID",	"Question",	"Instruction",	"Answer",	"Feedback",	"Type",	"Comment",	"DueDate",	"Attempts")
  answertypes = c("Text",'Logical', "Character", "Integer", "Fuzzy_Integer", "Numeric", "Rounded_Numeric")

  #check that all required columns are present and have the right names
  if (sum( !(colnames %in% colnames(quizdf)) ) >0 )
  {
    return('Your quiz sheet does not have the required columns/names.')
  }

  #check that QuizID is ok
  #only letters and numbers, can't be empty
  pattern = "^[a-zA-Z0-9]*$"
  idtext = quizdf$QuizID[1]
  if (!grepl(pattern,idtext) | nchar(idtext)==0 )
  {
    return('Your QuizID is not valid. Only use letters and numbers.')
  }

  #check that QuestionID is ok
  #only letters and numbers, each entry unique, can't be empty
  pattern = "^[a-zA-Z0-9]*$"
  idtext = quizdf$QuestionID
  if ( sum(!grepl(pattern,idtext))>0 | sum(duplicated(idtext))>0 | min(nchar(idtext))==0)
  {
    return('Your QuestionID is not valid. Only use letters and numbers and make sure values are unique.')
  }


  #check that Answer Type is one of the allowed types
  idtext = quizdf$Type
  if (sum(!(idtext %in% answertypes))>0 )
  {
    return('You have non-allowed values in the Type column.')
  }

  #check that due date is correct
  idtext = quizdf$DueDate[1]
  if ( is.na(lubridate::as_date(idtext)) )
  {
    return('Your due date entry is not correct.')
  }

  #check that attempts is correct
  idtext = quizdf$Attempts[1]
  if (is.na(as.numeric(idtext)) || idtext<0 )
  {
    return('Your Attempts entry is not correct.')
  }

  return(NULL)

} #end function




