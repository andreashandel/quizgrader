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
gradelists_folder = ('./gradelists')
completequizzes_folder = ('./completequizzes')
studentsubmissions_folder = ('./studentsubmissions')


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
            output$resulttext <<- NULL

    })

    #######################################################
    #main code
    #loads and processes the user input and uploaded file
    #happens once submit button is pressed
    #######################################################
    observeEvent(input$submitbutton, {

        #remove any previous submission text
        output$resulttext <- NULL
        output$statstext <- NULL

        #combine all inputs into list for checking
        #make all inputs lower case
        metadata = list()
        metadata$StudentID = tolower(input$userid)
        metadata$Password = tolower(input$password)

        #read gradelist every time submit button is pressed to make sure it's the latest version
        gradelist = read_gradelist(gradelists_folder)

        #check that student ID and password are correct and can be matched
        #if student is found, check name and password
        metaerror <- check_metadata(metadata, gradelist)
        if (!is.null(metaerror)) #if errors occur, do not load file
        {
          show_error(metaerror)
          return()
        }


        #if meta-data is correct, proceed by loading the file
        #the student just submitted
        #read each column as character, is safer for comparison
        submission_original <- try( readxl::read_excel(input$loadfile$datapath, col_types = "text"))
        if (length(submission_original)==1) #if this is true, it means the file hasn't loaded and instead produced an error string
        {
            errormsg = "File could not be loaded, make sure it's a valid Excel file"
            show_error(errormsg)
            return()
        }

        #if submitted file could be loaded, process a bit
        #also make a data frame instead of tibble
        submission <- submission_original %>%
                    dplyr::mutate_all(~ tidyr::replace_na(.x, "")) %>%
                    data.frame()

        #if all answers are blank, flag that and don't let a student submit
        if (sum(submission$Answer=="") == nrow(submission))
        {
          errormsg = "All answers are missing. Please, make sure you submit your answers."
          show_error(errormsg)
          return()
        }

        #check quiz ID column of uploaded file
        #needs to have a single entry and the right column name
        #note that we don't know which quiz a student submits, this will be matched with a solution file
        #an error is produced if the quizid does not correspond to a valid solution file
        if ( colnames(submission)[1] != "QuizID" || length(unique(submission$QuizID))>1)
        {
            errormsg <- "First column name must be named QuizID and onle a single QuizID entry is allowed. Blank lines are not allowed."
            show_error(errormsg)
            return()
        }

        #save quiz ID
        quizid = tolower(unique(submission$QuizID))

        # load the solution file for this quiz with the answers
        # test if it can be loaded
        # for it to work the quizid in the submitted sheet must have a name that matches a solution
        solutionname = paste0(solution_folder,'/', quizid,'_complete.xlsx')

        solution_raw <- try( readxl::read_excel(solutionname, col_types = "text"))
        if (length(solution_raw)==1) #if this is true, it means the file hasn't loaded and instead produced an error string
        {
          errormsg = "Matching solution file could not be loaded, this could mean your QuizID is wrong."
          showModal(modalDialog(errormsg))
          shinyjs::reset(id  = "loadfile")
          shinyjs::disable(id = "submitbutton")
          return()
        }
        #if loading worked, do a bit of cleaning
        solution <- solution_raw %>%
          dplyr::mutate_all(~ tidyr::replace_na(.x, "")) %>%  #don't want NA, want empty string to be consistent with TSV files
          data.frame()

        #check uploaded file for any other problems
        docerrors <- check_submission(submission,solution,studentid,quizid,gradelist)

        if (!is.null(docerrors)) #if errors occur, show them
        {
            showModal(modalDialog(docerrors))
            shinyjs::reset(id  = "loadfile") #clear out the file upload field
            shinyjs::disable(id = "submitbutton") #disable submission until new file is uploaded
            return()
        }

        #grade things and show results
        result_table <- grade_quiz(submission,solution)
        # if an error occurs during grading, result_table will contain the error message as a string
        if (is.character(result_table))
        {
          showModal(modalDialog(result_table))
          shinyjs::reset(id  = "loadfile") #clear out the file upload field
          shinyjs::disable(id = "submitbutton") #disable submission until new file is uploaded
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
        filename = paste(input$lastname, input$email, timestamp, quizid, 'submission.tsv', sep='_')
        filenamepath = paste0(submission_folder,"/",filename)
        write.table(submission, file=filenamepath, sep = '\t', col.names = TRUE, row.names = FALSE )

        #####################################
        #save student grade to gradelist file
        #####################################
        #saves new score in time-stamped gradelist file
        #creates a new gradelist file with score recorded and current date
        #returns nothing
        #that extra if statement is to prevent recording for test submissions
        #otherwise one always has to go in manually to delete submission to prevent 'already submitted' message
        save_grade(score, studentid, quizid, gradelist_folder)

        #####################################
        #display results
        #if no errors occurred during grading, show and record results
        output$resulttable <- shiny::renderTable(result_table)

        #show a success text
        success_text = paste0("Your submission for quiz ",quizid," has been successfully graded and recorded.")
        output$resulttext <- renderText(success_text)

        #####################################
        #also compute submission stats for student and display
        #load the latest gradelist which contains the just submitted grade
        gradelist = read_gradelist(gradelist_folder)
        #compute stats for that student
        quizstats <- compute_student_stats(studentid, quizid, gradelist)
        stats_text = paste0("You have submitted ", quizstats["gradesubmissions"], " out of ",quizstats["totalquizzes"], " quizzes and your average score is ",round(quizstats["gradeaverage"],2))
        output$statstext <- shiny::renderText(stats_text)
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
  textInput("userid","User ID"),
  textInput("password","Password"),
  fileInput("loadfile", label = "", accept = ".xlsx", buttonLabel = "Upload file", placeholder = "No file selected"),
  actionButton("submitbutton", "Submit file", class = "submitbutton"),
  br(),
  tableOutput("resulttable"),
  br(),
  h2(textOutput("resulttext")),
  br(),
  h3(textOutput("statstext")),
  br(),
  p(textOutput("warningtext"))
)


# Run the application
shinyApp(ui = ui, server = server)
