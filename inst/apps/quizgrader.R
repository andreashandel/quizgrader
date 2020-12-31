######################################################
# This app is part of quizgrader
# it provides the web interface where students upload their submissions
# The app/package auto-grades the submissions and provides feedback
######################################################



#######################################################
#general setup
#######################################################

solution_raw <- NULL
submission_raw <- NULL

classlist_folder = here('classlist') #path and name of file that contains class roster
solution_folder = here('complete_solution_sheets')
submission_folder = here('submissions')

#######################################################
#general helper functions, non-reactive
#######################################################



#######################################################
#check that metadata are correct
#specifically, check that name and email are valid, i.e. exist in class roster
check_metadata <- function(metadata,studentid,classlist)
{
   metaerror = NULL

   #name check not really needed, just an extra check if wanted
   #disable for now since some students have different last names in system versus in real life (recent name change)
   #email is unique match, so name match not really needed
   # if ( metadata$lastname != classlist$lastname[studentid])
   # {
   #  metaerror <- "Name does not match"
   #  return(metaerror)
   # }

   #find the row for this user, check that they have a password set
   if ( nchar(classlist$password[studentid])==0)
   {
     metaerror <- "It seems like you have not provided a password, please do so."
     return(metaerror)
   }

   #find the row for this user, check if their password is correct
   #this can prevent anyone submitting for someone else (unless that person shared their password)
   #ignore capitalization for password
   if ( metadata$password != tolower(classlist$password[studentid]))
   {
       metaerror <- "Password does not match"
       browser()
       return(metaerror)
   }
   return(metaerror)

} #end function that checks metadata





#######################################################
#write grade to classlist file
#append date, such that files don't overwrite each other
save_grade <- function(score, studentid, quizid, classlist_folder)
{
  classlist = read_classlist(classlist_folder)
  gradecol = which(colnames(classlist) == paste0(quizid,"_grade"))
  classlist[studentid,gradecol] <- score
  submitcol = which(colnames(classlist) == paste0(quizid,"_submitdate"))
  classlist[studentid,submitcol] <- as.character(Sys.time())
  timestamp = gsub(" ","_",gsub("-","_", gsub(":", "_", Sys.time())))
  filename = paste0("classlist_",timestamp,".tsv")
  classlistfile = paste0(classlist_folder,"/",filename)
  write.table(classlist,classlistfile, sep = '\t', col.names = TRUE, row.names = FALSE )
} #end function that writes to file




#######################################################
#UI for shiny app
#######################################################

ui <- fluidPage(
        shinyjs::useShinyjs(),
        titlePanel("Quiz grader"),
        #h2('Grading app is not yet available, I am still missing some passwords. I will announce when it is available.'),
        textInput("lastname","Last Name"),
        textInput("email","Email"),
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

#######################################################
#server part for shiny app
#######################################################

server <- function(input, output) {


    #######################################################
    #code that turns off submit button  unless a file is uploaded
    #######################################################
    if (is.null(submission_raw))
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
    #code that loads and processes the user input and uploaded file
    #happens once submit button is pressed
    #######################################################
    observeEvent(input$submitbutton, {


        #remove any previous submission text
        output$resulttext <- NULL
        output$statstext <- NULL

        #combine all inputs into list for checking
        #make all inputs not case sensitive
        metadata = list()
        metadata$lastname = tolower(input$lastname)
        metadata$email = tolower(input$email)
        metadata$password = tolower(input$password)

        #read classlist every time submit button is pressed to make sure it's the latest version
        classlist = read_classlist(classlist_folder)

        #get row ID/number for student by matching on email and check that it's valid
        studentid = which(metadata$email == classlist$email)
        if (length(studentid)==0)
        {
            metaerror <- "Email not found"
            showModal(modalDialog(metaerror))
            return()
        }

        #check that all other metadata is correct
        #if student is found, check name and password
        metaerror <- check_metadata(metadata,studentid,classlist)
        if (!is.null(metaerror)) #if errors occur, do not load file
        {
            showModal(modalDialog(metaerror))
            #could reset file upload, but not needed
            #shinyjs::reset(id  = "loadfile")
            #shinyjs::disable(id = "submitbutton")
            return()
        }


        #if meta-data is correct, proceed by loading submission file
        #read each column as character, is safer for comparison
        submission_raw <- try( readxl::read_excel(input$loadfile$datapath, col_types = "text"))
        if (length(submission_raw)==1) #if this is true, it means the file hasn't loaded and instead produced an error string
        {
            errormsg = "File could not be loaded, make sure it's a valid Excel file"
            showModal(modalDialog(errormsg))
            shinyjs::reset(id  = "loadfile")
            shinyjs::disable(id = "submitbutton")
            return()
        }

        #if submitted file could be loaded, process a bit
        #turn all column names to lowercase
        #note that quizID is converted to quiz_id
        #also make a data frame instead of tibble
        submission <- submission_raw %>%
                    dplyr::mutate_all(~ tidyr::replace_na(.x, "")) %>%  #don't want NA, want empty string to be consistent with TSV files
                    data.frame()

        #if all answers are blank, flag that and don't let a student submit
        if (sum(submission$Answer=="") == nrow(submission))
        {
          errormsg = "All answers are missing. Please, make sure you submit your answers."
          showModal(modalDialog(errormsg))
          shinyjs::reset(id  = "loadfile")
          shinyjs::disable(id = "submitbutton")
          return()
        }



        #check quiz ID column of uploaded file
        #needs to have a single entry and the right column name
        #note that we don't know which quiz a student submits, this will be matched with a solution file
        #an error is produced if the quizid does not correspond to a valid solution file
        if ( colnames(submission)[1] != "QuizID" || length(unique(submission$QuizID))>1)
        {
            errormsg <- "First column name must be named QuizID and onle a single QuizID entry is allowed. Blank lines are not allowed."
            showModal(modalDialog(errormsg))
            shinyjs::reset(id  = "loadfile")
            shinyjs::disable(id = "submitbutton")
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
        docerrors <- check_submission(submission,solution,studentid,quizid,classlist)

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
        #save student grade to classlist file
        #####################################
        #saves new score in time-stamped classlist file
        #creates a new classlist file with score recorded and current date
        #returns nothing
        #that extra if statement is to prevent recording for test submissions
        #otherwise one always has to go in manually to delete submission to prevent 'already submitted' message
        testusers = c("handel1","dailey1")
        if (!(tolower(input$email) %in% testusers))
        {
          save_grade(score, studentid, quizid, classlist_folder)
        }

        #####################################
        #display results
        #if no errors occurred during grading, show and record results
        output$resulttable <- shiny::renderTable(result_table)

        #show a success text
        success_text = paste0("Your submission for quiz ",quizid," has been successfully graded and recorded.")
        output$resulttext <- renderText(success_text)

        #####################################
        #also compute submission stats for student and display
        #load the latest classlist which contains the just submitted grade
        classlist = read_classlist(classlist_folder)
        #compute stats for that student
        quizstats <- compute_student_stats(studentid, quizid, classlist)
        stats_text = paste0("You have submitted ", quizstats["gradesubmissions"], " out of ",quizstats["totalquizzes"], " quizzes and your average score is ",round(quizstats["gradeaverage"],2))
        output$statstext <- shiny::renderText(stats_text)
        #some text with a note about the displayed stats
        warningtext = "Note that for these stats to be fully correct, you need to submit the theory quiz first, and the DSAIDE quizzes (if multiple) in order. Otherwise the displayed numbers will be off. However, even if the numbers here are a bit off, things are recorded correctly. If anything doesn't look right, let me know."
        output$warningtext = shiny::renderText(warningtext)

        #reset UI inputs
        submission_raw <- NULL #remove file submission
        solution_raw <- NULL #remove file submission
        shinyjs::reset(id  = "loadfile")
        shinyjs::disable(id = "submitbutton")

    }) #end the submit button code block

}

# Run the application
shinyApp(ui = ui, server = server)
