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

        #if user clicks the button to select a folder for new course
        observeEvent(input$newcoursedir, {
                shinyFiles::shinyDirChoose(input, "newcoursedir", roots = volumes, session = session, restrictions = system.file(package = "base"), allowDirCreate = FALSE)
                courselocation <<- shinyFiles::parseDirPath(volumes, input$newcoursedir)
                output$newcoursedir <- renderPrint(courselocation)
                output$coursedir <- renderPrint(courselocation)
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
                        #run start_course function to make new folders and populate with files for the course
                        errorlist <- quizgrader::start_course(isolate(input$coursename), isolate(newcoursedir))
                        msg <- errorlist$message #message to display showing if things worked or not
                }
                if (errorlist$status == 0) #if start_course worked well, assign directory to global variable
                {
                        #save course folder to global variable
                        courselocation <<- fs::path(isolate(newcoursedir), isolate(input$coursename))
                        #show the directory to the new course
                        output$coursedir <- renderPrint(courselocation)

                }
                showModal(modalDialog(msg, easyClose = FALSE))
        })


        #######################################################
        #start code block that selects an existing course folder
        #this is used for working on an existing course
        #######################################################
        observeEvent(input$coursedir, {
                shinyFiles::shinyDirChoose(input, "coursedir", roots = volumes, session = session, restrictions = system.file(package = "base"), allowDirCreate = FALSE)
                courselocation <<- shinyFiles::parseDirPath(volumes, input$coursedir)
                output$coursedir <- renderPrint(courselocation)
        })



        #######################################################
        #start code block that gives users the student list template
        #this file is pulled out of the package, it's not the file copied over into the course
        #this prevents/minimizes accidental editing of the template
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
                        #timestamp = gsub(" ","_",gsub("-","_", gsub(":", "_", Sys.time())))
                        #find path to course folder
                        #filename = paste0("studentlist","_",timestamp,'.xlsx')

                        new_path = fs::path(courselocation, 'studentlists', input$addstudentlist$name)

                        #copy time-stamped file to student list folder
                        fs::file_copy(path = input$addstudentlist$datapath,  new_path = new_path)

                        msg <- paste0("student list has been saved to ", new_path)
                }
                showModal(modalDialog(msg, easyClose = FALSE))
        })


        #######################################################
        #start code block that adds filled quizzes to course
        #also checks quizzes
        #######################################################
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
                        # Load quiz and check that is in the required format
                        quizdf <- readxl::read_excel(input$addquiz$datapath, col_types = "text", col_names = TRUE)
                        msg <- check_quiz(quizdf)
                        if (is.null(msg)) #if no problem occurred, try copying
                        {
                                #find path to course folder
                                newname = paste0(quizdf$QuizID[1],'_complete.xlsx')
                                new_path = file.path(courselocation,"completequizzes",newname)
                                #copy renamed file to completequiz folder
                                fs::file_copy(path = input$addquiz$datapath, new_path = new_path, overwrite = TRUE)
                                msg <- paste0("quiz has been saved to ", new_path)
                        } #if check worked, copy file
                } #end if for
                showModal(modalDialog(msg, easyClose = FALSE))
        })


        #######################################################
        #start code block that removes quizzes from course
        #######################################################

        observeEvent(input$removequiz,{

                if (is.null(courselocation)) #not sure why integer, but that's how the example is
                {
                        msg <- "Please set the course location"
                        shinyjs::reset(id  = "removequiz")
                } else {
                        volumes = c(Coursefolder = fs::path(courselocation,"completequizzes"))
                        shinyFiles::shinyFileChoose(input, "removequiz", roots = volumes, session = session)
                        deletefile <- shinyFiles::parseFilePaths(volumes, input$removequiz) #save course folder to global variable
                        #file.remove(deletefile)
                        browser()
                        msg <- paste0("this quiz has been removed:", deletefile)
                }
                showModal(modalDialog(msg, easyClose = FALSE))
        })




        #######################################################
        #start code block that turns filled quizzes
        #into student quizzes
        #######################################################
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

        #######################################################
        #start code block that returns zip file of student quizzes
        #######################################################
        output$getstudentquizzes <- downloadHandler(
                        filename <- function() {
                                "studentquizsheets.zip"
                        },
                        content <- function(file) {
                                file.copy(file.path(courselocation,'studentquizzes',"studentquizsheets.zip"), file)
                        },
                        contentType = "application/zip"
                )


        #######################################################
        #start code block that takes student list
        #and adds info for all quizzes to the main grade tracking sheet
        #######################################################
        observeEvent(input$creategradelist,{

                if (is.null(courselocation))
                {
                        msg <- "Please set the course location"
                        shinyjs::reset(id  = "createstudentquizzes")
                } else {

                        #first, generate student versions to make sure everything is in sync
                        msg <- quizgrader::create_student_quizzes(courselocation)

                        if (!is.null(msg)) #this means it didn't work
                        {
                                msg <- paste0('Something went wrong creating the student quiz sheets, please run that process separately.')
                        } else {

                                #run function to generate main grade tracking sheet
                                msg <- quizgrader::create_gradelist(courselocation)

                                if (is.null(msg)) #this means it worked
                                {
                                        msg <- paste0('The grade tracking sheet has been created and copied to ', file.path(courselocation,'gradelists'))
                                }

                        } #end inner else statement
                } #end outer else statement
                showModal(modalDialog(msg, easyClose = FALSE))
        }) #end creategradelist code block



        #######################################################
        #start code block that combines and zips documents needed for initial deployment
        #######################################################
        observeEvent(input$makepackage,{

                if (is.null(courselocation))
                {
                        msg <- "Please set the course location"
                        shinyjs::reset(id  = "createstudentquizzes")
                } else {
                        #make zip file
                        msg <- quizgrader:: make_package(courselocation, newpackage = TRUE)
                        if (is.null(msg)) #this means it worked
                        {
                                msg <- paste0('The serverpackage.zip file for deployment has been created and copied to ', file.path(courselocation))
                        }
                }
                showModal(modalDialog(msg, easyClose = FALSE))
        }) #end code block that zips files/folders needed for initial deployment



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
                        msg <- quizgrader:: make_package(courselocation, newpackage = FALSE)
                        if (is.null(msg)) #this means it worked
                        {
                                msg <- paste0('The serverpackage.zip file for updates has been created and copied to ', file.path(courselocation))
                        }
                }
                showModal(modalDialog(msg, easyClose = FALSE))
        }) #end code block that zips files/folders needed for updates


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
        p('Happy teaching!', class='maintext'),
        navbarPage(title = "quizmanager", id = 'alltabs', selected = "manage",
                   tabPanel(title = "Manage quizzes", value = "manage",
                            h2('Start a new Course'),
                            textInput("coursename",label = "Course Name"),
                            shinyFiles::shinyDirButton("newcoursedir", "Set parent directory for new course", "Select a parent folder for new course"),
                            verbatimTextOutput("newcoursedir", placeholder = TRUE),  # added a placeholder
                            actionButton("startcourse", "Start new course", class = "actionbutton"),
                            h2('Load existing Course'),
                            shinyFiles::shinyDirButton("coursedir", "Find existing course", "Select an existing course folder"),
                            verbatimTextOutput("coursedir", placeholder = TRUE),  # added a placeholder
                            h2('Get template files'),
                            downloadButton("getstudentlist", "Get studentlist template", class = "actionbutton"),
                            downloadButton("getquiztemplate", "Get quiz template", class = "actionbutton"),
                            h2('Add student list to course'),
                            fileInput("addstudentlist", label = "", buttonLabel = "Add filled studentlist to course", accept = '.xlsx'),
                            h2('Manage complete quizzes'),
                            shiny::fileInput("addquiz", label = "", buttonLabel = "Add a completed quiz to course", accept = '.xlsx'),
                            p('Any quiz with the same file name as the one being added will be overwritten.'),
                            shinyFiles::shinyFilesButton("removequiz", label = "Remove quiz", title = "Remove a quiz from the course", multiple = TRUE),
                            h2('Make student quizzes'),
                            actionButton("createstudentquizzes", "Create student quiz files", class = "actionbutton"),
                            downloadButton("getstudentquizzes", "Get zip file with all student quiz files", class = "actionbutton"),
                            h2('Make grade list'),
                            actionButton("creategradelist", "Generate grade tracking list", class = "actionbutton"),
                            h2('Deploy course'),
                            actionButton("makepackage", "Make zip file for initial deployment", class = "actionbutton"),
                            actionButton("updatepackage", "Make zip file for updates", class = "actionbutton"),
                            #actionButton("deploycourse", "Deploy course to shiny server", class = "actionbutton"),
                            p(textOutput("warningtext")),

                            fluidRow(

                                    column(12,
                                           actionButton("Exit", "Exit", class="exitbutton")
                                    ),
                                    class = "mainmenurow"
                            ) #close fluidRow structure for input

                   ), #close "Manage" tab

                   tabPanel("Analyze Submissions",  value = "analyze",
                            h2('Retrieve submissions'),
                            actionButton("retrieve", "Retrieve submissions from shiny server", class = "actionbutton"),
                            h2('Analyze submissions'),
                            actionButton("analyze", "Analyze submissions", class = "actionbutton"),
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
