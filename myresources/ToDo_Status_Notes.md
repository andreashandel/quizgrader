# Andreas comments


# ToDo 

* At some point, rename all studentID to username.
* Fix check for valid course when user opens existing course in quizmanager_app.* Fix all bugs that happen especially when no course exists yet.
* Thorough testing of all quizmanager functionality.




### QUIZMANAGER


MANAGEMENT


GENERAL


# ToDo for later

* investigate ShinyApps server deployment
* Need to harmonize quizgrader and the solution files from DSAIDE and DSAIRM
* Can we change look of disabled tabs?
* Do error check and catch if user tries to load non-Excel files (right now readxl throws an error)
* Maybe reorganize quizmanager UI
* Keep updating vignettes.


# General Notes

How to do data storage with shinyappsio
https://shiny.rstudio.com/articles/persistent-data-storage.html

Keeping a temporary "archive" of old scripts within auxilliary.

Possibly interesting package for interacting with dropbox:
https://github.com/karthik/rdrop2


# Resources

* There is a gradeR R package: https://cran.r-project.org/web/packages/gradeR/index.html
* Another similar package: https://cran.r-project.org/web/packages/ProfessR/
* A package to grade learnr documents: https://rstudio-education.github.io/gradethis/
https://cran.r-project.org/web/packages/exams/index.html




#############################
### Old/Archived information
#############################

## 14 June 2021

New function read_studentlist.R; pretty much same as read_gradelist.R was.

Now, submissions are saved in two formats: raw submission excel file and an adaptation of the result table (referred to as submission logs). 

New function to process the submission logs (compile_submission_logs.R) seems to work well for a single studentid; need to test it on a batch of studentids as this will be used for the analysis tab of quizmanager.R app. These are saved as simple text files. 

Another new function generates a summary of the quizzes in the complete quizzes folder (summarize_course.R). A rather small function. Still undecided where to incorporate this into the workflow; likely it will have its own "page" on quiz manager app to review before deployment, but it does need to be generated automatically for downstream purposes. This could be potentially inefficient to do repeatedly as it does read each excel file separately (it may be possible to have some code to query the closed excel file? But would require VBA so not sure if feasible, needed.). Would be good basis for generating "schedule" that teachers could give students / include in syllabus.

Without the gradelist, the largest speedbump (so far) is the functionality of compute_student_stats.R to give a "progress report" upon submission. Without gradelist, there is no simple readfile and average scores. However, the above two functions that compile the submissions logs and generate a summary of quizzes will be used together to generate stats. I will merge submission logs to course summary to compute to-date statistics (avoiding problem of missing quizzes in calculations and no associated due dates). For now, the compute_student_stats.R output is omitted from app.R in place of the raw submissions log (to be fixed ASAP).

Due date and attempts road blocks in place. Reading solution file before submission file allows both. Due date checked first comparing system date to due date within solution file. Attempts then checked comparing attempt number in solution file to a count of "studentid-quizid-.xlsx" files saved in the submissions folder.

quizmanager.R app is paginated. Buttons work, but need better placement.


