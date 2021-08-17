#' @title Set up structure for a new course
#'
#' @description This function creates a new course/project
#' and creates template folders and files for quizzes
#' to be filled by the teacher
#'
#' @param coursename Name of course to be created
#' this will be the main folder name
#' and will contain sub-folders for all the materials
#' @param courselocation The location where the new course folder
#' is to be created
#'
#' @return The function creates folders an files for the new course.
#' The function returns a list containing error or success information.
#' If things went well, the list element status is 0 and a the list
#' element message is a string specifying the location of the new course folder.
#' Otherwise an error status of 1 and an error message is returned.
#' @export

create_course <- function(coursename, courselocation = NULL)
{

  #return error status/message
  errorlist = list(status = 0, message = NULL)

  #if no course location is provided use working directory
  if (is.null(courselocation)) {courselocation = getwd()}

  #set new course directory
  #make directories for course and sub-folders
  newfolder = fs::path(courselocation,coursename)
  if (dir.exists(newfolder))
  {
    errorlist$status = 1
    errorlist$message = "Folder already exists! Please delete the existing folder or choose a different course name."
    return(errorlist) #stop rest of function/script
  }
  else
  {
    fs::dir_create(newfolder)
    fs::dir_create(fs::path(newfolder,'templates')) #contains template files submissions

    fs::dir_create(fs::path(newfolder,'studentlists')) #for student roster files
    fs::dir_create(fs::path(newfolder,'completequizzes')) #for complete quiz sheets
    fs::dir_create(fs::path(newfolder,'studentquizzes')) #for quiz sheets to be given to students

    fs::dir_create(fs::path(newfolder,'studentsubmissions')) #will contain all student submissions

    fs::dir_create(fs::path(newfolder,'studentsubmissions', 'logs')) #will contain student submissions log file

    #create an empty log file with just the column headers
    #this file will be filled as students start submitting
    submissions_log <- data.frame(StudentID = NA,
                                  QuizID = NA,
                                  Attempt = NA,
                                  Score = NA,
                                  n_Questions = NA,
                                  n_Correct = NA,
                                  Submit_Date = NA
                                  )

    timestamp = gsub(" ","_",gsub("-","_", gsub(":", "_", Sys.time())))

    submissions_log_filename = paste0("submissions_log_", timestamp, ".xlsx")
    submissions_log_filenamepath = fs::path(newfolder, "studentsubmissions", "logs", submissions_log_filename)
    writexl::write_xlsx(submissions_log, submissions_log_filenamepath, col_names = TRUE, format_headers = TRUE)

  }

  #copy templates of files into folders
  #templates are stored as part of the quizgrader package
  templatedir <- system.file("templates", package = 'quizgrader') #find location of template path
  #copy the courselist template
  fs::file_copy(fs::path(templatedir,'studentlist_template.xlsx'), fs::path(newfolder,'templates','studentlist_template.xlsx') )
  #copy the quiz template
  fs::file_copy(fs::path(templatedir,'quiz_template.xlsx'), fs::path(newfolder,'templates','quiz_template.xlsx') )

  #if no errors occurred above (which would lead to early return)
  #return message with location of newly created course folder and status message 0
  errorlist$status = 0
  errorlist$message = paste0("The new course folder and its subfolders have been created at: ",newfolder)

  return(errorlist)

} #end main function




