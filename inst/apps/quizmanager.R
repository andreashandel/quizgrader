######################################################
# This app is part of quizgrader
# It provides a frontend for instructors to manage their course quizzes
# It helps both in preparing the quizzes and analyzing student submissions
######################################################


##############################################
#Set up some variables, define all as global (the <<- notation)
#name of R package
packagename <<- "quizgrader"
#find path to apps
#appdir <<- system.file("appinformation", package = packagename) #find path to apps
#modeldir <<- system.file("mbmodels", package = packagename) #find path to apps
#templatedir <<- system.file("templates", package = packagename) #find path to apps
#load app table that has all the app information
#at <<- read.table(file = paste0(appdir,"/apptable.tsv"), sep = '\t', header = TRUE)
#appNames <<- at$appid
#path to simulator function zip file

quiztemplatefile <<- file.path(system.file("templates", package = packagename),"quiz_template.xlsx")
studentlisttemplatefile <<- file.path(system.file("templates", package = packagename),"studentlist_template.xlsx")




#######################################################
#server part for shiny app
#######################################################

server <- function(input, output) {



        #######################################################
        #start code block that creates a new course
        #######################################################

        shinyDirChoose(input, 'dir', roots = c(home = '~'), filetypes = c('', 'txt','bigWig',"tsv","csv","bw"))

        dir <- reactive(input$dir)
        output$dir <- renderText({parseDirPath(c(home = '~'), dir())})

        observeEvent(
                ignoreNULL = TRUE,
                eventExpr = {
                        input$dir
                },
                handlerExpr = {
                        home <- normalizePath("~")
                        datapath <<- file.path(home, paste(unlist(dir()$path[-1]), collapse = .Platform$file.sep))
                }
        )


        observeEvent(input$startcourse, {

                if (coursename == "")
                {
                        msg <- "Please choose a course name"
                }

                msg <- quizgrader::start_course(coursename, input$coursefolder)

                showModal(modalDialog(
                        msg,
                        easyClose = FALSE
                ))


        })

        #######################################################
        #start code block that loads new student list
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
        #start code block that loads new student list
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
                            textInput(coursename,label = "Course Name"),
                            shinyDirButton("dir", "Input directory", "Upload"),
                            verbatimTextOutput("dir", placeholder = TRUE),  # added a placeholder
                            actionButton("startcourse", "Start new course", class = "actionbutton"),
                            fluidRow(
                                    column(4,

                                           downloadButton("getstudentlist", "Get studentlist template", class = "actionbutton"),

                                           downloadButton("getquiztemplate", "Get quiz template", class = "actionbutton"),

                                    ),
                                    class = "mainmenurow"
                            ), #close fluidRow structure for input

                            actionButton("addstudentlist", "Add filled studentlist to course", class = "actionbutton"),

                            actionButton("addquizzes", "Add quizzes to course", class = "actionbutton"),

                            actionButton("createstudentquizzes", "Create student quiz files", class = "actionbutton"),

                            p(textOutput("warningtext")),

                            fluidRow(

                                    column(12,
                                           actionButton("Exit", "Exit", class="exitbutton")
                                    ),
                                    class = "mainmenurow"
                            ) #close fluidRow structure for input

                   ), #close "Manage" tab

                   tabPanel("Analyze Quizzes",  value = "analyze",
                            fluidRow(
                                    column(12,
                                           uiOutput('analyzemodel')
                                    ),
                                    class = "mainmenurow"
                            ) #close fluidRow structure for input
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
