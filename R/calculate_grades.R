#' @title Generate a summary of all quizzes in the course
#'
#' @description This function creates a dataframe summarizing the quizzes in the course.
#'
#' @param courselocation parent folder for all course directories
#' @param grades_type one of c("overview", "student", "question")
#' @param duedate_filter logical indicating whether to output statistics for past quizzes only
#'
#' @return
#' If things went well, a dataframe containing a summary of all quizzes.
#' Otherwise an error message is returned.
#' @export




#######################################################


calculate_grades <- function(courselocation, grades_type="overview", duedate_filter=FALSE)
{

  # aggregate all submissions to a single tibble
  submissions <- quizgrader::compile_submissions(courselocation)


  if(grades_type %in% c("overview", "student")){

    # load course summary and studentlist to have complete data shell regardless of missing submissions
    if(!fs::file_exists(fs::path(courselocation, "course_summary.xlsx"))){
      quizgrader::summarize_course(courselocation)
    }

    course.summary <- readxl::read_xlsx(fs::path(courselocation, "course_summary.xlsx"))
    studentlist <- quizgrader::read_studentlist(fs::path(courselocation, "studentlists"))

    grades.scaffold <- expand.grid(QuizID = course.summary$QuizID, StudentID = studentlist$StudentID)

    grades <- dplyr::full_join(studentlist, full_join(course.summary, grades.scaffold, by = "QuizID"), by = "StudentID")



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

    simple.grades <- bind_rows(long.data)


    # due date filter

    if(duedate_filter){
      grades <- grades %>% filter(DueDate<=Sys.Date())
    }


    # generate an overall grade taking simple average of each quiz grade


    grades.summary <- dplyr::left_join(grades, simple.grades, by = c("Lastname", "Firstname", "QuizID")) %>%
      dplyr::mutate(
        grade.zeros = ifelse(is.na(grade), 0, as.numeric(grade)),
        n.questions = as.numeric(n_Questions),
        n.correct = ifelse(is.na(n.correct), 0, as.numeric(n.correct))
      ) %>%

      group_by(Lastname, Firstname) %>%

      dplyr::summarise(
        n.quizzes = n(),
        n.submitted = sum(!is.na(grade)),
        n.missing = sum(is.na(grade)),
        grade = paste0(round(mean(grade.zeros), 2)),
        n.questions = paste0("TOTQs = ", sum(n.questions, na.rm = TRUE)),
        n.correct = paste0("TOTcorrect = ", sum(n.correct, na.rm = TRUE))
      ) %>%

      dplyr::ungroup() %>%

      dplyr::mutate(
        n.questions = paste0("TOTQs = ", max(as.numeric(gsub("[^0-9]{1-3}", "", n.questions)), na.rm=TRUE)),
        by.question.avg = round(100*as.numeric(gsub("[^0-9]{1-3}", "", n.correct))/as.numeric(gsub("[^0-9]{1-3}", "", n.questions)), 2)
      )




    if(grades_type == "overview"){return(grades.summary)}

    # ui <- shinyUI(
    #   fluidPage(
    #     verbatimTextOutput("Class Summary from Classlist"),
    #     DT::dataTableOutput("Class Summary by classlist")
    #   )
    # )
    #
    #
    # server <- shinyServer(function(input, output, session) {
    #   output$`Class Summary by classlist` <- DT::renderDataTable({
    #     return(DT::datatable(grades.summary, class = "cell-border stripe", rownames = FALSE, filter = "top", extensions = "Buttons", options = list(dom = "Bfrtip", buttons = c("copy", "csv", "excel", "pdf", "print"), pageLength = 30)) )
    #   })
    # }
    # )

    ## hard code add to line list grades for simple viewing of average alongside individual grades
    simple.grades <- simple.grades %>% mutate(grade = round(grade, 2)) %>% lapply(as.character) %>% bind_rows(grades.summary) %>% arrange(Lastname, Firstname) %>% mutate_all(~as.character(.))

    ## add placeholder
    simple.grades <- simple.grades %>% add_row(.before = 1)
    simple.grades[1,] <- as.list(toupper(names(simple.grades)))



    if(grades_type == "student"){return(simple.grades)}

    # ui <- shinyUI(
    #   fluidPage(
    #     selectInput("Student Name","Choose a student to view grades.",
    #                 choices = unique(paste0(simple.grades$Lastname, ", ", simple.grades$Firstname)),
    #                 selected = "LASTNAME, FIRSTNAME"),
    #     DT::dataTableOutput("Student Grades")
    #   )
    # )
    #
    # server <- shinyServer(function(input, output, session) {
    #   # reactiveData <- reactive({
    #   #   return(simple.grades %>% filter(email == input$`Student Email`) %>% select(lastname, firstname, QuizID, duedate, grade, n.questions, n.correct, by.q.avg, n.quizzes, n.submitted, n.missing))
    #   #   })
    #   reactiveData <- reactive({
    #     return(simple.grades %>% filter(paste0(Lastname, ", ", Firstname) == input$`Student Name`) %>% select(Lastname, Firstname, QuizID, grade, n.questions, n.correct, by.q.avg, n.quizzes, n.submitted, n.missing))
    #   })
    #   output$`Student Grades` <- DT::renderDataTable({
    #     return(DT::datatable(reactiveData(), class = "cell-border stripe", rownames = FALSE, filter = "top", extensions = "Buttons", options = list(dom = "Bfrtip", buttons = c("copy", "csv", "excel", "pdf", "print"), pageLength = 30)) )
    #   })
    # }
    # )


    }


  if(grades_type == "question"){
    questions <- submissions[,which(grepl("q[0-9]{1,2}", names(submissions)))]

    questions.summary <- lapply(questions, function(x){return(list(Number.Correct = sum(x=="Correct", na.rm = TRUE), Number.Responses = sum(!is.na(x)),Percentage.Correct = round(sum(x=="Correct", na.rm = TRUE)/sum(!is.na(x))*100, 2)))})

    questionID <- names(questions.summary)
    quizID <- gsub("(.+?)\\..*", "\\1", questionID)

    questions.summary <- bind_cols(quizID = quizID, questionID = questionID, bind_rows(questions.summary))




    # ui <- shinyUI(
    #   fluidPage(
    #     selectInput("Quiz ID","Choose a Quiz ID to view a summary.",
    #                 choices = c("ALL", unique(questions.summary$quizID)),
    #                 selected = "ALL"),
    #     DT::dataTableOutput("Questions Summary")
    #   )
    # )
    #
    # server <- shinyServer(function(input, output, session) {
    #   reactiveData <- reactive({
    #     if(input$`Quiz ID`=="ALL"){return(questions.summary)}else{return(subset(questions.summary, quizID == input$`Quiz ID`))}
    #   })
    #   output$`Questions Summary` <- DT::renderDataTable({
    #     return(DT::datatable(reactiveData(), class = "cell-border stripe", rownames = FALSE, filter = "top", extensions = "Buttons", options = list(dom = "Bfrtip", buttons = c("copy", "csv", "excel", "pdf", "print"), pageLength = 30)) )
    #   })
    # }
    # )
    }

}
