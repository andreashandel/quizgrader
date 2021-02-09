#' @title Create main quiz tracking data frame
#'
#' @description This function takes the user-supplied
#' list of students and a directory containing all quizzes
#' and generates a data frame that has for each student
#' their information needed for login and multiple columns
#' for each quiz tracking/recording student submission
#'
#' @param courselocation Path to course
#'
#' @return A data frame with each student as row, and columns
#' containing student information and information for each quiz.
#' @export



make_gradelist <- function(courselocation)
{

  #load file containing student information
  #also check for proper formatting/content
  studentlist <- read_studentlist(courselocation)
  if (is.character(studentlist))
  {
    #something didn't go right, return error message to calling function
    return(studentlist)
  }

  nstudent <- nrow(studentlist) #number of students



  # Pulls all of the xlsx files from the solution folder to get names for quizzes
  # Each xlsx file will be the name of a quiz. The file needs to end in _complete.xlsx
  quizfilenames <- list.files( ,pattern='*.xlsx')

  #for each quiz that is found, add these columns:
  #due date, submit date, submit attempt max, submit attempt actual and grade
  for (nn in 1:length(quizfilenames))
  {
    #Clean up the quiz names
    quizname <- quizfilenames[nn] %>% stringr::str_replace("_complete.xlsx*","")

    # Create names for columns
    duedate    <- c(paste0(quizname,"_duedate"))
    submitdate <- c(paste0(quizname,"_submitdate"))
    quizgrade  <- c(paste0(quizname,"_grade"))

    columns<-c(columns, duedate, submitdate, quizgrade)
  }

  #return data frame containing the course list
  return(courselist)

} #end function




