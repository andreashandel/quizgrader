#' @title The main menu for creating and administering quizzes
#'
#' @description This function opens a Shiny app called quizmanager_app with a menu
#' that allows the user to perform all relevant quiz management operations.
#'
#' @details Run this function with no arguments to start the main menu (a Shiny app).
#' You can also provide a path to an existing course directory.
#' @param courselocation Path to main course directory
#' @examples
#' \dontrun{quizmanager()}
#' @author Andreas Handel
#' @importFrom stringr str_replace
#' @import shiny
#' @importFrom shinyjs enable
#' @importFrom shinyFiles getVolumes
#' @importFrom utils globalVariables
#' @export

# Note the imports above. That's because those packages are used by the apps which are in /inst not /R
# and therefore R/CRAN checks would complain

quizmanager <- function(courselocation = NULL) {

    # if user provides location of existing course
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
    # if user doesn't provide location of existing course
    } else {
      #set course location to global variable and to NULL
      courselocation_global <<- NULL
    }

    appDir <- system.file( "quizmanager", package = "quizgrader") #get directory for main menu app
    appFile <- shiny::shinyAppFile(file.path(appDir,"app.R"))
    shiny::runApp(appDir = appFile, launch.browser = TRUE) #run quizmanager app

    print('*************************************************')
    print('Exiting the quizmanager main menu.')
    print('I hope you had a productive session!')
    print('*************************************************')

    # clean up at end
    courselocation_global <<- NULL

}

# needed to get CRAN checks to shut up about no visible binding
# seems better to do it this way eventually:
# https://dplyr.tidyverse.org/articles/programming.html#eliminating-r-cmd-check-notes
utils::globalVariables(c("courselocation_global", "DueDate", "QuizID", "Attempt", "QuizDueDate", "Score", "StudentID", "Submit_Date", "n_Correct", "n_Questions"))


.onAttach <- function(libname, pkgname){
  packageStartupMessage("Welcome to the quizgrader package. Type quizmanager() to get started.")
}
