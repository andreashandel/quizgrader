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

    #error message if things don't work, otherwise will remain NULL
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
    studentlistfile <- fs::dir_ls(fs::path(courselocation,"studentlists"))
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
    zipfilename = fs::path(courselocation,"serverpackage.zip")

    #add completequizzes folder and contents
    zip::zip(zipfile = zipfilename, files = fs::path(courselocation,"completequizzes"),
                                    mode = "cherry-pick",
                                    recurse = TRUE, include_directories = FALSE)

    #add studentlist folder and contents
    zip::zip_append(zipfile = zipfilename, files = fs::path(courselocation,"studentlists"),
                    mode = "cherry-pick",
                    recurse = TRUE, include_directories = FALSE)

    if (newpackage == TRUE)
    {
        #add the grading app
        zip::zip_append(zipfile = zipfilename, files = fs::path(fs::path_package(package = "quizgrader","apps"),"app.R"),
                        mode = "cherry-pick",
                        recurse = TRUE, include_directories = FALSE)
        #add css file
        zip::zip_append(zipfile = zipfilename, files = fs::path(fs::path_package(package = "quizgrader","apps"),"quizgrader.css"),
                        mode = "cherry-pick",
                        recurse = TRUE, include_directories = FALSE)

        #if exists, add file with additional grades
        gradelistfile = fs::path(courselocation,"gradelist.xlsx")
        if (fs::file_exists(gradelistfile))
        {
          zip::zip_append(zipfile = zipfilename, files = gradelistfile,
                          mode = "cherry-pick",
                          recurse = TRUE, include_directories = FALSE)
        }


        #add folder for submissions and logs
        #this folder might initially be empty
        zip::zip_append(zipfile = zipfilename, files = fs::path(courselocation,"studentsubmissions"),
                        mode = "cherry-pick",
                        recurse = TRUE, include_directories = TRUE)

    }

    #if things worked ok, return NULL
    return(msg)

} #end function


