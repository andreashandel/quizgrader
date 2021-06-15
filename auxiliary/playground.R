# ui <- fluidPage(
#
#   navbarPage(title = "quizmanager", id = 'alltabs', selected = "manage",
#              tabPanel(title = "Manage Course", value = "manage",
#                       navlistPanel(id = "man_sub", selected = "gettingstarted",
#                                    tabPanel("page_1",
#                                             "Welcome!",
#                                             actionButton("page_12", "next")
#                                             ),
#                                    tabPanel("page_2",
#                                             "Only one page to go",
#                                             actionButton("page_21", "prev"),
#                                             actionButton("page_23", "next")
#                                             ),
#                                    tabPanel("page_3",
#                                             "You're done!",
#                                             actionButton("page_32", "prev")
#                                             )
#                                    )
#                       ),
#              tabPanel(title = "Analyze", value = "analysis")
#              )
# )
#
# server <- function(input, output, session) {
#   switch_page <- function(i) {
#     updateTabsetPanel(inputId = "man_sub", selected = paste0("page_", i))
#   }
#
#   observeEvent(input$page_12, switch_page(2))
#   observeEvent(input$page_21, switch_page(1))
#   observeEvent(input$page_23, switch_page(3))
#   observeEvent(input$page_32, switch_page(2))
# }






#
# ui <- fluidPage(
#
#   navbarPage(title = "app", id = 'mainpage', selected = "first",
#
#              tabPanel(title = "first", value = "first",
#
#                       navlistPanel(id = "first_sublist", selected = "firstfirst",
#                       # tabsetPanel(id = "first_sublist", selected = "firstfirst",
#                                    tabPanel(title = "firstfirst", value = "firstfirst",
#
#                                             fluidRow(column(6, ""),
#                                                      column(6, align = "center", actionButton(inputId = 'goto_firstsecond', label = div('Advance to firstsecond', icon('angle-double-right'))))
#                                             )
#
#                                    ),
#                                    tabPanel(title = "firstsecond", value = "firstsecond",
#                                             "This one works",
#
#                                             fluidRow(column(6, align = "center", actionButton(inputId = 'goto_firstfirst', label = 'Return to firstfirst', icon = icon('angle-double-left'))),
#                                                      column(6, align = "center", actionButton(inputId = 'goto_firstthird', label = div('Advance to firstthird', icon('angle-double-right'))))
#                                             )
#
#                                    ),
#                                    tabPanel(title = "firstthird", value = "firstthird",
#                                             "This one does not work.",
#
#                                             fluidRow(column(6, align = "center", actionButton(inputId = 'gobackto_firstsecond', label = 'Return to firstsecond', icon = icon('angle-double-left'))),
#                                                      column(6, align = "center", actionButton(inputId = 'goto_firstfourth', label = div('Advance to firstfourth', icon('angle-double-right'))))
#                                             )
#
#                                    ),
#                                    tabPanel(title = "firstfourth", value = "firstfourth",
#                                             "This one does not work.",
#
#                                             fluidRow(column(6, align = "center", actionButton(inputId = 'goto_firstthird', label = 'Return to firstthird', icon = icon('angle-double-left'))),
#                                                      column(6, align = "center", actionButton(inputId = 'goto_firstfifth', label = div('Advance to firstfifth', icon('angle-double-right'))))
#                                             )
#
#                                    ),
#                                    tabPanel(title = "firstfifth", value = "firstfifth",
#                                             "This one does not work.",
#
#                                             fluidRow(column(6, align = "center", actionButton(inputId = 'goto_firstfourth', label = 'Return to firstfourth', icon = icon('angle-double-left'))),
#                                                      column(6, align = "center", "")
#                                             )
#                                    )
#                       )
#
#              ),
#
#              tabPanel("second",  value = "second"
#
#              )
#   )
# )
#
# server <- function(input, output, session) {
#
#     switch_page <- function(i) {
#       isolate(
#       updateNavlistPanel(inputId = "first_sublist", selected = my.pages[i])
#       # updateTabsetPanel(inputId = "first_sublist", selected = my.pages[i])
#       )
#     }
#
#     my.pages <- c("firstfirst", "firstsecond", "firstthird", "firstfourth", "firstfifth")
#
#     observeEvent(input$goto_firstfirst, switch_page(1))
#     observeEvent(input$goto_firstsecond | input$gobackto_firstsecond, switch_page(2), ignoreInit = TRUE)
#     # observeEvent(input$gobackto_firstsecond, switch_page(2))
#     observeEvent(input$goto_firstthird, isolate({switch_page(3)}))
#     observeEvent(input$goto_firstfourth, switch_page(4))
#     observeEvent(input$goto_firstfifth, switch_page(5))
#
#
#
#
#
#   # observeEvent(input$goto_firstfirst, {
#   #   updateNavlistPanel(inputId = "first_sublist",
#   #                      selected = "firstfirst")
#   # })
#   #
#   # observeEvent(input$goto_firstsecond, {
#   #   updateNavlistPanel(inputId = "first_sublist",
#   #                      selected = "firstsecond")
#   # })
#   #
#   # observeEvent(input$goto_firstthird, {
#   #   updateNavlistPanel(inputId = "first_sublist",
#   #                      selected = "firstthird")
#   # })
#   #
#   # observeEvent(input$goto_firstfourth, {
#   #   updateNavlistPanel(inputId = "first_sublist",
#   #                      selected = "firstfourth")
#   # })
#   #
#   # observeEvent(input$goto_firstfifth, {
#   #   updateNavlistPanel(inputId = "first_sublist",
#   #                      selected = "firstfifth")
#   # })
#
#
# }





#
#
# ui <- fluidPage(
#
#   navbarPage(title = "app", id = 'mainpage', selected = "first",
#
#              tabPanel(title = "first", value = "first",
#
#                       navlistPanel(id = "first_sublist", selected = "firstfirst",
#                                    # tabsetPanel(id = "first_sublist", selected = "firstfirst",
#                                    tabPanel(title = "firstfirst", value = "firstfirst",
#
#                                             fluidRow(column(6, ""),
#                                                      column(6, align = "center", actionButton(inputId = 'goto_firstsecond', label = div('Advance to firstsecond', icon('angle-double-right'))))
#                                             )
#
#                                    ),
#                                    tabPanel(title = "firstsecond", value = "firstsecond",
#                                             "This one works",
#
#                                             fluidRow(column(6, align = "center", actionButton(inputId = 'goto_firstfirst', label = 'Return to firstfirst', icon = icon('angle-double-left'))),
#                                                      column(6, align = "center", actionButton(inputId = 'goto_firstthird', label = div('Advance to firstthird', icon('angle-double-right'))))
#                                             )
#
#                                    ),
#                                    tabPanel(title = "firstthird", value = "firstthird",
#                                             "This one does not work.",
#
#                                             fluidRow(column(6, align = "center", actionButton(inputId = 'gobackto_firstsecond', label = 'Return to firstsecond', icon = icon('angle-double-left'))),
#                                                      column(6, align = "center", actionButton(inputId = 'goto_firstfourth', label = div('Advance to firstfourth', icon('angle-double-right'))))
#                                             )
#
#                                    ),
#                                    tabPanel(title = "firstfourth", value = "firstfourth",
#                                             "This one does not work.",
#
#                                             fluidRow(column(6, align = "center", actionButton(inputId = 'goto_firstthird', label = 'Return to firstthird', icon = icon('angle-double-left'))),
#                                                      column(6, align = "center", actionButton(inputId = 'goto_firstfifth', label = div('Advance to firstfifth', icon('angle-double-right'))))
#                                             )
#
#                                    ),
#                                    tabPanel(title = "firstfifth", value = "firstfifth",
#                                             "This one does not work.",
#
#                                             fluidRow(column(6, align = "center", actionButton(inputId = 'goto_firstfourth', label = 'Return to firstfourth', icon = icon('angle-double-left'))),
#                                                      column(6, align = "center", "")
#                                             )
#                                    )
#                       )
#
#              ),
#
#              tabPanel("second",  value = "second"
#
#              )
#   )
# )
#
#
#





ui <- fluidPage(
  navbarPage(title = "app", id = "main", selected = "page1",
             tabPanel("page1",
                        navbarPage("sub",
                          tabPanel("subpage1"),
                          tabPanel("subpage2")
                          )

                      ),
             tabPanel("page2")
  )
)






server <- function(input, output, session) {

  switch_page <- function(i) {
    isolate(
      updateNavlistPanel(inputId = "first_sublist", selected = my.pages[i])
      # updateTabsetPanel(inputId = "first_sublist", selected = my.pages[i])
    )
  }

  my.pages <- c("firstfirst", "firstsecond", "firstthird", "firstfourth", "firstfifth")

  observeEvent(input$goto_firstfirst, switch_page(1))
  observeEvent(input$goto_firstsecond | input$gobackto_firstsecond, switch_page(2), ignoreInit = TRUE)
  # observeEvent(input$gobackto_firstsecond, switch_page(2))
  observeEvent(input$goto_firstthird, isolate({switch_page(3)}))
  observeEvent(input$goto_firstfourth, switch_page(4))
  observeEvent(input$goto_firstfifth, switch_page(5))





  # observeEvent(input$goto_firstfirst, {
  #   updateNavlistPanel(inputId = "first_sublist",
  #                      selected = "firstfirst")
  # })
  #
  # observeEvent(input$goto_firstsecond, {
  #   updateNavlistPanel(inputId = "first_sublist",
  #                      selected = "firstsecond")
  # })
  #
  # observeEvent(input$goto_firstthird, {
  #   updateNavlistPanel(inputId = "first_sublist",
  #                      selected = "firstthird")
  # })
  #
  # observeEvent(input$goto_firstfourth, {
  #   updateNavlistPanel(inputId = "first_sublist",
  #                      selected = "firstfourth")
  # })
  #
  # observeEvent(input$goto_firstfifth, {
  #   updateNavlistPanel(inputId = "first_sublist",
  #                      selected = "firstfifth")
  # })


}










shinyApp(ui = ui, server = server)
