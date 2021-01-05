#' @title Set up structure for a new course through shiny
#'
#' @description This function is called from the main shiny menu
#' it asks for a course name and a location for the course
#' it then sends it on to the start_course function
#' which creates template folders and files for quizzes
#' to be filled by the teacher
#'
#'
#' @return The script creates folders.
#' If things went well, a message is returned stating where the new course was created.
#' Otherwise an error message is returned.
#' @export



start_course_shiny <- function(coursename, courselocation = NULL)
{

  # try to make provided path string valid if provided manually
  # shouldn't be an issue if this function is called through GUI

  coursepath = normalizePath(courselocation)

  #make directories for course and sub-folders
  newfolder = file.path(coursepath,coursename)
  if (dir.exists(newfolder))
  {
    errormsg = "Folder already exists! Please delete the existing folder or choose a different course name."
    return(errormsg) #stop rest of function/script
  }
  else
  {
    brows
    dir.create(newfolder)
    dir.create(file.path(newfolder,'courselists'))
    dir.create(file.path(newfolder,'student_quiz_sheets'))
    dir.create(file.path(newfolder,'complete_quiz_sheets'))
    dir.create(file.path(newfolder,'student_submissions'))
  }

  #copy templates of files into folders
  #templates are stored as part of the quizgrader package
  templatedir <<- system.file("templates", package = 'quizgrader') #find location of template path
  #copy the courselist template
  file.copy(from = file.path(templatedir,'courselist_template.xlsx'), to = file.path(newfolder,'courselists','courselist_template.xlsx') )
  #copy the quiz template
  file.copy(from = file.path(templatedir,'quiz_template.xlsx'), to = file.path(newfolder,'complete_quiz_sheets','quiz_template.xlsx') )





  #if no errors occurred above (which would lead to early return)
  #write and return a success message here
  errormsg = paste0("The new course folder and its subfolders have been created at: ",newfolder)
  return(errormsg)

} #end main function




