#' @title Generate a table showing detailed submission results for a selected quiz
#'
#' @description This function creates a dataframe showing
#' what each student submitted for a quiz, and some summary statistics
#' for each question.
#' This is used by the quizmanager part of the package
#'
#' @param courselocation parent folder for the course
#' @param selected_quiz quiz to be analyzed
#'
#' @return
#' If things went well, a dataframe containing detailed information
#' for each question in a quiz.
#' Otherwise an error message is returned.
#' @export


analyze_quiz <- function(courselocation, selected_quiz)
{

  #write code to produce a table that shows students in rows, quiz questions as columns, and for each student/question what students submitted
  #also maybe some summary stats for each question (distribution of answers and % who got it right)


  #################
  # this code doesn't quite do the right thing, it only pulls the log file with the summary information
  # and filters by quiz
  # should eventually be replaced with more detailed code
  #################

  submissions_log <- load_logfile(courselocation)

  #turn columns into the right types
  df1 <- dplyr::mutate(submissions_log, Attempt = as.numeric(Attempt), Score = as.numeric(Score),
                       n_Questions = as.numeric(n_Questions), n_Correct = as.numeric(n_Correct),
                       Submit_Date = as.Date(Submit_Date), QuizDueDate = as.Date(QuizDueDate))

  # kick out any entries from the test users
  summary_table <- df1 |> dplyr::filter((QuizID == selected_quiz))


}
