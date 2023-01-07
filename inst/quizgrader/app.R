######################################################
# This app is part of quizgrader
# it provides the web interface where students upload their submissions
# The app/package auto-grades the submissions and provides feedback
######################################################

#name of R package
packagename <- "quizgrader"

# load quizgrader package
# will contain all needed functions and package dependencies
# MAKE SURE THE VERSION INSTALLED ON THE SERVER IS THE SAME AS THE ONE
# BEING USED LOCALLY AND FROM WHICH THIS FILE COMES
library(packagename, character.only = TRUE)

#######################################################
#general setup
#######################################################

submission_original <- NULL #the uploaded file

#paths to the different folders
studentlist_folder = ('./studentlist')
gradelist_folder = ('./gradelist')
completequizzes_folder = ('./completequizzes')
studentsubmissions_folder = ('./studentsubmissions')

#names of all complete quizzes
completequiz_names = list.files(path = completequizzes_folder, recursive=FALSE, pattern = "\\.xlsx$", full.names = FALSE)
completequiz_ids = stringr::str_replace(completequiz_names,"_complete.xlsx","") #get only part that is name of quiz

#a vector of user IDs who can submit unlimited times and independent of due dates. Potentially good for test users.
testusers = c("ahandel@uga.edu","test")

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
            output$scoretext <- NULL
            output$warningtext <- NULL
            #and tables
            output$currenttable <- NULL
            output$historytable <- NULL
            output$scoretable <- NULL

    })


  #######################################################
  #code that runs when user presses the 'get scores' button
  #######################################################
  observeEvent(input$scoresbutton, {


    #remove any previous submission text
    output$currenttext <- NULL
    output$historytext <- NULL
    output$scoretext <- NULL
    output$warningtext <- NULL
    #and table
    output$currenttable <- NULL
    output$historytable <- NULL
    output$scoretable <- NULL

    #combine all inputs into list for checking
    #make all inputs lower case and trim any white space
    #note that list entries need this specific capitalization
    metadata = list()
    metadata$StudentID = trimws(tolower(input$StudentID))
    metadata$Password = trimws(tolower(input$Password))

    #read student list every time submit button is pressed to make sure it's the latest version
    studentlist <- readxl::read_xlsx(fs::dir_ls(fs::path(studentlist_folder)), col_types = "text", col_names = TRUE)

    #check that provided student ID and password are correct and can be matched with entry in studentlist
    #if student is found, check name and password
    metaerror <- quizgrader::check_metadata(metadata, studentlist)
    if (!is.null(metaerror)) #if errors occur, stop the process with an error message
    {
      show_error(metaerror)
      return()
    }

    #####################################
    #compute submission stats for student and display them
    #####################################
    #read previous most recent log file of submissions
    listfiles <- fs::dir_info(fs::path(studentsubmissions_folder,"logs"))
    #load the most recent one, which is the one to be used
    filenr = which.max(listfiles$modification_time) #find most recently changed file
    submissions_log <- readxl::read_xlsx(listfiles$path[filenr], col_types = "text", col_names = TRUE)

    log_table <- dplyr::filter(submissions_log, StudentID == metadata$StudentID)
    log_table$Score <- as.numeric(log_table$Score) #convert to numeric so we can round
    output$historytable <- shiny::renderTable(log_table, digits = 1)

    historytext = "The table below shows your complete quiz submission history."
    output$historytext <- shiny::renderText(historytext)

    scoretext = "If available, the table below shows scores from other assignments."
    output$scoretext <- shiny::renderText(scoretext)

    #some text with a note about the displayed stats
    warningtext = "If anything doesn't look right, let your instructor know."
    output$warningtext = shiny::renderText(warningtext)

    #####################################
    #show additional scores if they exist
    #####################################
    gradelistfile = fs::dir_ls(fs::path(gradelist_folder))
    if (fs::file_exists(gradelistfile))
    {
      #load list with other grades
      gradelist <- readxl::read_xlsx(gradelistfile, col_types = "text", col_names = TRUE)
      #get entry for current student
      other_grades <- dplyr::filter(gradelist, StudentID == metadata$StudentID)
      #return other scores as table
      output$scoretable <- shiny::renderTable(other_grades)
    }


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
      output$scoretable <- NULL

        #combine all inputs into list for checking
        #make all inputs lower case and trim any white space
        #note that list entries need this specific capitalization
        metadata = list()
        metadata$StudentID = trimws(tolower(input$StudentID))
        metadata$Password = trimws(tolower(input$Password))

        #read student list every time submit button is pressed to make sure it's the latest version
        studentlist <- readxl::read_xlsx(fs::dir_ls(fs::path(studentlist_folder)), col_types = "text", col_names = TRUE)

        #check that supplied student ID and password are correct and can be matched with entry in studentlist
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
        #skip check for test users
        #count number of files that exist for that student to determine number of already taken attempts
        n_attempts <- length(fs::dir_ls(path = fs::path(studentsubmissions_folder, quizid),
                                        regexp = paste0(metadata$StudentID, "_.*?_", quizid, "_submission[.]xlsx")
                                        )
                             )
        if ( !(metadata$StudentID %in% testusers))
        {

          #check that submission is before due data
          if (Sys.Date() > solution$DueDate[1]) #if this is true, it means the due date has passed
          {
            errormsg = "Quiz submission is no longer permitted as the due date has passed."
            show_error(errormsg)
            return()
          }
          if (n_attempts >= solution$Attempts[1]) #if this is true, it means max number of attempts is reached
          {
            errormsg = "You have already submitted the maximum number of attempts."
            show_error(errormsg)
            return()
          }
        }

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
        submission <- data.frame(dplyr::mutate_all(submission_original, ~ tidyr::replace_na(.x, "")))

        #check submitted file against solution to make sure content is right
        #if file is not right, this will return an error message
        #then display error message and stop the process
        filecheck <- quizgrader::check_submission(submission, quizid)
        if (!is.null(filecheck))
        {
          show_error(filecheck)
          return()
        }

        #if all seems  ok, we can go ahead and grade
        result_table <- quizgrader::grade_quiz(submission,solution)
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
        submission_filename = paste(metadata$StudentID, timestamp, quizid, 'submission.xlsx', sep='_')
        submission_filenamepath = fs::path(studentsubmissions_folder, quizid, submission_filename)
        writexl::write_xlsx(submission, submission_filenamepath, col_names = TRUE, format_headers = TRUE)


        #####################################
        #also create a single log file that has the summary of each submissions for record keeping
        #log files will be kept and new ones created
        #####################################

        #log entry to be recorded
        new_submission_log <- dplyr::bind_cols(StudentID = metadata$StudentID,
                                               QuizID = quizid,
                                               QuizDueDate = solution$DueDate[1],
                                               Attempt = n_attempts+1,
                                               Score = score,
                                               n_Questions = nrow(result_table),
                                               n_Correct = sum(result_table$Score == "Correct"),
                                               Submit_Date = Sys.Date()
                                               )
        new_submission_log <- dplyr::mutate_all(new_submission_log, as.character)

        #name for new file, corresponds to time stamp above
        submissions_log_filenamepath = fs::path(studentsubmissions_folder, "logs", paste0("submissions_log_", timestamp, ".xlsx"))

        #read previous most recent log file of submissions
        listfiles <- fs::dir_info(fs::path(studentsubmissions_folder,"logs"))
        #load the most recent one, which is the one to be used
        filenr = which.max(listfiles$modification_time) #find most recently changed file
        submissions_log <- readxl::read_xlsx(listfiles$path[filenr], col_types = "text", col_names = TRUE)
        #append new submission log entry
        submissions_log <- dplyr::bind_rows(submissions_log, new_submission_log)
        #write a new log file with the current submission appended
        writexl::write_xlsx(submissions_log, submissions_log_filenamepath, col_names = TRUE, format_headers = TRUE)

        #####################################
        #display results
        #if no errors occurred during grading, show and record results
        output$currenttable <- shiny::renderTable(cbind(result_table, Feedback = solution$Feedback))

        #show a success text
        success_text = paste0("Your submission for quiz ",quizid," has been successfully graded and recorded. \n The table below shows detailed feedback for each question.")
        output$currenttext <- renderText(success_text)

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
  br(),
  tags$div(id = "shinyheadertitle", "quizgrader - an R package for automated submission, grading and analysis of quizzes."),
  tags$div(id = "infotext", paste0('This is ', packagename,  ' version ',utils::packageVersion(packagename),' last updated ', utils::packageDescription(packagename)$Date,'.')),
  tags$div(id = "infotext", "Written and maintained by", a("Andreas Handel", href="https://www.andreashandel.com", target="_blank"), "with contributions from", a("others.",  href="https://andreashandel.github.io/quizgrader/authors.html", target="_blank")),
  br(),
  fluidRow(
       column(12,
              align = "center",
              textInput("StudentID","Student ID")
              ),
        class = "mainmenurow"
        ),
  fluidRow(
    column(12,
           align = "center",
           textInput("Password","Password")
          ),
      class = "mainmenurow"
    ),
  fluidRow(
    column(12,
          align = "center",
          h4("Submit a new file"),
          fileInput("loadfile", label = "", accept = ".xlsx", buttonLabel = "Upload file", placeholder = "No file selected"),
          actionButton("submitbutton", "Submit file", class = "mainbutton")
    ),
    class = "mainmenurow"
  ), #close fluidRow structure for input
  br(),
  fluidRow(
    column(12,
         align = "center",
        h4("Check scores"),
        actionButton("scoresbutton", "Check scores", class = "mainbutton")
    ),
    class = "mainmenurow"
  ), #close fluidRow structure for input
  fluidRow(
    column(12,
           align = "center",
           h3(textOutput("currenttext")),
           br(),
           tableOutput("currenttable"),
           br(),
           h3(textOutput("historytext")),
           tableOutput("historytable"),
           br(),
           h3(textOutput("scoretext")),
           tableOutput("scoretable"),
    ),
    class = "mainmenurow"
  ), #close fluidRow structure for output

) # close fluidpage


# Run the application
shinyApp(ui = ui, server = server)
