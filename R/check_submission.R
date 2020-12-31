#' @title Check submission for errors before grading
#'
#' @description This function checks the submitted quiz
#' performs some checks to make sure the formatting is right
#' and also checks to ensure due date or number of submissions has not been exceeded
#'
#' @param submission The data frame containing the student submission
#' @param solution The data frame containing the solution
#' @param studentid The student who's submission is checked
#' @param quizid The ID of the quiz to be checked
#' @param courselist A data frame containing due dates, previous submissions, etc.

#' is to be created
#'
#' @return
#' If anything is not right, an error message is returned.
#' Otherwise, NULL is returned, meaning all checks went ok.
#' @export



#######################################################
#check that submitted file looks right
#also check that it hasn't been submitted yet
#also check that it's not past the due date
check_file <- function(submission,solution,studentid,quizid,classlist)
{
  docerror = NULL #will contain error message if something went wrong

  #First, do all kinds of checks to make sure the submission and solution files match
  #Make sure the number of rows are the same in the submission and the solution files
  if (nrow(submission) != nrow(solution))
  {
    docerror <- "Your submission does not have the same number of entries as the solution, please re-fill a clean sheet."
    return(docerror)
  }

  if (!("Answer" %in% colnames(submission)))
  {
    docerror <- "Your submission needs to have a column called Answer."
    return(docerror)
  }
  if (!("QuizID" %in% colnames(submission)))
  {
    docerror <- "Your submission needs to have a column called QuizID."
    return(docerror)
  }
  if (!("RecordID" %in% colnames(submission)))
  {
    docerror <- "Your submission needs to have a column called RecordID."
    return(docerror)
  }
  if (sum(submission$RecordID != solution$RecordID)>0)
  {
    docerror <- "Your RecordID entries do not match the solution."
    return(docerror)
  }
  if (sum(submission$QuizID != solution$QuizID)>0)
  {
    docerror <- "Your QuizID entries do not match the solution."
    return(docerror)
  }

  #Now check that submission hasn't already happened and is not past the due date
  #find the column that will contain grade for this quiz
  #to check to make sure student hasn't already submitted
  gradecol = which(colnames(classlist) == paste0(quizid,"_grade"))

  if (classlist[studentid,gradecol] != "")
  {
    docerror <- "It seems you already submitted your answers for this assigment."
    return(docerror)
  }

  #check to make sure it's not past the due date (if a due date is in the classlist file)
  due_id = which(colnames(classlist) == paste0(quizid,'_duedate'))
  if (length(due_id)>0) #if there is a column with a due date, check that it hasn't passed yet
  {

    duedate = classlist[studentid,due_id] #there should only be one entry
    if (duedate != "" && Sys.Date() > as.Date(duedate)) #if a date is specified, make sure it's not past
    {
      docerror <- "Unfortunately you are past the due date and can't submit anymore."
      return(docerror)
    }
  }


  return(docerror) #if things went right, return empty

} #end function that checks file
