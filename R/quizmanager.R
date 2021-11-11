#' @title The main menu for creating and administering quizzes
#'
#' @description This function opens a Shiny app called quizgrader with a menu
#' that allows the user to perform all relevant operations.
#'
#' @details Run this function with no arguments to start the main menu (a Shiny app)
#' @param courselocation Path to main course directory
#' @examples
#' \dontrun{quizmanager()}
#' @author Andreas Handel
#' @import shiny
#' @importFrom magrittr %>%
#' @export

quizmanager <- function(courselocation = NULL) {

    if (!is.null(courselocation))
    {
      # check the quizgrader.txt in the provided path to ensure it's a valid quizgrader main folder
      msg <- check_courselocation(courselocation)
      if (!is.null(msg))
      {
        stop(msg) #if the quiz location check is not successful, an error message is returned. otherwise NULL.
      } else {
             courselocation_global <<- courselocation #assign course location to global variable, will then be used in quizmanager app
      }
    } else {
      #set course location to global variable and to NULL
      courselocation_global <<- NULL
    }


    appDir <- system.file( "apps", package = "quizgrader") #get directory for main menu app
    appFile <- shinyAppFile(file.path(appDir,"quizmanager_app.R"))
    shiny::runApp(appDir = appFile) #run quizmanager app

    print('*************************************************')
    print('Exiting the quizmanager main menu.')
    print('I hope you had a productive session!')
    print('*************************************************')

    # clean up at end
    courselocation <<- NULL

}

#needed to get CRAN checks to shut up about no visible binding
utils::globalVariables(c("courselocation_global", "DueDate"))



.onAttach <- function(libname, pkgname){
  packageStartupMessage("Welcome to the quizgrader package. Type quizmanager() to get started.")
}
