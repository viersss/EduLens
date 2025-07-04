# EduLens/ui.R 

library(shiny)
library(shinyjs)
library(plotly)

ui <- fluidPage(
  title = "EduLens Dashboard",
  
  # Mengaktifkan shinyjs
  useShinyjs(), 
  
  # Mendefinisikan semua link dan meta tag di dalam <head> satu kali saja
  tags$head(
    tags$meta(charset="UTF-8"),
    tags$meta(name="viewport", content="width=device-width, initial-scale=1"),
    tags$link(href="https://fonts.googleapis.com/icon?family=Material+Icons", rel="stylesheet"),
    
    tags$link(rel="preconnect", href="https://fonts.googleapis.com"),
    tags$link(rel="preconnect", href="https://fonts.gstatic.com", crossorigin = ""),
    tags$link(href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap", rel="stylesheet"),
    
    tags$link(href="style.css", rel="stylesheet")
  ),
  
  # Container utama di mana konten dinamis (home atau dashboard) akan dimuat
  uiOutput("main_ui_content")
)