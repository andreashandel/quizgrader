#' @title Create student quizzes from full quiz sheets
#'
#' @description This function takes the folder location
#' that contains all complete quizzes.
#' It strips some of the content and produces quiz sheets
#' to be given to students for filling out.
#' It places those quiz sheets into the student_quiz_sheets folder
#'
#' @param courselocation Path to main course directory
#' @return errormsg Is null if quiz generation was successfull,
#' otherwise contains an error message
#' @export


#function that takes list of file names, keeps only indicated columns
#saves them to indicated location
create_student_quizzes <- function(courselocation)
{

    errormsg <- NULL

    allquizpath = file.path(courselocation,"complete_quiz_sheets")
    studentquizpath = file.path(courselocation,"student_quiz_sheets")

    allfiles = list.files(allquizpath,  full.names = TRUE)
    allfilenames = list.files(allquizpath,  full.names = FALSE)
    columns_to_keep = c(
                        "QuizID",
                        "Duedate",
                        "Attempts",
                        "QuestionID",
                        "Question",
                        "Instruction",
                        "Answer"
    )

    #empty folder where student quizzes are located
    prior_quiz_files = list.files(studentquizpath, full.names = TRUE)
    file.remove(prior_quiz_files)

    for (i in 1:length(allfiles))
    {
        #load complete solution sheet
        nowfile <- readxl::read_excel(allfiles[i], col_types = "text")

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


