######################################################
# This app is part of quizgrader
# It provides a frontend for instructors to manage their course quizzes
# It helps both in preparing the quizzes and analyzing student submissions
######################################################



#######################################################
#UI for shiny app
#######################################################

ui <- fluidPage(
        shinyjs::useShinyjs(),

        titlePanel("Quiz mamager"),

        actionButton("newcourse", "Start new course", class = "actionbutton"),

        actionButton("getstudentlist", "Get studentlist template", class = "actionbutton"),

        actionButton("addstudentlist", "Add filled studentlist to course", class = "actionbutton"),

        actionButton("getquiztemplate", "Get quiz template", class = "actionbutton"),

        actionButton("addquizzes", "Add quizzes to course", class = "actionbutton"),

        actionButton("createstudentquizzes", "Create student quiz files", class = "actionbutton"),

        p(textOutput("warningtext"))
)

#######################################################
#server part for shiny app
#######################################################

server <- function(input, output) {


}

# Run the application
shinyApp(ui = ui, server = server)
