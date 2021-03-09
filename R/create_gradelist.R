#' @title Create main quiz tracking file
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



create_gradelist <- function(courselocation)
{

  #load file containing student information
  #find the one with the newest time-stamp (as per modified date)
  studentlistpath = file.path(courselocation,"studentlists")
  studentlistfiles = list.files(path = studentlistpath, recursive=FALSE, pattern = "\\.xlsx$", full.names = TRUE)
  filenr = which.max(file.info(studentlistfiles)$ctime) #find most recently changed file
  studentlistfile = studentlistfiles[filenr]
  studentdf <- readxl::read_excel(path = studentlistfile, col_types = "text")


  #check that courselist file is proper
  errormsg <- check_studentlist(studentdf)
  if (!is.null(errormsg))
  {
    #something didn't go right, return error message to calling function
    return(errormsg)
  }


  nstudent <- nrow(studentdf) #number of students

  # start grade list by assigning the student list
  gradelist <- studentdf

  #now add information for all quizzes

  # Get all xlsx files from the solution folder

  #path to complete quizzes
  completequizpath = fs::path(courselocation,"completequizzes")
  #get all file names for quiz files, with path
  completequizfiles = fs::dir_ls(completequizpath, glob = "*.xlsx")

  #loop over all complete quizzes and add relevant columns to gradelist
  for (i in 1:length(completequizfiles))
  {

    #load complete quiz sheet
    quizdf <- readxl::read_excel(completequizfiles[i], col_types = "text", col_names = TRUE)

    if (!tibble::is_tibble(quizdf))
    {
      #something didn't go right
      #read_excel should have returned an error message
      #send that message to calling function
      return(quizdf)
    }

    ##############################
    # Check that file is a quiz sheet in the required format.
    ##############################
    errormsg <- check_quiz(quizdf)
    if (!is.null(errormsg))
    {
      return(paste0('File ',completequizfiles[i]," has this problem: ",errormsg))
    }

    # Create names for columns for each quiz
    # those columns will track submissions
    dfcolnames = paste0(quizdf$QuizID[1],c("_DueDate","_SubmitDate","_Attempt","_Grade") )

    #make sure none of the new column names already exists
    #that can happen if user didn't create unique quiz IDs
    if (sum(colnames(gradelist) %in% dfcolnames)>0)
    {
      return(paste0('File ',completequizfiles[i]," has an already used QuizID, please fix."))
    }

    #create values for new columns
    valvec = c(quizdf$DueDate[1],"",quizdf$Attempts[1],"")
    allvals = matrix(valvec, nrow = nstudent, ncol = length(valvec), byrow=TRUE)

    # add new columns to gradelist
    gradelist[,dfcolnames] <- allvals
    #fill columns with values

  }

  browser()

  #return data frame containing the course list
  return(gradelist)

} #end function




