#' @title The main menu for creating and administering quizzes
#'
#' @description This function opens a Shiny app called quizgrader with a menu
#' that allows the user to perform all relevant operations.
#'
#' @details Run this function with no arguments to start the main menu (a Shiny app)
#' @examples
#' \dontrun{quizmanager()}
#' @author Andreas Handel
#' @import shiny
#' @export

quizmanager <- function() {

    appDir <- system.file( "apps", package = "quizgrader") #get directory for main menu app
    appFile <- shinyAppFile(file.path(appDir,"quizmanager_app.R"))
    shiny::runApp(appDir = appFile) #run quizmanager app

    print('*************************************************')
    print('Exiting the quizmanager main menu.')
    print('I hope you had a productive session!')
    print('*************************************************')
}

#needed to prevent NOTE messages on CRAN checks
#utils::globalVariables(c("xvals", "yvals", "varnames","IDvar","style","Condition", "simfunction","flu1918data","norodata"))


.onAttach <- function(libname, pkgname){
  packageStartupMessage("Welcome to the quizgrader package. Type quizmanager() to get started.")
}
