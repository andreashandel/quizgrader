


test_that("create course function works", {

   #set some temporary path
   temp_path = fs::path_temp()

   errorlist <- create_course(coursename = 'testcourse', courselocation = temp_path)

   # we assume that things went well and error status is 0
   expect_equal(errorlist$status, 0)
   # the message should contain the temp path
   expect_match(errorlist$message, temp_path)


})
