#' @title Create file and folder zip file for deployment
#'
#' @description This function takes all files and folders
#' needed for the server and places it in a zip file.
#' The user then needs to copy the files to the server
#' and unzip them in the app directory.
#'
#' @param courselocation Path to main course directory
#' @param newpackage If true, all files needed for initial setup are copied, otherwise only those needed for updates
#' @return errormsg Null if quiz generation was successful,
#' otherwise contains an error message
#' @export


#function that takes list of file names, keeps only indicated columns
#saves them to indicated location
create_serverpackage <- function(courselocation, newpackage = TRUE)
{

    #error message if things don't work, otherwise will remain NULL
    errormsg <- NULL

    #create zip file of all files and folders for deployment
    #place zip file in top directory of course
    zipfilename = fs::path(courselocation,"serverpackage.zip")

    #add completequizzes folder and contents
    zip::zip(zipfile = zipfilename, files = fs::path(courselocation,"completequizzes"),
                                    mode = "cherry-pick",
                                    recurse = TRUE, include_directories = TRUE)
    #add gradelists folder and contents
    zip::zip_append(zipfile = zipfilename, files = fs::path(courselocation,"gradelists"),
                    mode = "cherry-pick",
                    recurse = TRUE, include_directories = TRUE)

    if (newpackage == TRUE)
    {
        #add the grading app
        zip::zip_append(zipfile = zipfilename, files = file.path(system.file("apps", package = "quizgrader"),"app.R"),
                        mode = "cherry-pick",
                        recurse = TRUE, include_directories = TRUE)
        #add css file
        zip::zip_append(zipfile = zipfilename, files = file.path(system.file("apps", package = "quizgrader"),"quizgrader.css"),
                        mode = "cherry-pick",
                        recurse = TRUE, include_directories = TRUE)
        #add empty folder for submissions
        #also adds empty sub-folders for student submissions for each quiz to keep things more organized
        zip::zip_append(zipfile = zipfilename, files = fs::path(courselocation,"studentsubmissions"),
                        mode = "cherry-pick",
                        recurse = TRUE, include_directories = TRUE)

    }


    #if things worked ok, return NULL
    return(errormsg)

} #end function


