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
#' @return The script creates folders.
#' If things went well, folders a created and a NULL message is returned.
#' Otherwise an error message is returned.
#' @export



start_course <- function(coursename, courselocation = NULL)
{

  errormessage <- NULL #if things went wrong, provide an error mssage

  # try to make provided path string valid if provided manually
  # currently needs double \\ on windows, e.g. "C:\\testfolder\"
  # shouldn't be an issue if this function is called through GUI
  courselocation = normalizePath(courselocation)

  #make directories for course and sub-folders
  newfolder = file.path(courselocation,coursename)
  if (dir.exists(newfolder))
  {
    errormessage = "Folder already exists! Please delete the existing folder or choose a different course name."
    return(errormessage) #stop rest of function/script
  }
  else
  {
    dir.create(newfolder)
    dir.create(file.path(newfolder,'studentlists')) #for student roster files
    dir.create(file.path(newfolder,'gradelists')) #for file(s) that tracks all grades
    dir.create(file.path(newfolder,'studentquizzes')) #for quiz sheets to be given to students
    dir.create(file.path(newfolder,'completequizzes')) #for complete quiz sheets
    dir.create(file.path(newfolder,'studentsubmissions')) #will contain all student submissions
  }

  #copy templates of files into folders
  #templates are stored as part of the quizgrader package
  templatedir <<- system.file("templates", package = 'quizgrader') #find location of template path
  #copy the courselist template
  file.copy(from = file.path(templatedir,'studentlist_template.xlsx'), to = file.path(newfolder,'studentlists','studentlist_template.xlsx') )
  #copy the quiz template
  file.copy(from = file.path(templatedir,'quiz_template.xlsx'), to = file.path(newfolder,'completequizzes','quiz_template.xlsx') )

  #if no errors occurred above (which would lead to early return)
  #return NULL
  return(errormessage)

} #end main function




