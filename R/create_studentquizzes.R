#' @title Create student quizzes from full quiz sheets
#'
#' @description This function takes all complete quiz Excel sheets.
#' It checks each quiz sheet for proper formatting.
#' It then strips some of the content and produces quiz sheets
#' to be given to students for filling out.
#' It places those quiz sheets into the student_quiz_sheets folder
#'
#' @param courselocation Path to main course directory
#' @return errormsg Null if quiz generation was successful,
#' otherwise contains an error message
#' @export


#function that takes list of file names, keeps only indicated columns
#saves them to indicated location
create_studentquizzes <- function(courselocation)
{

    #error message if things don't work, otherwise will remain NULL
    errormsg <- NULL

    #columns to keep in the student quiz sheet
    columns_to_keep = c(
        "QuizID",
        "QuestionID",
        "Question",
        "Instruction",
        "Answer"
    )

    #path to complete quizzes
    completequizpath = fs::path(courselocation,"completequizzes")
    #get all file names for quiz files, with path
    completequizfiles = fs::dir_ls(completequizpath, glob = "*.xlsx")

    #clean out any previous student quizzes by deleting and rebuilding the student quiz folder
    studentquizpath = fs::path(courselocation,"studentquizzes")
    fs::dir_delete(studentquizpath)
    fs::dir_create(studentquizpath)

    #loop over all complete quizzes and generate student versions
    for (i in 1:length(completequizfiles))
    {
        #load complete solution sheet
        quizdf <- readxl::read_excel(completequizfiles[i], col_types = "text", col_names = TRUE)

        if (!tibble::is_tibble(quizdf))
        {
            #something didn't go right
            #read_excel should have returned an error message
            #send that message to calling function
            return(quizdf)
        }


        ##############################
        # Check that file is a quiz sheet in the required format.
        ##############################
        errormsg <- check_quiz(quizdf)
        if (!is.null(errormsg))
        {
            return(paste0('File ',completequizfiles[i]," has this problem: ",errormsg))
        }

        ##############################
        # Make a sheet for the students
        ##############################

        #select columns to keep
        quizdf <- quizdf[columns_to_keep]

        #add empty answer column
        quizdf$Answer = ""

        #save sheets for students
        #naming is original file name with _student appended

        quizname = fs::path_file(completequizfiles[i])
        #replace complete in the title with _student
        studentfilename = gsub("_complete","_student",quizname)
        studentfile_fullname = fs::path(studentquizpath, studentfilename)
        writexl::write_xlsx(quizdf, studentfile_fullname, col_names = TRUE, format_headers = TRUE)

    }

    #finally, create zip file of all student quizzes
    #place zip file in the same folder
    # create zip file
    zipfilename = fs::path(studentquizpath,"studentquizsheets.zip")
    allstudentfiles = fs::dir_ls(studentquizpath)
    zip::zipr(zipfile = zipfilename, files = allstudentfiles, recurse = FALSE, include_directories = FALSE)

    #if things worked ok, return NULL
    return(errormsg)

} #end function


