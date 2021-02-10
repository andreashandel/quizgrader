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
create_student_quizzes <- function(courselocation)
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


    #clean out any previous student quizzes by deleting and rebuilding the student quiz folder
    studentquizpath = fs::path(courselocation,"studentquizzes")
    dir_delete(studentquizpath)
    dir_create(studentquizpath)

    #path to complete quizzes
    completequizpath = fs::path(courselocation,"completequizzes")
    #get all file names
    completequizfiles = fs::dir_ls(completequizpath, glob = "*.xlsx")


    for (i in 1:length(allfiles))
    {
        #load complete solution sheet
        nowfile <- readxl::read_excel(allfiles[i], col_types = "text")

        ##############################
        # Check that file is a quiz sheet in the required format.
        ##############################
        check_quiz(nowfile)


        ##############################
        # Make a sheet for the students
        ##############################

        #so we can supply column names that might or might not be in the sheets
        #and only select them if they exist, otherwise we get an error message
        actual_cols_to_keep = intersect(columns_to_keep, colnames(nowfile))
        #select columns to keep
        nowfile <- nowfile[actual_cols_to_keep]

        #add empty answer column
        nowfile$Answer = ""

        #save sheets for students
        #naming is original file name with _student appended
        studentfilename = paste0("student_",allfilenames[i])
        studentfile_fullname = file.path(studentquizpath,studentfilename)
        writexl::write_xlsx(nowfile, studentfile_fullname)
    }

    #finally, create zip file from all files
    # create zip file
    zipfilename = file.path(studentquizpath,"studentquizsheets.zip")
    allstudentfiles = list.files(studentquizpath, full.names = TRUE)
    zip::zipr(zipfile = zipfilename, files = allstudentfiles, recurse = FALSE, include_directories = FALSE)

    #currently no error checking implemented
    return(errormsg)

} #end function


