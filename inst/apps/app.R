######################################################
# This app is part of quizgrader
# it provides the web interface where students upload their submissions
# The app/package auto-grades the submissions and provides feedback
######################################################

library('quizgrader')

#######################################################
#general setup
#######################################################

submission_original <- NULL #the uploaded file

#paths to the different folders
# gradelists_folder = ('./gradelists')
studentlists_folder = ('./studentlists')
completequizzes_folder = ('./completequizzes')
studentsubmissions_folder = ('./studentsubmissions')

#names of all complete quizzes
completequiz_names = list.files(path = completequizzes_folder, recursive=FALSE, pattern = "\\.xlsx$", full.names = FALSE)
completequiz_ids = stringr::str_replace(completequiz_names,"_complete.xlsx","") #get only part that is name of quiz

#######################################################
#small functions not worth sticking into their own files
#######################################################

show_error <- function(errormsg)
{
  showModal(modalDialog(errormsg))
  shinyjs::reset(id  = "loadfile")
  shinyjs::disable(id = "submitbutton")
}





#######################################################
#server part for shiny app
#######################################################

server <- function(input, output) {


    #######################################################
    #code that turns off submit button unless a file is uploaded
    #######################################################
    if (is.null(submission_original))
    {
      shinyjs::reset(id  = "loadfile") #clear out the file upload field
      shinyjs::disable(id = "submitbutton")
    }

    #######################################################
    #code that runs when user presses the load file button
    #turns on submit button only if file is uploaded
    #######################################################
    observeEvent(input$loadfile, {
            shinyjs::enable(id = "submitbutton")
            #remove any previous submission text
            output$currenttext <- NULL
            output$historytext <- NULL
            output$warningtext <- NULL
            #and table
            output$currenttable <- NULL
            output$historytable <- NULL

    })

    #######################################################
    #main code
    #loads and processes the user input and uploaded file
    #happens once submit button is pressed
    #######################################################
    observeEvent(input$submitbutton, {

      #remove any previous submission text
      output$currenttext <- NULL
      output$historytext <- NULL
      output$warningtext <- NULL
      #and table
      output$currenttable <- NULL
      output$historytable <- NULL

        #combine all inputs into list for checking
        #make all inputs lower case
        #note that list entries need this specific capitalization
        metadata = list()
        metadata$StudentID = tolower(input$StudentID)
        metadata$Password = tolower(input$Password)


        #read gradelist every time submit button is pressed to make sure it's the latest version
        # gradelist = quizgrader::read_gradelist(gradelists_folder)
        studentlist = quizgrader::read_studentlist(studentlists_folder)
        #check that student ID and password are correct and can be matched with entry in gradelist
        #if student is found, check name and password
        metaerror <- quizgrader::check_metadata(metadata, studentlist)
        if (!is.null(metaerror)) #if errors occur, stop the process with an error message
        {
          show_error(metaerror)
          return()
        }

        #if student ID and password are a match,
        #check that quizid part of file name of student submission
        #matches one of the quizid file names of the complete solution files
        quizid = stringr::str_replace(input$loadfile$name,"_student.xlsx","")
        if( !(quizid %in% completequiz_ids))
        {
          errormsg = "Your submitted file has the wrong name, please do not rename the provided files."
          show_error(errormsg)
          return()
        }



        # load the solution file for this quiz with the answers
        # test if it can be loaded
        # for it to work the quizid in the submitted sheet must have a name that matches a solution
        solutionname = paste0(completequizzes_folder,'/', quizid,'_complete.xlsx')

        solution_raw <- try( readxl::read_excel(solutionname, col_types = "text"))
        if (length(solution_raw)==1) #if this is true, it means the file hasn't loaded and instead produced an error string
        {
          errormsg = "Matching solution file could not be loaded. Please inform your instructor."
          show_error(errormsg)
          return()
        }

        #if loading worked, do a bit of cleaning
        #replace any potential NA with "" for consistency
        #also make a data frame instead of tibble
        #this should work on any excel file (even if student submits a non-quiz)
        #therefore do this before quiz format check
        #don't want NA, want empty string for consistentcy
        solution <- data.frame(dplyr::mutate_all(solution_raw, ~ tidyr::replace_na(.x, "")))


        #check due date and check attempts

        if (Sys.Date() > solution$DueDate[1]) #if this is true, it means the due date has passed
        {
          errormsg = "Quiz submission is no longer permitted as the due date has passed."
          show_error(errormsg)
          return()
        }

        n_attempts <- length(list.files(path = fs::path(studentsubmissions_folder, quizid),
                                      pattern = paste0(input$StudentID, "_.*?_", quizid, "_submission[.]xlsx")
                                     )
                          )

        #a bit of extra code to allow some users (teacher/testers) to submit as many times as they want
        #if not wanted, disable/uncomment
        if ( !(metadata$StudentID %in% c("ahandel@uga.edu","daileyco@uga.edu","wesley.billings@uga.edu")))
        {
          if (n_attempts >= solution$Attempts[1]) #if this is true, it means the due date has passed
          {
            errormsg = "You have already submitted the maximum number of attempts."
            show_error(errormsg)
            return()
          }
        }

        this_attempt <- n_attempts + 1





        #if file names, solution file, due date, attempt number are okay, proceed by loading the submitted file
        #read each column as character/text, this is safer for comparison
        submission_original <- try( readxl::read_excel(input$loadfile$datapath, col_types = "text"))
        if (length(submission_original)==1) #if this is true, it means the read_excel failed and instead produced an error string
        {
            errormsg = "File could not be loaded, make sure it's a valid Excel file"
            show_error(errormsg)
            return()
        }

        #if submitted file could be loaded, process a bit
        #replace any potential NA with "" for consistency
        #also make a data frame instead of tibble
        #this should work on any excel file (even if student submits a non-quiz)
        #therefore do this before quiz format check
        #submission <- submission_original %>%
        #  dplyr::mutate_all(~ tidyr::replace_na(.x, "")) %>%
        #  data.frame()
        submission <- data.frame(dplyr::mutate_all(submission_original, ~ tidyr::replace_na(.x, "")))



        #check submitted file against solution to make sure content is right
        #if file is not right, check_submission will return an error message
        #then display error message and stop the process
        filecheck <- quizgrader::check_submission(submission, quizid)
        #docerrors <- check_submission(submission,solution,studentid,quizid,gradelist)
        if (!is.null(filecheck))
        {
          show_error(filecheck)
          return()
        }



        #if all seems  ok, we can go ahead and grade
        result_table <- grade_quiz(submission,solution)
        # if an error occurs during grading, result_table will contain the error message as a string
        if (is.character(result_table))
        {
          show_error(result_table)
          return()
        }


        #compute score for submission
        score = sum(result_table$Score == "Correct")/nrow(result_table)*100



        #####################################
        #write the submission to a file for record keeping
        #####################################
        #filename contains student email, date and quiz ID
        #this allows checking if things in the app go wrong
        #give each submission a time-stamp
        timestamp = gsub(" ","_",gsub("-","_", gsub(":", "_", Sys.time())))
        submission_filename = paste(input$StudentID, timestamp, quizid, 'submission.xlsx', sep='_')
        submission_filenamepath = fs::path(studentsubmissions_folder, quizid, submission_filename)
        writexl::write_xlsx(submission, submission_filenamepath, col_names = TRUE, format_headers = TRUE)


        new_submission_log <- dplyr::bind_cols(StudentID = input$StudentID,
                                               QuizID = quizid,
                                               Attempt = this_attempt,
                                               Score = score,
                                               n_Questions = nrow(result_table),
                                               n_Correct = sum(result_table$Score == "Correct"),
                                               Submit_Date = Sys.Date()#,
                                               #tidyr::pivot_wider(result_table, names_from = "QuestionID", values_from = "Score")
                                               )

        new_submission_log <- dplyr::mutate_all(new_submission_log, as.character)

        submissions_log <- quizgrader::read_submissions_log(studentsubmissions_folder)

        submissions_log <- dplyr::bind_rows(submissions_log, new_submission_log)

        submissions_log_filename = paste0("submissions_log_", timestamp, ".xlsx")
        submissions_log_filenamepath = fs::path(studentsubmissions_folder, "logs", submissions_log_filename)
        writexl::write_xlsx(submissions_log, submissions_log_filenamepath, col_names = TRUE, format_headers = TRUE)


        # log_filename <- paste("log", input$StudentID, quizid, "attempt", paste0(this_attempt, ".txt"), sep = "_")
        # log_filenamepath = fs::path(studentsubmissions_folder, quizid, log_filename)
        # write.table(submission_log, file = log_filenamepath, sep = '\t', col.names = TRUE, row.names = FALSE, quote = FALSE)


        #####################################
        #save student grade to gradelist file
        #####################################
        #saves new score in time-stamped gradelist file
        #creates a new gradelist file with score recorded and current date
        #returns nothing
        #that extra if statement is to prevent recording for test submissions
        #otherwise one always has to go in manually to delete submission to prevent 'already submitted' message
        # save_grade(score, input$StudentID, quizid, gradelist, gradelists_folder)

        #####################################
        #display results
        #if no errors occurred during grading, show and record results
        output$currenttable <- shiny::renderTable(cbind(result_table, Feedback = solution$Feedback))

        #show a success text
        success_text = paste0("Your submission for quiz ",quizid," has been successfully graded and recorded. \n The table below shows detailed feedback for each question.")
        output$currenttext <- renderText(success_text)


        #####################################
        #also compute submission stats for student and display

        log_table <- dplyr::filter(submissions_log, StudentID == input$StudentID)
        output$historytable <- shiny::renderTable(log_table, digits = 1)

        quiz_stats <- dplyr::filter(dplyr::group_by(log_table, QuizID), Attempt == which.max(Attempt))

        quiz_stats <- dplyr::summarise(dplyr::ungroup(quiz_stats), n_Quizzes = dplyr::n(), Average_Score = mean(as.numeric(Score)))

        historytext = "The table below shows your complete quiz submission history."
        output$historytext <- shiny::renderText(historytext)



        #load the latest gradelist which contains the just submitted grade
        # gradelist = quizgrader::read_gradelist(gradelists_folder)
        #compute stats for that student
        # quizstats <- compute_student_stats(input$StudentID, quizid, gradelist)
        # stats_text = paste0("You have submitted ", quizstats["gradesubmissions"], " out of ",quizstats["totalquizzes"], " quizzes and your average score is ",round(quizstats["gradeaverage"],2))
        # output$statstext <- shiny::renderText(stats_text)
        #some text with a note about the displayed stats
        warningtext = "If anything doesn't look right, let your instructor know."
        output$warningtext = shiny::renderText(warningtext)

        #reset UI inputs
        submission_original <- NULL #remove file submission
        shinyjs::reset(id  = "loadfile")
        shinyjs::disable(id = "submitbutton")

    }) #end the submit button code block

}


#######################################################
#UI for shiny app
#######################################################

ui <- fluidPage(
  shinyjs::useShinyjs(),
  includeCSS("quizgrader.css"), #use custom styling
  titlePanel("Quiz grader"),
  textInput("StudentID","Student ID"),
  textInput("Password","Password"),
  #h3('Quiz submission not yet enabled.'),
  fileInput("loadfile", label = "", accept = ".xlsx", buttonLabel = "Upload file", placeholder = "No file selected"),
  actionButton("submitbutton", "Submit file", class = "submitbutton"),
  br(),
  h3(textOutput("currenttext")),
  br(),
  tableOutput("currenttable"),
  br(),
  h3(textOutput("historytext")),
  br(),
  tableOutput("historytable"),
  br(),
  h3(textOutput("warningtext"))
)


# Run the application
shinyApp(ui = ui, server = server)
