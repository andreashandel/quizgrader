#' @title Create main quiz tracking data frame
#'
#' @description This function takes the user-supplied
#' list of students and a directory containing all quizzes
#' and generates a data frame that has for each student
#' their information needed for login and multiple columns
#' for each quiz tracking/recording student submission
#'
#' @param courselistfile Name of file that contains the course list.
#' The file needs to be an Excel file with at least
#' columns Lastname, Firstname, ID and Password.
#' It should be based on the provided template.
#' @param quizlocation The name of the folder where
#' the complete quizzes are stored.
#' Those quizzes will be parsed to generate the data frame.
#'
#' @return A data frame with each student as row, and columns
#' containing student information and information for each quiz.
#' @export



make_course_list <- function(courselistfile,quizlocation)
{

  #read in the csv file containing the student names, ID and password
  #other columns can be in the original file, they will be ignored
  courslist <- read.csv(courselistfile)
  nstudent <- nrow(courselist) #number of students

  # Pulls all of the xlsx files from the solution folder to get names for quizzes
  # Each xlsx file will be the name of a quiz. The file needs to end in _complete.xlsx
  quizfilenames <- list.files(quizlocation,pattern='*.xlsx')

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




