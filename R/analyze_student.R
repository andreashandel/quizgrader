#' @title Generate a table showing detailed submission results for a selected student
#'
#' @description This function creates a dataframe showing
#' a detailed submission/performance history for a selected student.
#' This is used by the quizmanager part of the package
#'
#' @param courselocation parent folder for the course
#' @param selected_student student to be analyzed
#'
#' @return
#' If things went well, a dataframe containing detailed information
#' for the selected student.
#' Otherwise an error message is returned.
#' @export




analyze_student <- function(courselocation, selected_student)
{

  #write code to produce a table that shows for a selected student
  #all their quiz submissions, and what they got right/wrong, when they submitted, etc.
  #as much diagnostics per student as possible
  #this requires parsing all submission files
  #################
  # this code doesn't quite do the right thing, it only pulls the log file with the summary information
  # and filters by student
  # should eventually be replaced with more detailed code
  #################

  submissions_log <- load_logfile(courselocation)

  #turn columns into the right types
  df1 <- dplyr::mutate(submissions_log,
                       Attempt = as.numeric(Attempt), Score = as.numeric(Score),
                       n_Questions = as.numeric(n_Questions), n_Correct = as.numeric(n_Correct),
                       Submit_Date = as.Date(Submit_Date), QuizDueDate = as.Date(QuizDueDate))

  # filter by student
  summary_table <- df1 |> dplyr::filter((StudentID == selected_student))



}
