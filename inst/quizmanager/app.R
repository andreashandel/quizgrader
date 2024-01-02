######################################################
# This app is the quiz manager part of quizgrader
# It provides a frontend for instructors to manage their course quizzes
# It helps both in preparing the quizzes and analyzing student submissions
######################################################


##############################################
# Some setup
##############################################
#define some variables, define all as global (the <<- notation)
#not fully sure if the global definition is needed, but it was at some point in the development
#i'm sticking to it for now, doesn't seem to be a problem
#name of R package
packagename <- "quizgrader"
#path to templates
quiztemplatefile <- file.path(system.file("templates", package = packagename),"quiz_template.xlsx")
studentlisttemplatefile <- file.path(system.file("templates", package = packagename),"studentlist_template.xlsx")
gradelisttemplatefile <- file.path(system.file("templates", package = packagename),"gradelist_template.xlsx")

# use the variable set in quizmanager()
# either NULL for new course, or path to existing course
courselocation <<- courselocation_global
#for debugging/manual fiddling, or if I don't want to load through UI each time
courselocation <- "C:/Data/Dropbox/2024-1-spring-epid8060/quizzes/MADA2024"

#######################################################
#server part for shiny app
#######################################################

server <- function(input, output, session)
{

  ##################################################
  #Check if a course has been set/provided or not
  #based on that, disable/enable certain tabs
  ##################################################
  #disable all course related functions
  #unless a valid course location is set
  if (is.null(courselocation))
  {
    shinyjs::disable(selector = '.navbar-nav a[data-value="managecourse"')
    shinyjs::disable(selector = '.navbar-nav a[data-value="analyzesubmissions"')
  }
  if (!is.null(courselocation))
  {
    shinyjs::enable(selector = '.navbar-nav a[data-value="managecourse"')
    shinyjs::enable(selector = '.navbar-nav a[data-value="analyzesubmissions"')
    # if a course location is provided on startup
    # show it in the corresponding output field
    output$coursedir <- renderText(courselocation)
  }


  #set roots folders
  #this is taken from the shinyFilesExample() examples
  volumes <- c(Home = fs::path_home(), shinyFiles::getVolumes()())


#---------------------------------------------------------------
#---------------------------------------------------------------
# Set Course Tab
#---------------------------------------------------------------
#---------------------------------------------------------------


#---------------------------------------------------------------
# Course Creation
#---------------------------------------------------------------

  ##############################################################
  #start code block that chooses directory for new course
  ##############################################################

  #server functionality that lets user choose a folder for the new course
  #if user clicks the button to select a folder for new course
  observeEvent(input$newcoursedir, {
    shinyFiles::shinyDirChoose(input, "newcoursedir", roots = volumes, session = session, restrictions = system.file(package = "base"), allowDirCreate = FALSE)
    # not yet official course location, only once it has been created
    courselocation_tmp <- shinyFiles::parseDirPath(volumes, input$newcoursedir)
    output$newcoursedir <- renderText(courselocation_tmp)
    #output$coursedir <- renderText(courselocation_tmp)
    #turn on other tabs now that course has been selected
    shinyjs::enable(selector = '.navbar-nav a[data-value="managecourse"')
    shinyjs::enable(selector = '.navbar-nav a[data-value="analyzesubmissions"')

  })


  ##############################################################
  #start code block that creates directory skeleton structure
  ##############################################################

  #once user has entered course name and picked a folder location
  #a course can be started by clicking on 'Start new course'
  observeEvent(input$createcourse, {

    msg <- NULL
    if (input$coursename == "")
    {
      msg <- "Please choose a course name"
    }
    if (is.integer(input$newcoursedir)) #not sure why integer, but that's how the example is
    {
      msg <- "Please choose a course location"
    }

    if (is.null(msg)) #if no prior error, try to create course
    {
      #format course path into a way that can be used by create_course
      newcoursedir = shinyFiles::parseDirPath(volumes, input$newcoursedir)
      #run create_course function to make new folders and populate with files for the course
      errorlist <- quizgrader::create_course(isolate(input$coursename), isolate(newcoursedir))
      msg <- errorlist$message #message to display showing if things worked or not

      if (errorlist$status == 0) #if things worked well, assign directory to global variable
      {
        #save course folder to global variable
        courselocation <<- fs::path(isolate(newcoursedir), isolate(input$coursename))
        #show the directory to the new course
        output$coursedir <- renderText(as.character(courselocation))
      }
    }
    showModal(modalDialog(msg, easyClose = FALSE))
  }) #end create course


#---------------------------------------------------------------
# Course loading
#---------------------------------------------------------------


  ##############################################################
  #start code block that selects an existing course folder
  ##############################################################

  #this is used for working on an existing course
  observeEvent(input$coursedir, {
    shinyFiles::shinyDirChoose(input, "coursedir", roots = volumes, restrictions = system.file(package = "base"), allowDirCreate = FALSE)
    courselocation_temp <- shinyFiles::parseDirPath(volumes, input$coursedir)
    #check that course location is a valid quiz folder
    # CURRENTLY NOT WORKING, shinyDirChoose doesn't seem fully run before this code is executed
    #msg <- quizgrader::check_courselocation(courselocation_temp)
    msg <- NULL
    if (!is.null(msg))
    {
      showModal(modalDialog(msg, easyClose = FALSE))
    } else {
      #if no error, assign to courselocation
      courselocation <<- courselocation_temp
    }
    output$coursedir <- renderText(courselocation)
    #turn on other tabs now that course has been selected
    shinyjs::enable(selector = '.navbar-nav a[data-value="managecourse"')
    shinyjs::enable(selector = '.navbar-nav a[data-value="analyzesubmissions"')
  })


#---------------------------------------------------------------
#---------------------------------------------------------------
# Manage Course Tab
#---------------------------------------------------------------
#---------------------------------------------------------------

  observeEvent(input$topmenu == "managecourse",
               {
                 # if course hasn't been set or loaded, go back to set course
                 if (is.null(courselocation))
                 {
                   msg <- "Please make or load a course."
                   showModal(modalDialog(msg, easyClose = FALSE))
                   updateTabsetPanel(session, "topmenu", selected = "setcourse")
                 }
               }) #end observer listening to MANAGE course tab selection



#------------------------------------------------------
# Course Overview
#------------------------------------------------------

  #######################################################
  #start code block that generates course overview summary
  #######################################################

  observeEvent(input$showoverview,
               {
                 if (!is.null(courselocation))
                 {
                   ret <- quizgrader::summarize_course(courselocation)

                   # this means it should have worked
                   if (is.list(ret))
                   {

                     studenttext <- paste0("There are currently ", length(ret$studentids), " students enrolled in your course:\n")

                     studenttable <- data.frame(Names = ret$studentnames, UserIDs = ret$studentids)
                     if (!is.null(ret$gradelist))
                     {
                      gradelisttext <- paste0("Additional grade information for these activities is supplied:\n", paste(ret$gradelist,collapse =', '))
                     } else {
                       gradelisttext <- "No list with additional grade information is currently supplied."
                     }

                     output$studentlist_text <- shiny::renderText(studenttext)
                     output$studentlist_table <- shiny::renderTable(studenttable)
                     output$quiz_summary <- shiny::renderTable(ret$quizdf, digits = 0)
                     output$gradelist_summary <- shiny::renderText(gradelisttext)
                   }

                   if(!is.list(ret)) #if no list returned, it means it's an error message
                   {
                     output$summary_error <- shiny::renderText(ret)
                   }
                 } #end else statement of doing summary if course location is set
                 # don't run this on initialization (because no course is selected)
               }, ignoreInit = TRUE
  ) #end code that listens to manage course tab selection and summarizes course setup



#---------------------------------------------------------------
# Roster/Student List management
#---------------------------------------------------------------

  ##############################################################
  #start code block that gives users the student list template
  ##############################################################

  #this file is pulled out of the package, it's not the file copied over into the course
  #this prevents/minimizes accidental editing of the template
  output$getstudentlist <- downloadHandler(
    filename <- function() {
      "studentlist_template.xlsx"
    },
    content <- function(file) {
      file.copy(studentlisttemplatefile, file)
    },
    contentType = "application/xlsx"
  )



  ##############################################################
  #start code block that adds filled student list to course
  ##############################################################
  observeEvent(input$addstudentlist,{

    studentdf <- readxl::read_xlsx(input$addstudentlist$datapath, col_types = "text", col_names = TRUE)
    msg <- quizgrader::check_studentlist(studentdf)

    #if student list check went ok without errors, add student list to folder
    #otherwise skip this block and jump to message display below
    if (is.null(msg))
    {

      #do some data cleaning of student list
      #read data in
      studentdf <- readxl::read_xlsx(input$addstudentlist$datapath, col_types = "text", col_names = TRUE)
      #change everything to lowercase. does not apply to column headers
      studentdf <- dplyr::mutate_all(studentdf, .funs=tolower)
      #trim any potential white spaces before and after
      studentdf <- dplyr::mutate_all(studentdf, .funs=trimws)

      #add time stamp to filename
      #timestamp = gsub(" ","_",gsub("-","_", gsub(":", "_", Sys.time())))
      #filename = paste0("studentlist_",timestamp,'.xlsx')
      filename = "studentlist.xlsx"

      new_path = fs::path(courselocation, 'studentlist', filename)

      #save data frame to time-stamped file to student list folder
      writexl::write_xlsx(studentdf, path = new_path, col_names = TRUE)

      msg <- paste0("Student list has been saved to ", new_path,'.\nAny previous student list has been overwritten.')
    }

    showModal(modalDialog(msg, easyClose = FALSE))
  })



#---------------------------------------------------------------
# Quiz management
#---------------------------------------------------------------


  ##############################################################
  #start code block that gives users the quiz template file
  ##############################################################

  #this file is pulled out of the package, it's not the file copied over into the course
  #this prevents/minimizes accidental editing of the template
  output$getquiztemplate <- downloadHandler(
    filename <- function() {
      "quiz_template.xlsx"
    },
    content <- function(file) {
      fs::file_copy(quiztemplatefile, file)
    },
    contentType = "application/xlsx"
  )


  ##############################################################
  #start code block that adds complete quiz file to course
  ##############################################################

  observeEvent(input$addquiz,{

    # Load quiz and check that is in the required format
    quizdf <- readxl::read_excel(input$addquiz$datapath, col_types = "text", col_names = TRUE)
    msg <- check_quiz(quizdf)

    #if a problem occurred, msg contains text which will be displayed at end
    #if no problem occured with check, copy quiz to completequizzes folder,
    #append _complete to name, and regenerate all student quizzes
    if (is.null(msg))
    {
          # update file name
          newname = paste0(quizdf$QuizID[1],'_complete.xlsx')
          # find path to course folder
          new_path = fs::path(courselocation,"completequizzes",newname)
          #copy renamed file to completequizzes folder
          fs::file_copy(path = input$addquiz$datapath, new_path = new_path, overwrite = TRUE)

          #create a folder for future students submissions that corresponds to new quiz
          # this only happens if not already exists. If exists, nothing will happen
          fs::dir_create(fs::path(courselocation,"studentsubmissions", quizdf$QuizID[1]))

          #re-create all student quizzes
          msg <- quizgrader::create_studentquizzes(courselocation)
    } #end new quiz copy, folder creation and student quiz recreation

    # if msg is not null, it means it either had a problem with check_quiz or with create_studentquizzes
    # if it is null, it means check_quiz worked and create_studentquizzes() function worked
    if (is.null(msg))
    {
      msg <- paste0("quiz has been saved to:<br>", new_path,"<br>If it didn't yet exist, then a new submission folder has been created.<br>All student quizzes were recreated.")
    }

    showModal(modalDialog(msg, easyClose = FALSE))
  })


  #######################################################
  #start code block that removes quizzes from course
  #######################################################

  observeEvent(input$deletequiz,{


    #folder where the complete quizzes are
    localroot = c(Coursefolder = fs::path(courselocation,"completequizzes"))

    #open file browser to let user pick a file
    shinyFiles::shinyFileChoose(input, 'deletequiz',
                                roots = localroot, filetypes=c('', 'xlsx'),
                                defaultPath='', defaultRoot='Coursefolder')
    #once user has picked a file to delete, its stored here
    deletefile <- shinyFiles::parseFilePaths(localroot, input$deletequiz)

    # if a file was picked, delete file
    # also delete submission folder and re-create student quizzes
    if(nrow(deletefile)!=0)
    {
      #delete the file
      fs::file_delete(deletefile$datapath)

      #remove folder
      quizname = stringr::str_replace(deletefile$name,"_complete.xlsx","")
      fs::dir_delete(fs::path(courselocation,"studentsubmissions", quizname))

      #re-create student quizzes
      msg <- quizgrader::create_studentquizzes(courselocation)

      #that means the create_studentquizzes() function worked
      if (is.null(msg))
      {
        msg <- paste0("Removed:\n",deletefile$name,'\nAlso removed submission folder and re-created student quizzes.')
      }
      showModal(modalDialog(HTML(msg), easyClose = FALSE))
    }
  })


  ##############################################################
  #start code block that turns filled quizzes into student quizzes
  ##############################################################

  observeEvent(input$createstudentquizzes,{

      #run function to generate student versions of quizzes
      #this takes all quizzes in the specified location
      #strips columns not needed for students, and copies
      #quizzes for students into the student_quiz_sheets folder
      msg <- quizgrader::create_studentquizzes(courselocation)

      if (is.null(msg)) #this means it worked
      {
        msg <- paste0('All student quiz sheets have been created and copied to ', fs::path(courselocation,'studentquizzes'))
      }

    showModal(modalDialog(msg, easyClose = FALSE))
  })


  ##############################################################
  #start code block that returns zip file of student quizzes
  ##############################################################
  output$getstudentquizzes <- downloadHandler(
    filename <- function() {
      "studentquizsheets.zip"
    },
    content <- function(file) {
      file.copy(file.path(courselocation,'studentquizzes',"studentquizsheets.zip"), file)
    },
    contentType = "application/zip"
  )


#---------------------------------------------------------------
# Additional/Optional Grade List management
#---------------------------------------------------------------

  ##############################################################
  #start code block that gives users a grade list template file
  ##############################################################

  #this file is pulled out of the package, it's not the file copied over into the course
  #this prevents/minimizes accidental editing of the template
  output$getgradelisttemplate <- downloadHandler(
    filename <- function() {
      "gradelist_template.xlsx"
    },
    content <- function(file) {
      fs::file_copy(gradelisttemplatefile, file)
    },
    contentType = "application/xlsx"
  )


  ##############################################################
  #start code block that adds optional grade list to course
  ##############################################################
  observeEvent(input$addgradelist,{

    gradedf <- readxl::read_xlsx(input$addgradelist$datapath, col_types = "text", col_names = TRUE)

    #needs to have at least StudentID columns.
    msg <- NULL
    if (!("StudentID" %in% names(gradedf)))
    {
      msg <- "Column StudentID is missing"
    }
    #if student list check went ok without errors, add student list to folder
    #otherwise skip this block and jump to message display below
    if (is.null(msg))
    {

      #do some data cleaning of student list
      #read data in
      gradedf <- readxl::read_xlsx(input$addgradelist$datapath, col_types = "text", col_names = TRUE)
      #change everything to lowercase. does not apply to column headers
      gradedf <- dplyr::mutate_all(gradedf, .funs=tolower)
      #trim any potential white spaces before and after
      gradedf <- dplyr::mutate_all(gradedf, .funs=trimws)
      # needs to have name gradelist.xlsx
      filename = "gradelist.xlsx"
      #place in gradelist folder
      new_path = fs::path(courselocation, 'gradelist', filename)

      #save data frame to time-stamped file to student list folder
      writexl::write_xlsx(gradedf, path = new_path, col_names = TRUE)

      msg <- paste0("Grade list has been saved to ", new_path,'.\nAny previous grade list has been overwritten.')
    }

    showModal(modalDialog(msg, easyClose = FALSE))
  })



#---------------------------------------------------------------
# Course Deployment
#---------------------------------------------------------------


  ##############################################################
  #start code block that combines and zips documents needed for initial deployment
  ##############################################################
  observeEvent(input$makepackage,{

      #make zip file
      msg <- quizgrader:: create_serverpackage(courselocation, newpackage = input$newpackage)
      # show either success or error message
      showModal(modalDialog(msg, easyClose = FALSE))
  }) #end code block that zips files/folders needed for initial deployment


  ##############################################################
  #start code block that returns zip file of deployment package
  ##############################################################
  output$getpackage <- downloadHandler(
    filename <- function() {
      "serverpackage.zip"
    },
    content <- function(file) {
      file.copy(file.path(courselocation,"serverpackage.zip"), file)
    },
    contentType = "application/zip"
  )


  #######################################################
  #start code block that combines and zips documents needed for updates
  #CURRENTLY NOT USED
  #######################################################
  # observeEvent(input$updatepackage,{
  #
  #   if (is.null(courselocation))
  #   {
  #     msg <- "Please set the course location"
  #     shinyjs::reset(id  = "createstudentquizzes")
  #   } else {
  #     #make zip file
  #     msg <- quizgrader:: create_serverpackage(courselocation, newpackage = FALSE)
  #     if (is.null(msg)) #this means it worked
  #     {
  #       msg <- paste0('The serverpackage.zip file for updates has been created and copied to ', file.path(courselocation))
  #     }
  #   }
  #   showModal(modalDialog(msg, easyClose = FALSE))
  # }) #end code block that zips files/folders needed for updates



#---------------------------------------------------------------
#---------------------------------------------------------------
# Analyze Submissions Tab
#---------------------------------------------------------------
#---------------------------------------------------------------




  ################################################################################################
  #create the student and quiz UI elements
  ################################################################################################

  # observeEvent(input$topmenu == "analyzecourse",
  #              {
  #
  #             if (is.null(courselocation))
  #             {
  #               msg <- "Please make or load a course."
  #               showModal(modalDialog(msg, easyClose = FALSE))
  #               updateTabsetPanel(session, "topmenu", selected = "setcourse")
  #             }
  #             if (!is.null(courselocation))
  #                {
  #                    ret <- quizgrader::summarize_course(courselocation)
  #
  #                    student_var <- ret$studentids
  #                    quiz_var <- ret$quizdf$QuizID
  #
  #                    output$student_selector = renderUI({
  #                      shinyWidgets::pickerInput("student_selector", "Select Student", student_var, multiple = FALSE, options = list(`actions-box` = TRUE), selected = NULL )
  #                    })
  #                    output$quiz_selector = renderUI({
  #                      shinyWidgets::pickerInput("quiz_selector", "Select Quiz", quiz_var, multiple = FALSE, options = list(`actions-box` = TRUE), selected = NULL )
  #                    })
  #             } #end create student and quiz selectors
  #         }, ignoreInit = TRUE
  #       ) #end observer listening to Analyze course tab selection
  #



#   #######################################################
#   #start code block that generates overall quiz summary stats
#   #######################################################
#   observeEvent(input$analyze_overview,{
#
#     analysis_table <- quizgrader::analyze_overview(courselocation)
#
#     output$statstable <- DT::renderDataTable({
#             return(DT::datatable(analysis_table, class = "cell-border stripe", rownames = FALSE,
#                                  filter = "top", extensions = "Buttons",
#                                  options = list(dom = "Bfrtip", buttons = c("copy", "csv", "excel", "pdf", "print"), pageLength = 30)) )
#           })
#   })
#
#
#   #######################################################
#   #start code block that generates score table for all students/quizzes
#   #######################################################
#   observeEvent(input$analyze_scoretable,{
#
#     analysis_table <- quizgrader::analyze_scoretable(courselocation)
#
#     output$statstable <- DT::renderDataTable({
#       return(DT::datatable(analysis_table, class = "cell-border stripe", rownames = FALSE,
#                            filter = "top", extensions = "Buttons",
#                            options = list(dom = "Bfrtip", buttons = c("copy", "csv", "excel", "pdf", "print"), pageLength = 30)) )
#     })
#   })
#
#
#   #######################################################
#   #start code block that generates detailed student view table
#   #######################################################
#   observeEvent(input$analyze_student,{
#
#     analysis_table <- quizgrader::analyze_student(courselocation, selected_student = tolower(input$student_selector))
#
#     output$statstable <- DT::renderDataTable({
#       return(DT::datatable(analysis_table, class = "cell-border stripe",
#                            rownames = FALSE, filter = "top", extensions = "Buttons", options = list(dom = "Bfrtip", buttons = c("copy", "csv", "excel", "pdf", "print"), pageLength = 30)) )
#     })
#
#   }) #end generate_course_summary code block
#
#
#   #######################################################
#   #start code block that generates detailed quiz view table
#   #######################################################
#   observeEvent(input$analyze_quiz,{
#
#     analysis_table <- quizgrader::analyze_quiz(courselocation, selected_quiz = input$quiz_selector)
#     output$statstable <- DT::renderDataTable({
#       return(DT::datatable(analysis_table, class = "cell-border stripe",
#                            rownames = FALSE, filter = "top", extensions = "Buttons", options = list(dom = "Bfrtip", buttons = c("copy", "csv", "excel", "pdf", "print"), pageLength = 30)) )
#     })
#
#   })
#
#
#   #######################################################
#   #start code block that generates table for full submission log
#   #######################################################
#   observeEvent(input$analyze_log,{
#
#     msg <- NULL
#     submissions_log <- quizgrader::load_logfile(courselocation)
#     # if submissions_log is not a data frame, something didn't work
#     if (!is.data.frame(submissions_log))
#     {
#       msg <- "Something went wrong"
#     }
#     #if a data frame is returned and msg is null,
#     # assume things went ok
#     if (is.null(msg))
#     {
#       # need to write error catcher here
#       analysis_table <-  dplyr::select(submissions_log, -n_Questions, -n_Correct) |> dplyr::arrange(QuizID, StudentID)
#
#       output$statstable <- DT::renderDataTable({
#         return(DT::datatable(analysis_table, class = "cell-border stripe",
#                              rownames = FALSE, filter = "top", extensions = "Buttons", options = list(dom = "Bfrtip", buttons = c("copy", "csv", "excel", "pdf", "print"), pageLength = 30)) )
#       })
#     }
#     if (!is.null(msg))
#     {
#       showModal(modalDialog(msg, easyClose = FALSE))
#     }
#   }) #end analyze log part

  #---------------------------------------------------------------
  #---------------------------------------------------------------
  # End of Analyze Submissions Tab
  #---------------------------------------------------------------
  #---------------------------------------------------------------



  #######################################################
  #Exit quizmanager menu
  #######################################################
  observeEvent(input$Exit, {
    stopApp('Exit')
  })


} #end server function



#######################################################
#UI for quiz manager shiny app
#######################################################

#This is the UI for the Main Menu of the
#quiz manager app
ui <- fluidPage(
  shinyjs::useShinyjs(),  # Set up shinyjs
  #tags$head(includeHTML(("google-analytics.html"))), #this is only needed for Google analytics when deployed as app to the UGA server. Should not affect R package use.
  includeCSS("quizmanager.css"),
  tags$div(id = "shinyheadertitle", "quizgrader - automated grading and analysis of quizzes"),
  tags$div(id = "infotext", paste0('This is ', packagename,  ' version ',utils::packageVersion(packagename),' last updated ', utils::packageDescription(packagename)$Date,'.')),
  tags$div(id = "infotext", "Written and maintained by", a("Andreas Handel", href="https://www.andreashandel.com", target="_blank"), "with many contributions from", a("others.",  href="https://github.com/andreashandel/quizgrader#contributors", target="_blank")),
  p("For documentation on how to use the package, please see", a("the package website.", href="https://andreashandel.github.io/quizgrader/", target="_blank"), class='maintext'),
  p('Happy teaching!', class='maintext'),


  navbarPage(title = "quizmanager", id = "topmenu", selected = "setcourse",
             # ---------------------
             # Tab for setting up/loading course
             # ---------------------
             tabPanel(title = "Set Course", value = "setcourse", id = "setcourse",
                               h3('Start a new Course'),
                               textInput("coursename",label = "Course Name"),
                               shinyFiles::shinyDirButton("newcoursedir", "Set parent directory for new course", "Select a parent folder for new course"),
                               verbatimTextOutput("newcoursedir", placeholder = TRUE),  # added a placeholder
                               actionButton("createcourse", "Start new course", class = "actionbutton"),
                               h3('Load existing Course'),
                               shinyFiles::shinyDirButton("coursedir", "Find existing course", "Select an existing course folder"),
                               verbatimTextOutput("coursedir", placeholder = TRUE),  # added a placeholder
                               br(),
                               br()
                      ), # end set course tab panel

             # ---------------------
             # Tab for managing course
             # ---------------------
             tabPanel(title = "Manage Course", value = "managecourse", id = 'managecourse',
                      navlistPanel(id = "manage_submenu",
                                   tabPanel(title = "Course Overview", value = "overview",
                                            actionButton("showoverview", "Show/refresh course overview", class = "actionbutton"),
                                            textOutput("studentlist_text"),
                                            tableOutput("studentlist_table"),
                                            tableOutput("quiz_summary"),
                                            textOutput("gradelist_summary"),
                                            textOutput("summary_error"),
                                            br()
                                   ), # end setup overview panel
                                   tabPanel(title = "Student List Management", id = "studentlist", value = "studentlist",
                                            p('Fill this template with your student information, then add with the button below. If you add a new list, any old ones will be overwritten.'),
                                            downloadButton("getstudentlist", "Get studentlist template", class = "actionbutton"),
                                            fileInput("addstudentlist", label = "", buttonLabel = "Add filled studentlist to course", accept = '.xlsx')
                                            ), # end setup roster panel
                                   tabPanel(title = "Quiz Management", value = "quizzes",
                                            p('Use this template to create your quizzes.'),
                                            downloadButton("getquiztemplate", "Get quiz template", class = "actionbutton"),
                                            p('Add a completed quiz to course. Any quiz with the same file name as one being added will be replaced/overwritten.'),
                                            shiny::fileInput("addquiz", label = "", buttonLabel = "Add a quiz", accept = '.xlsx', multiple = FALSE),
                                            p('Remove a quiz from the course. WARNING: This also deletes the submission folder for this quiz. If there are already student submissions you want to keep, move them to a save place first.'),
                                            shinyFiles::shinyFilesButton("deletequiz", label = "Remove a quiz", title = "Remove a quiz from the course", multiple = FALSE),
                                            p('After you update the complete quizzes, do not forget to re-distribute updated student quiz sheets.'),
                                            downloadButton("getstudentquizzes", "Get zip file with all student quiz files", class = "actionbutton")
                                            ), # end setup quizzes panel
                                   tabPanel(title = "Grade List Management", id = "gradelist", value = "gradelist",
                                            downloadButton("getgradelisttemplate", "Get grade list template", class = "actionbutton"),
                                            p('You can add an Excel sheet with additional (grade) information that students can check. The sheet needs to have at least the StudentID column. Add columns with scores/information from other activities you want each student to be able to check. All columns will be shown.'),
                                            fileInput("addgradelist", label = "", buttonLabel = "Add optional gradelist to course", accept = '.xlsx'),
                                            br()
                                   ), # end setup roster panel
                                   tabPanel(title = "Deployment", value = "deployment",
                                            h2('Deploy course'),
                                            p('This checks all supplied files, re-creates student quizzes, then combines all folders and files needed for server deployment into a zip file.'),
                                            h3('If you want the app and the folders for student submissions, check this. Note that if you place this on the server, it might overwrite existing student submission!
                                               Therefore, if you check this, first copy everything in studentsubmissions from the server into the local studentsubmissions folder before creating an updated package!'),
                                            checkboxInput("newpackage", "Create initial package with everything."),
                                            p('Once the zip file is created, copy it to the server and unzip (re-set access permissions as needed).'),
                                            p('Any student submissions you previously retrieved from the server and placed in the local studentsubmissions folder will be included and thus preserved upon extraction of this file on the server (but better make a backup).'),
                                            p('Any prior student list or quiz files will be overwritten.'),
                                            actionButton("makepackage", "Make zip file for deployment", class = "actionbutton"),
                                            #actionButton("deploycourse", "Deploy course to shiny server", class = "actionbutton"),
                                            p(textOutput("warningtext")),
                                            br(),
                                            br()
                                            ) # end setup deployment panel
                                   ) # end management nav list
                      ), # end management panel

             # ---------------------
             # Tab for analyzing submissions
             # ---------------------

             tabPanel(title = "Analyze Submissions",  value = "analyzecourse", id = 'analyzecourse',
                      h2('Show summary data for all submissions'),
                      actionButton("analyze_overview", "Summary Data", class = "actionbutton"),
                      h2('Show score table for all students/quizzes'),
                      actionButton("analyze_scoretable", "Score Table", class = "actionbutton"),
                      h2('Show information for a specific student'),
                      p('Check course overview to match StudentID to a student name.'),
                      uiOutput('student_selector'),
                      actionButton("analyze_student", "Student Data", class = "actionbutton"),
                      h2('Show information for a specific quiz'),
                      uiOutput('quiz_selector'),
                      actionButton("analyze_quiz", "Quiz Data", class = "actionbutton"),
                      h2('Show full submission log'),
                      actionButton("analyze_log", "Log Data", class = "actionbutton"),
                      hr(),
                      hr(),
                      DT::dataTableOutput("statstable"),
                      ) #end of "Analyze" tab

        ), #close navbarPage element
        # add to bottom
        fluidRow(column(12,
                      actionButton("Exit", "Exit", class="exitbutton")
                      ),
                 class = "mainmenurow"
        ), #close fluidRow structure for input
        tagList( hr(),
           p('All text and figures are licensed under a ',
             a("Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.", href="http://creativecommons.org/licenses/by-nc-sa/4.0/", target="_blank"),
             'Software/Code is licensed under ',
             a("GPL-3.", href="https://www.gnu.org/licenses/gpl-3.0.en.html" , target="_blank")
             ,
             br(),
             "The development of this package was partially supported by TBD.",
             align = "center", style="font-size:small") #end paragraph
        ) #end taglist
) #end fluidpage and UI part of app




# Run the application
shinyApp(ui = ui, server = server)
