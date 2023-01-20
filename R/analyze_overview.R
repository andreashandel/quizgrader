#' @title Generate a summary of all quizzes in the course
#'
#' @description This function creates a dataframe summarizing the quizzes and submissions in the course.
#' This is a helper function called by the quizmanager app.
#'
#' @param courselocation parent folder for the course
#'
#' @return
#' If things went well, a dataframe containing a summary of all quizzes.
#' @export



#######################################################
# this function calls summarize_course, compile_submissions and compile_submission_logs


analyze_overview <- function(courselocation)
{

  # load submissions log
  submissions_log <- load_logfile(courselocation)

  #turn columns into the right types
  sub_df <- submissions_log |> dplyr::mutate(Attempt = as.numeric(Attempt), Score = as.numeric(Score),
                                          n_Questions = as.numeric(n_Questions), n_Correct = as.numeric(n_Correct),
                                          Submit_Date = as.Date(Submit_Date), QuizDueDate = as.Date(QuizDueDate))

  # get the test users from the student list file
  studentlistfile <- fs::dir_ls(fs::path(courselocation,"studentlist"))
  studentdf <- readxl::read_xlsx(studentlistfile, col_types = "text", col_names = TRUE)
  studentdf$StudentID <- tolower(studentdf$StudentID)
  testusers = trimws(tolower(studentdf$StudentID[studentdf$Testuser == TRUE]))

  # kick test users out of the submission log entries
  sub_df <- sub_df |> dplyr::filter(!(StudentID %in% testusers))

  summary_table <- sub_df |> dplyr::group_by(QuizID) |>
                          dplyr::summarize( submissions = dplyr::n(), students = length(unique(StudentID)), lowest = min(Score), highest = max(Score) )


  return(summary_table)
}
