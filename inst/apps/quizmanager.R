######################################################
# This app is part of quizgrader
# It provides a frontend for instructors to manage their course quizzes
# It helps both in preparing the quizzes and analyzing student submissions
######################################################


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


        #######################################################
        #start code block that creates a new course
        #######################################################

        #server functionality that lets user choose a folder for the new course
        #this is taken from the shinyFilesExample() examples
        volumes <- c(Home = fs::path_home(), shinyFiles::getVolumes()())
        shinyFiles::shinyDirChoose(input, "newcoursedir", roots = volumes, session = session, restrictions = system.file(package = "base"), allowDirCreate = FALSE)

        output$newcoursedir <- renderPrint({
                if (is.integer(input$newcoursedir)) {
                        cat("No directory has been selected")
                } else {
                        #save course folder location to global variable
                        courselocation <<- shinyFiles::parseDirPath(volumes, input$newcoursedir)
                        shinyFiles::parseDirPath(volumes, input$newcoursedir)
                }
        })

        #once user has entered course name and picked a folder location
        #a course can be started
        observeEvent(input$startcourse, {

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
                        #format course path into a way that can be used by start_course
                        newcoursedir = shinyFiles::parseDirPath(volumes, input$newcoursedir)
                        msg <- quizgrader::start_course(isolate(input$coursename), isolate(newcoursedir))
                }
                if (is.null(msg)) #if start_course worked well, it won't sent a message back
                {
                        #save course folder to global variable
                        courselocation <<- file.path(isolate(newcoursedir), isolate(input$coursename))

                        msg <- paste0("The new course folder and its subfolders have been created at: ",courselocation)
                }

                showModal(modalDialog(
                        msg,
                        easyClose = FALSE
                ))
        })


        #######################################################
        #start code block that selects an existing course folder
        #######################################################
        shinyFiles::shinyDirChoose(input, "coursedir", roots = volumes, session = session, restrictions = system.file(package = "base"), allowDirCreate = FALSE)

        output$coursedir <- renderPrint({
                if (is.integer(input$coursedir)) {
                        cat("No directory has been selected")
                } else {
                        courselocation <<- shinyFiles::parseDirPath(volumes, input$coursedir) #save course folder to global variable
                        shinyFiles::parseDirPath(volumes, input$coursedir)
                }
        })



        #######################################################
        #start code block that gives users the student list template
        #######################################################
        output$getstudentlist <- downloadHandler(
                        filename <- function() {
                                "studentlist_template.xlsx"
                        },
                        content <- function(file) {
                                file.copy(studentlisttemplatefile, file)
                        },
                        contentType = "application/xlsx"
                )

        #######################################################
        #start code block that gives users the quiz template
        #######################################################
        output$getquiztemplate <- downloadHandler(
                filename <- function() {
                        "quiz_template.xlsx"
                },
                content <- function(file) {
                        file.copy(quiztemplatefile, file)
                },
                contentType = "application/xlsx"
        )


        #######################################################
        #start code block that adds filled student list to course
        #######################################################
        observeEvent(input$addstudentlist,{

                #check that a course folder has been selected
                msg <- NULL
                if (is.null(courselocation))
                {
                        msg <- "Please set the course location"
                        shinyjs::reset(id  = "addstudentlist")
                }

                if (is.null(msg)) #if no prior error, try to create course
                {
                        #add time stamp to filename
                        timestamp = gsub(" ","_",gsub("-","_", gsub(":", "_", Sys.time())))
                        #find path to course folder
                        filename = paste0("studentlist","_",timestamp,'.xlsx')
                        new_path = file.path(courselocation,"studentlists",filename)

                        #copy time-stamped file to student list folder
                        fs::file_copy(path = input$addstudentlist$datapath,  new_path = new_path)

                        msg <- paste0("student list has been saved to ", new_path)
                }

                showModal(modalDialog(
                        msg,
                        easyClose = FALSE
                ))
        })


        #######################################################
        #start code block that adds filled quizzes to course
        #######################################################
        observeEvent(input$addquiz,{

                #check that a course folder has been selected
                msg <- NULL
                if (is.null(courselocation)) #not sure why integer, but that's how the example is
                {
                        msg <- "Please set the course location"
                        shinyjs::reset(id  = "addquiz")
                }

                if (is.null(msg)) #if no prior error, try to create course
                {
                        #find path to course folder
                        new_path = file.path(courselocation,"complete_quiz_sheets",input$addquiz$name)

                        #copy time-stamped file to student list folder
                        fs::file_copy(path = input$addquiz$datapath,  new_path = new_path, overwrite = TRUE)

                        msg <- paste0("quiz has been saved to ", new_path)
                }

                showModal(modalDialog(
                        msg,
                        easyClose = FALSE
                ))
        })



        #######################################################
        #start code block that turns filled quizzes
        #into student quizzes
        #######################################################
        observeEvent(input$createstudentquizzes,{


                msg <- create_student_quizzes(courselocation)

                if (is.null(msg)) #this means it worked
                {
                  msg <- paste0('All student quiz sheets have been created and copied to ', file.path(courselocation,'student_quiz_sheets'))
                }

                showModal(modalDialog(
                        msg,
                        easyClose = FALSE
                ))


        })

        #######################################################
        #start code block that returns zip file of student quizzes
        #######################################################
        output$getstudentquizzes <- downloadHandler(
                        filename <- function() {
                                "studentquizsheets.zip"
                        },
                        content <- function(file) {
                                file.copy(file.path(courselocation,'student_quiz_sheets',"studentquizsheets.zip"), file)
                        },
                        contentType = "application/zip"
                )


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
        includeCSS("packagestyle.css"),
        tags$div(id = "shinyheadertitle", "quizgrader - automated grading and analysis of quizzes"),
        tags$div(id = "infotext", paste0('This is ', packagename,  ' version ',utils::packageVersion(packagename),' last updated ', utils::packageDescription(packagename)$Date,'.')),
        tags$div(id = "infotext", "Written and maintained by", a("Andreas Handel", href="https://www.andreashandel.com", target="_blank"), "with many contributions from", a("others.",  href="https://github.com/andreashandel/quizgrader#contributors", target="_blank")),
        p('Happy teaching!', class='maintext'),
        navbarPage(title = "quizmanager", id = 'alltabs', selected = "manage",
                   tabPanel(title = "Manage quizzes", value = "manage",
                            h2('Start a new Course'),
                            textInput("coursename",label = "Course Name"),
                            shinyFiles::shinyDirButton("newcoursedir", "Course location", "Select a parent folder for new course"),
                            verbatimTextOutput("newcoursedir"),  # added a placeholder
                            actionButton("startcourse", "Start new course", class = "actionbutton"),
                            h2('Load existing Course'),
                            shinyFiles::shinyDirButton("coursedir", "Course location", "Select an existing course folder"),
                            verbatimTextOutput("coursedir"),  # added a placeholder
                            h2('Get template files'),
                            downloadButton("getstudentlist", "Get studentlist template", class = "actionbutton"),
                            downloadButton("getquiztemplate", "Get quiz template", class = "actionbutton"),
                            h2('Add files to course'),
                            fileInput("addstudentlist", label = "", buttonLabel = "Add filled studentlist to course", accept = '.xlsx'),
                            p('Any quiz with the same file name as the one being added will be overwritten.'),
                            fileInput("addquiz", label = "", buttonLabel = "Add a finished quiz to course", accept = '.xlsx'),
                            actionButton("createstudentquizzes", "Create student quiz files", class = "actionbutton"),
                            downloadButton("getstudentquizzes", "Get zip file with all student quiz files", class = "actionbutton"),
                            h2('Deploy course'),
                            actionButton("deploycourse", "Deploy course to shiny server", class = "actionbutton"),
                            p(textOutput("warningtext")),

                            fluidRow(

                                    column(12,
                                           actionButton("Exit", "Exit", class="exitbutton")
                                    ),
                                    class = "mainmenurow"
                            ) #close fluidRow structure for input

                   ), #close "Manage" tab

                   tabPanel("Analyze Quizzes",  value = "analyze",
                            h2('Retrieve submissions'),
                            actionButton("retrieve", "Retrieve submissions from shiny server", class = "actionbutton"),
                            h2('Analyze submissions'),
                            actionButton("analyze", "Analyze submissions from shiny server", class = "actionbutton"),
                   ) #close "Analyze" tab
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
