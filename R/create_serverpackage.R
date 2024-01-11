#' @title Create zip file for deployment containing all needed folders and files
#'
#' @description This function takes all files and folders
#' needed for the server and places it in a zip file.
#' The user then needs to copy the files to the server
#' and unzip them in the app directory.
#'
#' @param courselocation Path to main course directory
#' @param newpackage If true, all files needed for initial setup are copied, otherwise only those needed for updates
#' @return msg Null if quiz generation was successful,
#' otherwise contains an error message
#' @export


#function that takes list of file names, keeps only indicated columns
#saves them to indicated location
#this also runs check_studentlist, check_quiz and create_studentquizzes
create_serverpackage <- function(courselocation, newpackage = TRUE)
{

    #will contain either an error or success message
    msg <- NULL

    #check that course location exits is performed in calling function quizmanager.R
    #but we do it again here for those times when a user doesn't go through the shiny interface
    if (is.null(courselocation))
    {
        msg <- "Please set the course location"
        return(msg)
    }

    ###########################################
    #first, check that all documents are correct
    ############################################

    # check roster
    studentlistfile <- fs::dir_ls(fs::path(courselocation,"studentlist"))
    studentdf <- readxl::read_xlsx(studentlistfile, col_types = "text", col_names = TRUE)
    msg <- quizgrader::check_studentlist(studentdf)
    if (!is.null(msg))
    {
        return(msg) #something didn't go right when checking student list/roster, return with error message
    }

    #check all quizzes
    listfiles <- fs::dir_ls(fs::path(courselocation,"completequizzes"))
    for (nn in 1:length(listfiles))
    {
        # Load each quiz and check that is in the required format
        quizdf <- readxl::read_excel(listfiles[nn], col_types = "text", col_names = TRUE)
        msg <- check_quiz(quizdf)
        if (!is.null(msg))
        {
            return(msg) #something didn't go right when checking a quiz, return with error message
        }
    }

    #also, recreate fresh student quiz docs
    msg <- quizgrader::create_studentquizzes(courselocation)
    if (!is.null(msg))
    {
        return(msg) #something didn't go right when checking quizzes
    }




    ######################################################################
    #if all the checks above run ok, continue to make the server package
    ######################################################################

    #create zip file of all files and folders for deployment
    #place zip file in top directory of course

    #give each server package file a timestamp to prevent accidental confusion about which is the latest
    timestamp = format(Sys.time(), '%Y_%m_%d_%H_%M_%S')
    zipfilename = fs::path(courselocation, paste0("serverpackage_",timestamp,".zip"))

    #add completequizzes folder and contents
    zip::zip(zipfile = zipfilename, files = fs::path(courselocation,"completequizzes"),
                                    mode = "cherry-pick",
                                    recurse = TRUE, include_directories = FALSE)

    #add studentlist folder and contents
    zip::zip_append(zipfile = zipfilename, files = fs::path(courselocation,"studentlist"),
                    mode = "cherry-pick",
                    recurse = TRUE, include_directories = FALSE)

    #add gradelist folder and contents
    zip::zip_append(zipfile = zipfilename, files = fs::path(courselocation,"gradelist"),
                    mode = "cherry-pick",
                    recurse = TRUE, include_directories = FALSE)

    if (newpackage == TRUE)
    {
        #add the grading app
        zip::zip_append(zipfile = zipfilename, files = fs::path(fs::path_package(package = "quizgrader","quizgrader"),"app.R"),
                        mode = "cherry-pick",
                        recurse = TRUE, include_directories = FALSE)
        #add css file
        zip::zip_append(zipfile = zipfilename, files = fs::path(fs::path_package(package = "quizgrader","quizgrader"),"quizgrader.css"),
                        mode = "cherry-pick",
                        recurse = TRUE, include_directories = FALSE)

        #add folder that will/does contain student submissions and logs
        #this folder might initially be empty
        zip::zip_append(zipfile = zipfilename, files = fs::path(courselocation,"studentsubmissions"),
                        mode = "cherry-pick",
                        recurse = TRUE, include_directories = TRUE)

    }

    #if things worked ok, return a success message
    if (is.null(msg))
    {
      msg <- paste0('The file ',zipfilename,' has been created for deployment to the shiny server.')
    }

    return(msg)

} #end function


