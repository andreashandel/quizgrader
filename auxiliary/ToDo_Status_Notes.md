# Main importance

* Continue transitioning structure away from gradelist.
  + Most (if not all) dependent functions are redirected to studentlist. Need to verify.
  + Incorporate summarize_course.R into quizmanager.R app.
  + Use generated course summary (not incorporated) and compile_submission_logs.R (incorporated) to compute_student_stats.R upon submission in app.R

* Trial compile_submission_logs.R for course analysis purposes in quizmanager.R app.

* Get grading app to work using the self-hosted shiny server setup.

* Figure out and implement setup for quiz/course maintenance while course is running.

* Keep updating vignettes.

* UI alterations
  + Friendlier UI with built-in walkthrough. May play with CSS for navbarPage().
  + Separation of "Creating Course", "Modifying Course", "Analysis"?




# Medium importance

* Get quiz deletion to work in quizmanager.

* Add code that creates subfolders in studentsubmissions for each quiz. Should either happen when grade tracking list is created or during deployment package. 
  + Subfolders are created when grade tracking list is created. Also, submissions are placed into quizid subfolder when submitted. **Need to make sure this doesn't overwrite files once class is in session.**





# Minor priority

* Allow adding multiple quizzes at a time through quizmanager shiny app

* Need to harmonize quizgrader and the solution files from DSAIDE and DSAIRM

* Regrade functionality?





# General Notes

How to do data storage with shinyappsio
https://shiny.rstudio.com/articles/persistent-data-storage.html

Keeping a temporary "archive" of old scripts within auxilliary.

## Newest functionality

### 14 June 2021

New function read_studentlist.R; pretty much same as read_gradelist.R was.

Now, submissions are saved in two formats: raw submission excel file and an adaptation of the result table (referred to as submission logs). 

New function to process the submission logs (compile_submission_logs.R) seems to work well for a single studentid; need to test it on a batch of studentids as this will be used for the analysis tab of quizmanager.R app. These are saved as simple text files. 

Another new function generates a summary of the quizzes in the complete quizzes folder (summarize_course.R). A rather small function. Still undecided where to incorporate this into the workflow; likely it will have its own "page" on quiz manager app to review before deployment, but it does need to be generated automatically for downstream purposes. This could be potentially inefficient to do repeatedly as it does read each excel file separately (it may be possible to have some code to query the closed excel file? But would require VBA so not sure if feasible, needed.). Would be good basis for generating "schedule" that teachers could give students / include in syllabus.

Without the gradelist, the largest speedbump (so far) is the functionality of compute_student_stats.R to give a "progress report" upon submission. Without gradelist, there is no simple readfile and average scores. However, the above two functions that compile the submissions logs and generate a summary of quizzes will be used together to generate stats. I will merge submission logs to course summary to compute to-date statistics (avoiding problem of missing quizzes in calculations and no associated due dates). For now, the compute_student_stats.R output is omitted from app.R in place of the raw submissions log (to be fixed ASAP).

Due date and attempts road blocks in place. Reading solution file before submission file allows both. Due date checked first comparing system date to due date within solution file. Attempts then checked comparing attempt number in solution file to a count of "studentid-quizid-.xlsx" files saved in the submissions folder.

quizmanager.R app is paginated. Buttons work, but need better placement.
