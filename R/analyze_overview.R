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

  # read latest log file
  listfiles <- fs::dir_info(fs::path(courselocation, "studentsubmissions", "logs"))
  #load the most recent one, which is the one to be used
  filenr = which.max(listfiles$modification_time) #find most recently changed file
  submissions_log <- readxl::read_xlsx(listfiles$path[filenr], col_types = "text", col_names = TRUE)

  #turn columns into the right types
  df1 <- dplyr::mutate(submissions_log, Attempt = as.numeric(Attempt), Score = as.numeric(Score),
                                           n_Questions = as.numeric(n_Questions), n_Correct = as.numeric(n_Correct),
                                           Submit_Date = as.Date(Submit_Date), QuizDueDate = as.Date(QuizDueDate))

  summary_table <- df1 |> dplyr::group_by(QuizID) |>
                          dplyr::summarize( submissions = dplyr::n(), students = length(unique(StudentID)), lowest = min(Score), highest = max(Score) )


  return(summary_table)

}
