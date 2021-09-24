#' @title Generate a summary of all quizzes in the course
#'
#' @description This function creates a dataframe summarizing the quizzes in the course.
#' This is used by the quizmanager part of the package
#'
#' @param courselocation parent folder for the course
#' @param grades_type one of c("overview", "student", "question")
#' @param duedate_filter logical indicating whether to output statistics for past quizzes only
#'
#' @return
#' If things went well, a dataframe containing a summary of all quizzes.
#' Otherwise an error message is returned.
#' @export



#######################################################
# this function calls summarize_course, compile_submissions and compile_submission_logs


analyze_quizzes <- function(courselocation, grades_type="overview", duedate_filter=FALSE)
{

  # aggregate all submissions to a single tibble
  submissions <- quizgrader::compile_submissions(courselocation)


  if(grades_type %in% c("overview", "student"))
  {

    # load course summary and studentlist to have complete data shell regardless of missing submissions
    course.summary <- quizgrader::summarize_course(courselocation)[["quizdf"]]

    studentlist <- readxl::read_xlsx(fs::dir_ls(fs::path(courselocation, "studentlists")), col_types = "text", col_names = TRUE)

    grades.scaffold <- expand.grid(QuizID = course.summary$QuizID, StudentID = studentlist$StudentID)

    grades <- dplyr::full_join(studentlist, dplyr::full_join(course.summary, grades.scaffold, by = "QuizID"), by = "StudentID")



    # subset submissions df variables to include student indicators, quiz due dates, and variables for overall quiz stats: number of questions and number of correct responses
    simple.grades <- submissions[, which(
      names(submissions)%in%c("Lastname", "Firstname") |
        grepl("\\.n\\.", names(submissions)) |
        grepl("DueDate", names(submissions)))]




    # iterate over quizzes to transform data from wide to long format

    ## quizIDs <- gsub("[.]n[.]questions", "", names(simple.grades)[which(grepl("[.]n[.]questions", names(simple.grades)))])
    quizIDs <- course.summary$QuizID

    long.data <- list()

    for(i in 1:length(quizIDs)){
      temp <- simple.grades[,c(1:2, which(grepl(quizIDs[i], names(simple.grades))))]

      names(temp) <- gsub(paste0(quizIDs[i], "[.]"), "", names(temp))

      if(ncol(temp)>2){
        temp$grade <- as.numeric(temp$n.correct) / as.numeric(temp$n.questions) * 100
      }

      temp$QuizID <- quizIDs[i]

      long.data[[i]] <- temp
    }

    simple.grades <- dplyr::bind_rows(long.data)


    # due date filter

    if(duedate_filter){
      grades <-  dplyr::filter(grades, DueDate<=Sys.Date())
    }


    # generate an overall grade taking simple average of each quiz grade


    grades.summary <- dplyr::left_join(grades, simple.grades, by = c("Lastname", "Firstname", "QuizID"))

    grades.summary <- dplyr::mutate(grades.summary,
        grade.zeros = ifelse(is.na(grade), 0, as.numeric(grade)),
        n.questions = as.numeric(n_Questions),
        n.correct = ifelse(is.na(n.correct), 0, as.numeric(n.correct))
      )

    grades.summary <- dplyr::group_by(grades.summary, Lastname, Firstname)

    grades.summary <- dplyr::summarise(grades.summary,
        n.quizzes = dplyr::n(),
        n.submitted = sum(!is.na(grade)),
        n.missing = sum(is.na(grade)),
        grade = paste0(round(mean(grade.zeros), 2)),
        n.questions = paste0("TOTQs = ", sum(n.questions, na.rm = TRUE)),
        n.correct = paste0("TOTcorrect = ", sum(n.correct, na.rm = TRUE))
      )

    grades.summary <- dplyr::ungroup(grades.summary)

    grades.summary <- dplyr::mutate(grades.summary,
        n.questions = paste0("TOTQs = ", max(as.numeric(gsub("[^0-9]{1-3}", "", n.questions)), na.rm=TRUE)),
        by.question.avg = round(100*as.numeric(gsub("[^0-9]{1-3}", "", n.correct))/as.numeric(gsub("[^0-9]{1-3}", "", n.questions)), 2)
      )




    if(grades_type == "overview"){return(grades.summary)}


    ## hard code add to line list grades for simple viewing of average alongside individual grades
    simple.grades <-  dplyr::mutate(simple.grades, grade = round(grade, 2))
    simple.grades <-  lapply(simple.grades, as.character)
    simple.grades <-  dplyr::bind_rows(simple.grades, grades.summary)
    simple.grades <-  dplyr::arrange(simple.grades, Lastname, Firstname)
    simple.grades <-  dplyr::mutate_all(simple.grades, ~as.character(.))

    ## add placeholder
    simple.grades <- dplyr::add_row(simple.grades, .before = 1)
    simple.grades[1,] <- as.list(toupper(names(simple.grades)))



    if(grades_type == "student"){return(simple.grades)}

    }


  if(grades_type == "question"){
    questions <- submissions[,which(grepl("q[0-9]{1,2}", names(submissions)))]

    questions.summary <- lapply(questions, function(x){return(list(Number.Correct = sum(x=="Correct", na.rm = TRUE), Number.Responses = sum(!is.na(x)),Percentage.Correct = round(sum(x=="Correct", na.rm = TRUE)/sum(!is.na(x))*100, 2)))})

    questionID <- names(questions.summary)
    quizID <- gsub("(.+?)\\..*", "\\1", questionID)

    questions.summary <- dplyr::bind_cols(quizID = quizID, questionID = questionID, dplyr::bind_rows(questions.summary))

    }

}
