#' @title Compile log files from each quiz submission
#'
#' @description This function creates a dataframe from the log files generated during student submission (adaptation of the displayed results table).
#'
#' @param studentid id of student(s)
#' @param studentsubmissions_folder folder where student quiz submissions are saved
#' @param df_format which data frame format to output: "condensed" for a single row per student per quiz; "byquestion" for question-specific rows
#'
#' @return
#' If things went well, a dataframe containing student quiz results from all submitted quizzes.
#' Otherwise an error message is returned.
#' @export




#######################################################


compile_submission_logs <- function(studentid, studentsubmissions_folder, df_format = "condensed")
{


  # find log files
  ## if only one studentid, find only that student's logs, else find all
  the_pattern <- ifelse(length(studentid)==1,
                        paste0("log_", studentid, ".*?[.]txt"),
                        paste0("log_", ".*?[.]txt")
                        )

  # parse data from log filenames
  # then, subset to requested student(s) and their last attempt(s)
  # to reduce number of logs needed to read
  log_files <- list.files(path = studentsubmissions_folder,
                          pattern = paste0("log_", studentid, ".*?[.]txt"),
                          recursive = TRUE,
                          full.names = TRUE
                          )

  filename_keys <- strsplit(gsub(".*?log_(.*?)[.]txt", "\\1", log_files), split = "_")


  filename_keys_df <- dplyr::bind_cols(setNames(data.frame(t(sapply(filename_keys, c)))[-3], nm = c("StudentID", "QuizID", "Attempt")),
                                       file = log_files) %>%
                      dplyr::group_by(QuizID) %>%
                      dplyr::filter(StudentID %in% studentid & Attempt == which.max(Attempt)) %>%
                      dplyr::ungroup() %>%
                      data.frame()


  # create dataframe from read log files
  ## condensed format with only overall score per quiz per student

  if(df_format=="condensed")
  {
    log_df <- lapply(filename_keys_df$file,
                     function(.file)
                       {
                       .df <- read.delim(file = .file) %>%
                              dplyr::select(StudentID, QuizID, Score)

                       }
                     ) %>%
              dplyr::bind_rows()
  }

  if(df_format=="byquestion")
  {
    log_df <- lapply(filename_keys_df$file,
                     function(.file)
                       {
                       .df <- read.delim(file = .file) %>%
                              dplyr::select(-Score) %>%
                              tidyr::pivot_longer(cols = which(grepl(".*?q[0-9].*?", names(.))), #this may not be robust
                                                  names_to = "QuestionID",
                                                  values_to = "Score"
                                                  )
                       }
                     ) %>%
              dplyr::bind_rows()
  }


  return(log_df)
}
