#' @title Return IDs of all students and a summary table of all quizzes in the course
#'
#' @description This function creates a list based on current student roster
#' and course quizzes.
#'
#' @param courselocation parent folder for all course directories
#'
#' @return If things went well, a list containing two elements:
#' \itemize{
#'     \item `studentIDs`: A vector with name/ID of all students in course.
#'     \item `quizstats`: A data frame of basic quiz stats.
#'   }
#'
#' Otherwise an error message is returned.
#' @export




#######################################################


summarize_course <- function(courselocation)
{
  #load student list
  studentlistfile <- fs::dir_ls(fs::path(courselocation,"studentlist"))
  if (length(studentlistfile)>0)
  {
    studentdf <- readxl::read_xlsx(studentlistfile, col_types = "text", col_names = TRUE)
    studentids = tolower(studentdf$StudentID)
    #those are not used anymore
    #studentnames = paste(tolower(studentdf$Firstname),tolower(studentdf$Lastname))

  } else {
    studentids = NULL
  }


  # get names of all complete quiz files
  completequiz_files = fs::dir_ls(path = fs::path(courselocation, "completequizzes"), glob = "*.xlsx")
  if (length(completequiz_files)>0)
  {
    # read each one and extract quizid, number of questions, due date, number of attempts
    # then, put all summaries into a dataframe
    summary_df <- lapply(completequiz_files,
                         function(.file)
                           {
                           .quiz <- readxl::read_xlsx(.file, col_types = "text")
                           .quiz_summary <- data.frame(QuizID = .quiz$QuizID[1],
                                                       n_Questions = round(nrow(.quiz),0),
                                                       DueDate = .quiz$DueDate[1],
                                                       Attempts = .quiz$Attempts[1]
                                                       )
                           return(.quiz_summary)
                           }
                         )

    quizdf <- data.frame(dplyr::arrange(dplyr::bind_rows(summary_df), DueDate))
  } else {
    # if no quizzes exist yet, return NULL
    quizdf = NULL
  }

  # get columns of gradelist if exists
  gradelistfile <- fs::dir_ls(fs::path(courselocation,"gradelist"))
  if (length(gradelistfile)>0)
  {
    gradelistdf <- readxl::read_xlsx(gradelistfile, col_types = "text", col_names = TRUE)
    gradelistnames = colnames(gradelistdf)
  } else {
    gradelistnames = NULL
  }


  ret = list(usernames = studentids, quizdf = quizdf, gradelist = gradelistnames)

  return(ret)

}
