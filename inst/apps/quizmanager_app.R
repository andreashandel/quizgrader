######################################################
# This app is part of quizgrader
# It provides a frontend for instructors to manage their course quizzes
# It helps both in preparing the quizzes and analyzing student submissions
######################################################

#for debugging/manual fiddling
#courselocation <- ("D:/Dropbox/2021-3-fall-MADA/quizzes/MADA2021")

##############################################
#Set up some variables, define all as global (the <<- notation)
#name of R package
packagename <<- "quizgrader"
#path to templates
quiztemplatefile <<- file.path(system.file("templates", package = packagename),"quiz_template.xlsx")
studentlisttemplatefile <<- file.path(system.file("templates", package = packagename),"studentlist_template.xlsx")
# will contain location/path to course
courselocation <<- NULL


#######################################################
#server part for shiny app
#######################################################

server <- function(input, output, session) {


#---------------------------------------------------------------
# Course Creation
#---------------------------------------------------------------

  ##############################################################
  #start code block that chooses directory for new course
  ##############################################################

  #server functionality that lets user choose a folder for the new course
  #this is taken from the shinyFilesExample() examples
  volumes <- c(Home = fs::path_home(), shinyFiles::getVolumes()())

  #if user clicks the button to select a folder for new course
  observeEvent(input$newcoursedir, {
    shinyFiles::shinyDirChoose(input, "newcoursedir", roots = volumes, session = session, restrictions = system.file(package = "base"), allowDirCreate = FALSE)
    courselocation <<- shinyFiles::parseDirPath(volumes, input$newcoursedir)
    output$newcoursedir <- renderText(courselocation)
    output$coursedir <- renderText(courselocation)
  })


  ##############################################################
  #start code block that selects an existing course folder
  ##############################################################

  #this is used for working on an existing course
  observeEvent(input$coursedir, {
    shinyFiles::shinyDirChoose(input, "coursedir", roots = volumes, session = session, restrictions = system.file(package = "base"), allowDirCreate = FALSE)
    courselocation <<- shinyFiles::parseDirPath(volumes, input$coursedir)
    output$coursedir <- renderText(courselocation)
  })


  ##############################################################
  #start code block that creates directory skeleton structure
  ##############################################################

  #once user has entered course name and picked a folder location
  #a course can be started
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
  })




#---------------------------------------------------------------
# Roster Creation
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

    #check that a course folder has been selected
    msg <- NULL
    if (is.null(courselocation))
    {
      msg <- "Please set the course location"
      shinyjs::reset(id  = "addstudentlist")
    }

    if (is.null(msg)) #if course location is ok, get and check student roster
    {
      studentdf <- readxl::read_xlsx(input$addstudentlist$datapath, col_types = "text", col_names = TRUE)
      msg <- quizgrader::check_studentlist(studentdf)
    }

    if (is.null(msg)) #if no prior error, add student list to folder
    {

      #do some data cleaning of student list
      #read data in
      studentdf <- readxl::read_xlsx(input$addstudentlist$datapath, col_types = "text", col_names = TRUE)
      #change everything to lowercase. does not apply to column headers
      studentdf <- dplyr::mutate_all(studentdf, .funs=tolower)
      #trim any potential white spaces before and after
      studentdf <- dplyr::mutate_all(studentdf, .funs=trimws)

      #add time stamp to filename
      timestamp = gsub(" ","_",gsub("-","_", gsub(":", "_", Sys.time())))
      filename = paste0("studentlist_",timestamp,'.xlsx')

      new_path = fs::path(courselocation, 'studentlists', filename)

      #save data frame to time-stamped file to student list folder
      writexl::write_xlsx(studentdf, path = new_path, col_names = TRUE)

      msg <- paste0("student list has been saved to ", new_path)
    }

    showModal(modalDialog(msg, easyClose = FALSE))
  })





#---------------------------------------------------------------
# Quiz Creation
#---------------------------------------------------------------


  ##############################################################
  #start code block that gives users the quiz template
  ##############################################################

  #this file is pulled out of the package, it's not the file copied over into the course
  #this prevents/minimizes accidental editing of the template
  output$getquiztemplate <- downloadHandler(
    filename <- function() {
      "quiz_template.xlsx"
    },
    content <- function(file) {
      file.copy(quiztemplatefile, file)
    },
    contentType = "application/xlsx"
  )



  ##############################################################
  #start code block that adds filled quizzes to course
  ##############################################################

  observeEvent(input$addquiz,{

    #check that a course folder has been selected
    msg <- NULL
    if (is.null(courselocation)) #not sure why integer, but that's how the example is
    {
      msg <- "Please set the course location"
      shinyjs::reset(id  = "addquiz")
    }

    if (is.null(msg)) #if no prior error, try to open quiz file, then copy
    {

      successfully_added <- c()
      unsuccessfully_added <- c()

      # Loop over quizzes to add
      for(quiz_i in seq_along(input$addquiz$name)){

        # Load quiz and check that is in the required format
        quizdf <- readxl::read_excel(input$addquiz$datapath[quiz_i], col_types = "text", col_names = TRUE)
        msg <- check_quiz(quizdf)

        if (!is.null(msg)) # if returned error message, log it as description list: filename = term, error message = description
        {
          unsuccessfully_added <- c(unsuccessfully_added, paste0("<dt>", input$addquiz$name[quiz_i], "</dt><dd>- ", msg, "</dd>"))
        } # end if logging error message

        if (is.null(msg)) #if no problem occurred, try copying
        {
          #find path to course folder
          newname = paste0(quizdf$QuizID[1],'_complete.xlsx')
          new_path = fs::path(courselocation,"completequizzes",newname)
          #copy renamed file to completequiz folder
          fs::file_copy(path = input$addquiz$datapath[quiz_i], new_path = new_path, overwrite = TRUE)
          # msg <- paste0("quiz has been saved to ", new_path)
          successfully_added <- c(successfully_added, input$addquiz$name[quiz_i])
        }# end if check worked, copy file



      } # end loop for adding quizzes


      # Aggregate messages with HTML unordered lists, description lists for error messages with unsuccessfully loaded quizzes
      if (is.null(unsuccessfully_added))
      {
        msg <- paste0("Quizzes successfully added:<br><ul><li>", paste(successfully_added, collapse = "</li><li>"), "</li></ul>")
      } else
      {
        if (is.null(successfully_added))
        {
          msg <- paste0("Quizzes unsuccessfully added:<br><dl><ul><li>", paste(unsuccessfully_added, collapse = "</li><li>"), "</li></ul></dl>")
        } else
        {
          msg <- paste0("Quizzes successfully added:<br><ul><li>", paste(successfully_added, collapse = "</li><li>"), "</li></ul>",
                        "<br>",
                        "Quizzes unsuccessfully added:<br><dl><ul><li>", paste(unsuccessfully_added, collapse = "</li><li>"), "</li></ul></dl>")
        }
      }



    } #end if for attempting quiz add

    # result message, wrapped in HTML for lists
    showModal(modalDialog(HTML(msg), easyClose = FALSE))
  })




#------------------------------------------------------
# Course Summary
#------------------------------------------------------


  #######################################################
  #start code block that generates course summary of all quizzes
  #######################################################
  observeEvent(input$generate_course_summary,{

    msg <- NULL

    if (is.null(courselocation))
    {
      msg <- "Please set the course location"
    } else {

      msg <- quizgrader::summarize_course(courselocation)

      if (is.null(msg))
      {
        #load student list
        listfiles <- fs::dir_info(fs::path(courselocation,"studentlists"))
        #load the most recent one, which is the one to be used
        filenr = which.max(listfiles$modification_time) #find most recently changed file
        studentdf <- readxl::read_xlsx(listfiles$path[filenr], col_types = "text", col_names = TRUE)
        nstudents = nrow(studentdf)

        output$studentlist_summary <- shiny::renderText(paste0("There are currently ", nstudents, " students enrolled in your course."))
        output$quiz_summary <- shiny::renderTable(readxl::read_xlsx(fs::path(courselocation, "course_summary.xlsx")), digits = 0)
      }
    } #end outer else statement

    if(!is.null(msg))
    {
      showModal(modalDialog(msg, easyClose = FALSE))
    }
  }) #end generate_course_summary code block





  #---------------------------------------------------------------
  # Initial Course Deployment
  #---------------------------------------------------------------


  ##############################################################
  #start code block that turns filled quizzes into student quizzes
  ##############################################################

  observeEvent(input$createstudentquizzes,{

    if (is.null(courselocation)) #not sure why integer, but that's how the example is
    {
      msg <- "Please set the course location"
      shinyjs::reset(id  = "createstudentquizzes")
    } else {


      #run function to generate student versions of quizzes
      #this takes all quizzes in the specified location
      #strips columns not needed for students, and copies
      #quizzes for students into the student_quiz_sheets folder
      msg <- quizgrader::create_student_quizzes(courselocation)

      if (is.null(msg)) #this means it worked
      {
        msg <- paste0('All student quiz sheets have been created and copied to ', fs::path(courselocation,'studentquizzes'))
      }

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



  ##############################################################
  #start code block that combines and zips documents needed for initial deployment
  ##############################################################
  observeEvent(input$makepackage,{

    if (is.null(courselocation))
    {
      msg <- "Please set the course location"
      shinyjs::reset(id  = "createstudentquizzes")
    } else {
      #make zip file
      msg <- quizgrader:: create_serverpackage(courselocation, newpackage = TRUE)
      if (is.null(msg)) #this means it worked
      {
        msg <- paste0('The serverpackage.zip file for deployment has been created and copied to ', file.path(courselocation))
      }
    }
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



  #------------------------------------------------------
  # Course Modification
  #------------------------------------------------------

  #######################################################
  #start code block that removes quizzes from course
  #######################################################




  observeEvent(input$deletequiz,{

    msg <- NULL

    if (is.null(courselocation)) #not sure why integer, but that's how the example is
    {
      msg <- "Please set the course location"
      shinyjs::reset(id  = "deletequiz")

      showModal(modalDialog(HTML(msg), easyClose = FALSE))
    }
    if (is.null(msg))
    {
      volumes = c(Coursefolder = fs::path(courselocation,"completequizzes"))

      shinyFiles::shinyFileChoose(input, 'deletequiz', roots=c(Coursefolder=fs::path(courselocation, "completequizzes")), filetypes=c('', 'xlsx'),
                                  defaultPath='', defaultRoot='Coursefolder')

      deletefile <- shinyFiles::parseFilePaths(volumes, input$deletequiz) #save course folder to global variable
      file.remove(deletefile$datapath)
      msg <- paste0("Removed:<br><ul><li>", paste0(deletefile$name, collapse = "</li><li>"), "</li></ul>")


      if(nrow(deletefile)!=0){
        showModal(modalDialog(HTML(msg), easyClose = FALSE))
      }

    }

  })





  #######################################################
  #start code block that combines and zips documents needed for updates
  #######################################################
  observeEvent(input$updatepackage,{

    if (is.null(courselocation))
    {
      msg <- "Please set the course location"
      shinyjs::reset(id  = "createstudentquizzes")
    } else {
      #make zip file
      msg <- quizgrader:: create_serverpackage(courselocation, newpackage = FALSE)
      if (is.null(msg)) #this means it worked
      {
        msg <- paste0('The serverpackage.zip file for updates has been created and copied to ', file.path(courselocation))
      }
    }
    showModal(modalDialog(msg, easyClose = FALSE))
  }) #end code block that zips files/folders needed for updates





#------------------------------------------------------
# Analysis
#------------------------------------------------------


  #######################################################
  #start code block that generates analysis summary stats
  #######################################################
  observeEvent(input$analyze,{

    msg <- NULL
    output$summarystats <- NULL
    if (is.null(courselocation))
    {
      msg <- "Please set the course location"
    } else {

      grades <- quizgrader::calculate_grades(courselocation, input$grades_type, ifelse(input$duedate_filter=="Yes", TRUE, FALSE))

      output$summarystats <- DT::renderDataTable({
            return(DT::datatable(grades, class = "cell-border stripe", rownames = FALSE, filter = "top", extensions = "Buttons", options = list(dom = "Bfrtip", buttons = c("copy", "csv", "excel", "pdf", "print"), pageLength = 30)) )
          })

    }# end outer else statement

    if(!is.null(msg))
    {
      showModal(modalDialog(msg, easyClose = FALSE))
    }
  }) #end generate_course_summary code block






#------------------------------------------------------
# App Layout Functionality
#------------------------------------------------------

  #######################################################
  #start code block that transitions between tabs
  #######################################################

  observeEvent(input$gobackto_setup_directory, {
    updateNavlistPanel(inputId = "initial_setup_submenu",
                       selected = "setup_directory")
  })

  observeEvent(input$goto_setup_roster | input$gobackto_setup_roster, {
    updateNavlistPanel(inputId = "initial_setup_submenu",
                       selected = "setup_roster")
  }, ignoreInit = TRUE)

  observeEvent(input$goto_setup_quizzes | input$gobackto_setup_quizzes, {
    updateNavlistPanel(inputId = "initial_setup_submenu",
                       selected = "setup_quizzes")
  }, ignoreInit = TRUE)

  observeEvent(input$goto_setup_overview | input$gobackto_setup_overview, {
    updateNavlistPanel(inputId = "initial_setup_submenu",
                       selected = "setup_overview")
  }, ignoreInit = TRUE)

  observeEvent(input$goto_setup_deployment, {
    updateNavlistPanel(inputId = "initial_setup_submenu",
                       selected = "setup_deployment")
  }, ignoreInit = TRUE)






  #######################################################
  #Exit quizmanager menu
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
  includeCSS("quizgrader.css"),
  tags$div(id = "shinyheadertitle", "quizgrader - automated grading and analysis of quizzes"),
  tags$div(id = "infotext", paste0('This is ', packagename,  ' version ',utils::packageVersion(packagename),' last updated ', utils::packageDescription(packagename)$Date,'.')),
  tags$div(id = "infotext", "Written and maintained by", a("Andreas Handel", href="https://www.andreashandel.com", target="_blank"), "with many contributions from", a("others.",  href="https://github.com/andreashandel/quizgrader#contributors", target="_blank")),
  p("For documentation on how to use the package, please see", a("the package website.", href="https://andreashandel.github.io/quizgrader/", target="_blank"), class='maintext'),
  p('Happy teaching!', class='maintext'),


  navbarPage(title = "quizmanager", id = "topmenu", selected = "initial_setup",

             tabPanel(title = "Course Setup", value = "initial_setup",
                      navlistPanel(id = "initial_setup_submenu", selected = "setup_directory",
                                   tabPanel(title = "Directory Setup", value = "setup_directory",

                                            h3('Start a new Course'),
                                            textInput("coursename",label = "Course Name"),

                                            shinyFiles::shinyDirButton("newcoursedir", "Set parent directory for new course", "Select a parent folder for new course"),

                                            verbatimTextOutput("newcoursedir", placeholder = TRUE),  # added a placeholder


                                            actionButton("createcourse", "Start new course", class = "actionbutton"),


                                            h3('Load existing Course'),
                                            shinyFiles::shinyDirButton("coursedir", "Find existing course", "Select an existing course folder"),
                                            verbatimTextOutput("coursedir", placeholder = TRUE),  # added a placeholder

                                            br(),
                                            br(),
                                            br(),
                                            fluidRow(column(6, ""),
                                                     column(6, align = "center", actionButton(inputId = 'goto_setup_roster', label = div('Advance to Roster Setup', icon('angle-double-right'))))
                                            ),
                                            br(),
                                            br()
                                            ), # end setup directory panel
                                   tabPanel(title = "Roster Setup", value = "setup_roster",
                                            h3('Manage student list (you can do this after adding quizzes)'),
                                            downloadButton("getstudentlist", "Get studentlist template", class = "actionbutton"),
                                            fileInput("addstudentlist", label = "", buttonLabel = "Add filled studentlist to course", accept = '.xlsx'),

                                            br(),
                                            br(),
                                            br(),
                                            fluidRow(column(6, align = "center", actionButton(inputId = 'gobackto_setup_directory', label = 'Return to Directory Setup', icon = icon('angle-double-left'))),
                                                     column(6, align = "center", actionButton(inputId = 'goto_setup_quizzes', label = div('Advance to Quizzes Setup', icon('angle-double-right'))))
                                            ),

                                            br(),
                                            br()
                                            ), # end setup roster panel
                                   tabPanel(title = "Quizzes Setup", value = "setup_quizzes",
                                            h3('Manage quizzes'),
                                            downloadButton("getquiztemplate", "Get quiz template", class = "actionbutton"),
                                            shiny::fileInput("addquiz", label = "", buttonLabel = "Add a completed quiz to course", accept = '.xlsx', multiple = TRUE),
                                            p('Any quiz with the same file name as the one being added will be overwritten.'),
                                            shinyFiles::shinyFilesButton("deletequiz", label = "Remove a quiz", title = "Remove a quiz from the course", multiple = TRUE),
                                            br(),
                                            actionButton("createstudentquizzes", "Create all student quiz files", class = "actionbutton"),
                                            downloadButton("getstudentquizzes", "Get zip file with all student quiz files", class = "actionbutton"),
                                            br(),
                                            fluidRow(column(6, align = "center", actionButton(inputId = 'gobackto_setup_roster', label = 'Return to Roster Setup', icon = icon('angle-double-left'))),
                                                     column(6, align = "center", actionButton(inputId = 'goto_setup_overview', label = div('Advance to Setup Overview', icon('angle-double-right'))))
                                            ),


                                            br(),
                                            br()
                                            ), # end setup quizzes panel
                                   tabPanel(title = "Setup Overview", value = "setup_overview",
                                            h2('Review Course Structure'),
                                            actionButton("generate_course_summary", "Generate Course Summary", class = "actionbutton"),
                                            br(),
                                            textOutput("studentlist_summary"),
                                            tableOutput("quiz_summary"),
                                            br(),
                                            br(),
                                            fluidRow(column(6, align = "center", actionButton(inputId = 'gobackto_setup_quizzes', label = 'Return to Quizzes Setup', icon = icon('angle-double-left'))),
                                                     column(6, align = "center", actionButton(inputId = 'goto_setup_deployment', label = div('Advance to Deployment Setup', icon('angle-double-right'))))
                                            ),
                                            br()
                                            ), # end setup overview panel
                                   tabPanel(title = "Deployment", value = "setup_deployment",
                                            h2('Deploy course'),
                                            actionButton("makepackage", "Make zip file for initial deployment", class = "actionbutton"),
                                            downloadButton("getpackage", "Get zip file of deployment package", class = "actionbutton"),
                                            #actionButton("deploycourse", "Deploy course to shiny server", class = "actionbutton"),
                                            p(textOutput("warningtext")),
                                            br(),
                                            fluidRow(column(6, align = "center", actionButton(inputId = 'gobackto_setup_overview', label = 'Return to Setup Overview', icon = icon('angle-double-left'))),
                                                     column(6, align = "center", "")
                                            ),

                                            br(),
                                            br()
                                            ) # end setup deployment panel
                                   ) # end initial setup nav list
                      ), # end initial setup panel



             tabPanel(title = "Manage Existing Course", value = "manage",
                      navlistPanel(id = "manage_submenu", selected = "specify_directory",
                                  tabPanel(title = "Directory Setup", value = "specify_directory",
                                           h3('Load existing Course'),
                                           # shinyFiles::shinyDirButton("coursedir", "Find existing course", "Select an existing course folder"),
                                           # verbatimTextOutput("coursedir", placeholder = TRUE)  # added a placeholder


                                          ), # end directory specification panel

                                  tabPanel(title = "Roster", value = "roster",
                                           # h3('Manage student list'),
                                           # downloadButton("getstudentlist", "Get studentlist template", class = "actionbutton"),
                                           # fileInput("addstudentlist", label = "", buttonLabel = "Add filled studentlist to course", accept = '.xlsx')


                                          ), # end roster management panel

                                  tabPanel(title = "Quizzes", value = "quizzes",
                                           # h3('Manage quizzes'),
                                           # downloadButton("getquiztemplate", "Get quiz template", class = "actionbutton"),
                                           # shiny::fileInput("addquiz", label = "", buttonLabel = "Add a completed quiz to course", accept = '.xlsx'),
                                           # p('Any quiz with the same file name as the one being added will be overwritten.'),
                                           # shinyFiles::shinyFilesButton("removequiz", label = "Remove quiz", title = "Remove a quiz from the course", multiple = TRUE),
                                           # actionButton("createstudentquizzes", "Create student quiz files", class = "actionbutton"),
                                           # downloadButton("getstudentquizzes", "Get zip file with all student quizzes", class = "actionbutton")
                                          ), # end quizzes management panel


                                  tabPanel(title = "Deployment", value = "deploy",
                                           # h2('Deploy course'),
                                           # actionButton("makepackage", "Make zip file for initial deployment", class = "actionbutton"),
                                           # actionButton("updatepackage", "Make zip file for updates", class = "actionbutton"),
                                           # #actionButton("deploycourse", "Deploy course to shiny server", class = "actionbutton"),
                                           #
                                           # p(textOutput("warningtext"))
                                          ) # end deployment panel
                                  ) # end course management navlist
                      ), # end course management panel


             tabPanel("Analyze Submissions",  value = "analyze",
                      h2('Retrieve submissions'),
                      actionButton("retrieve", "Retrieve submissions from shiny server", class = "actionbutton"),
                      h2('Analyze submissions'),
                      selectInput("grades_type", "Select which analysis to generate", choices = c("overview", "student", "question")),
                      selectInput("duedate_filter", "Do you want to include only past quizzes?", choices = c("Yes", "No")),
                      actionButton("analyze", "Analyze submissions", class = "actionbutton"),
                      DT::dataTableOutput("summarystats")
                      ), #close "Analyze" tab

            fluidRow(column(12,
                            actionButton("Exit", "Exit", class="exitbutton")
                            ),
                     class = "mainmenurow"
                     ) #close fluidRow structure for input
            ), #close NavBarPage



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
