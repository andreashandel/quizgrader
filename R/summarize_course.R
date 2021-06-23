#' @title Generate a summary of all quizzes in the course
#'
#' @description This function creates a dataframe summarizing the quizzes in the course.
#'
#' @param completequizzes_folder folder where complete quizzes are saved
#'
#' @return
#' If things went well, a dataframe containing a summary of all quizzes.
#' Otherwise an error message is returned.
#' @export




#######################################################


summarize_course <- function(completequizzes_folder)
{

  # identify quiz files
  completequiz_files = list.files(path = completequizzes_folder,
                                  pattern = "\\.xlsx$",
                                  recursive=FALSE,
                                  full.names = TRUE
                                  )
  completequiz_files = completequiz_files[-which(grepl("course_summary.*?[.]xlsx$", completequiz_files))]

  # read each one and extract quizid, number of questions, due date, number of attempts
  # then, put all summaries into a dataframe
  summary_df <- lapply(completequiz_files,
                       function(.file)
                         {
                         .quiz <- readxl::read_xlsx(.file, col_types = "text")
                         .quiz_summary <- data.frame(QuizID = .quiz$QuizID[1],
                                                     n_Questions = nrow(.quiz),
                                                     DueDate = .quiz$DueDate[1],
                                                     Attempts = .quiz$Attempts[1]
                                                     )
                         return(.quiz_summary)
                         }
                       ) %>%
                dplyr::bind_rows() %>%
                data.frame()



  if(nrow(summary_df)==0){
    return(paste("Currently, there are no quizzes associated with this course."))
  }else{
    return(summary_df)
  }


  writexl::write_xlsx(summary_df, fs::path(completequizzes_folder, "course_summary.xlsx"), col_names = TRUE, format_headers = TRUE)



}
