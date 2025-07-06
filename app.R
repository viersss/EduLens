Tentu, ini adalah gabungan dari `ui.R` dan `server.R` menjadi satu file `app.R`.

```r
# ====================================================================
# 1. MEMUAT SEMUA LIBRARY YANG DIBUTUHKAN
# ====================================================================
library(shiny)
library(shinyjs)
library(plotly)
library(dplyr)
library(tidyr)
library(readxl)
library(leaflet)
library(sf)
library(DT)
library(htmlwidgets)
library(webshot)
library(rmarkdown)

# ====================================================================
# 2. DEFINISI UI (USER INTERFACE)
# ====================================================================
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

# ====================================================================
# 3. DEFINISI SERVER (LOGIKA APLIKASI)
# ====================================================================
server <- function(input, output, session) {
  
  # --- FUNGSI BANTUAN UNTUK MEMBUAT LEGENDA BIVARIAT ---
  createBivariateLegend <- function(var1, var2) {
    colors <- c("#e8e8e8", "#b0d5df", "#64acbe", "#e4acac", "#ad9ea5", "#627f8c", "#c85a5a", "#985356", "#574249")
    
    legend_html <- paste0(
      "<div class='bivar-legend-container'>",
      "<div class='bivar-legend'>",
      paste0("<div class='bivar-cell' style='background:", colors, "'></div>", collapse = ""),
      "</div>",
      "<div class='bivar-axis bivar-axis-y'>",
      "<span>Tinggi &uarr;</span>",
      paste0("<span>", var2, "</span>"),
      "<span>Rendah &darr;</span>",
      "</div>",
      "<div class='bivar-axis bivar-axis-x'>",
      "<span>Rendah &larr;</span>",
      paste0("<span>", var1, "</span>"),
      "<span>Tinggi &rarr;</span>",
      "</div>",
      "</div>"
    )
    
    return(legend_html)
  }
  
  # ====================================================================
  # 3.1. SETUP AWAL (MEMBACA DATA PETA)
  # ====================================================================
  
  indonesia_map_data <- tryCatch({
    st_read("www/indonesia_provinces.geojson", quiet = TRUE)
  }, error = function(e) {
    showNotification("Gagal membaca file GeoJSON peta. Pastikan file 'indonesia_provinces.geojson' ada di folder www.", type = "error", duration = NULL)
    return(NULL)
  })
  
  # ------------------------------------------------------------------
  # 3.2. MANAJEMEN NAVIGASI & DATA
  # ------------------------------------------------------------------
  
  rv <- reactiveValues(page = "home")
  
  onclick("goToDashboardBtn", { rv$page <- "dashboard" })
  onclick("goToHomeBtn", { rv$page <- "home" })
  
  # Data awal Dashboard (digunakan juga untuk fitur reset)
  initial_data <- tibble(
    year = rep(c(2024, 2023, 2022, 2021, 2020, 2019), each = 38),
    Provinsi = rep(c("Aceh", "Sumatera Utara", "Sumatera Barat", "Riau", 
                     "Jambi", "Sumatera Selatan", "Bengkulu", "Lampung",
                     "Kepulauan Bangka Belitung", "Kepulauan Riau", "DKI Jakarta",
                     "Jawa Barat", "Jawa Tengah", "DI Yogyakarta", "Jawa Timur", 
                     "Banten", "Bali", "Nusa Tenggara Barat", "Nusa Tenggara Timur", 
                     "Kalimantan Barat", "Kalimantan Tengah", "Kalimantan Selatan", 
                     "Kalimantan Timur", "Kalimantan Utara", "Sulawesi Utara", 
                     "Sulawesi Tengah", "Sulawesi Selatan", "Sulawesi Tenggara",
                     "Gorontalo", "Sulawesi Barat", "Maluku", "Maluku Utara", 
                     "Papua Barat", "Papua Barat Daya", "Papua", "Papua Selatan", 
                     "Papua Tengah", "Papua Pegunungan"), times = 6),
    
    RLS = c(
      # 2024
      9.64, 9.93, 9.44, 9.43, 8.9, 8.57, 9.04, 8.36, 8.33, 10.5, 11.49, 8.87, 8.02, 9.92, 8.28, 9.23, 9.54, 7.87, 8.02, 7.78, 8.81, 8.62, 10.02, 9.35, 9.84, 9.04, 8.86, 9.42, 8.29, 8.15, 10.26, 9.37, 7.86, 8.39, 9.82, 8.38, 6.12, 4.21,
      # 2023
      9.55, 9.82, 9.28, 9.32, 8.81, 8.5, 9.03, 8.29, 8.25, 10.41, 11.45, 8.83, 8.01, 9.83, 8.11, 9.15, 9.45, 7.74, 7.82, 7.71, 8.73, 8.55, 9.99, 9.34, 9.77, 8.96, 8.76, 9.31, 8.1, 8.13, 10.2, 9.26, 7.93, 0, 7.15, 0, 0, 0,
      # 2022
      9.44, 9.71, 9.18, 9.22, 8.68, 8.37, 8.91, 8.18, 8.11, 10.37, 11.31, 8.78, 7.93, 9.75, 8.03, 9.13, 9.39, 7.61, 7.7, 7.59, 8.65, 8.46, 9.92, 9.27, 9.68, 8.89, 8.63, 9.25, 8.02, 8.08, 10.19, 9.24, 7.84, 0, 7.02, 0, 0, 0,
      # 2021
      9.37, 9.58, 9.07, 9.19, 8.6, 8.3, 8.87, 8.08, 8.08, 10.18, 11.17, 8.61, 7.75, 9.64, 7.88, 8.93, 9.06, 7.38, 7.69, 7.45, 8.64, 8.34, 9.84, 9.11, 9.62, 8.89, 8.46, 9.13, 7.9, 7.96, 10.03, 9.09, 7.69, 0, 6.76, 0, 0, 0,
      # 2020
      9.33, 9.54, 8.99, 9.14, 8.55, 8.24, 8.84, 8.05, 8.06, 10.12, 11.13, 8.55, 7.69, 9.55, 7.78, 8.89, 8.95, 7.31, 7.63, 7.37, 8.59, 8.29, 9.77, 9, 9.49, 8.83, 8.38, 9.04, 7.82, 7.89, 9.93, 9.04, 7.6, 0, 6.69, 0, 0, 0,
      # 2019
      9.18, 9.45, 8.92, 9.03, 8.45, 8.18, 8.73, 7.92, 7.98, 9.99, 11.06, 8.37, 7.53, 9.38, 7.59, 8.74, 8.84, 7.27, 7.55, 7.31, 8.51, 8.2, 9.7, 8.94, 9.43, 8.75, 8.26, 8.91, 7.69, 9.81, 9.0, 7.44, 0, 6.65, 0, 0, 0, 0
    ),
    
    HLS = c(
      # 2024
      14.39, 13.49, 14.3, 13.42, 13.14, 12.64, 13.75, 12.78, 12.49, 13.27, 13.51, 12.8, 12.86, 15.7, 13.43, 13.1, 13.62, 13.98, 13.23, 12.68, 12.77, 12.87, 14.03, 13.21, 12.97, 13.34, 13.55, 13.71, 13.17, 12.89, 14.09, 13.75, 13.17, 13.88, 13.72, 12.67, 9.63, 9.97,
      # 2023
      14.38, 13.48, 14.11, 13.13, 13.13, 12.63, 13.74, 12.77, 12.31, 13.05, 13.33, 12.68, 12.85, 15.66, 13.38, 13.09, 13.58, 13.97, 13.22, 12.67, 12.76, 12.86, 14.02, 13.2, 12.96, 13.33, 13.54, 13.7, 13.16, 12.88, 14.08, 13.74, 13.34, 0, 11.15, 0, 0, 0,
      # 2022
      14.37, 13.31, 14.1, 13.29, 13.05, 12.55, 13.68, 12.74, 12.18, 12.99, 13.08, 12.62, 12.81, 15.65, 13.37, 13.05, 13.48, 13.96, 13.21, 12.66, 12.75, 12.82, 13.84, 13.06, 12.95, 13.32, 13.53, 13.69, 13.12, 12.87, 14, 13.73, 13.21, 0, 11.14, 0, 0, 0,
      # 2021
      14.36, 13.27, 14.09, 13.28, 13.04, 12.54, 13.67, 12.73, 12.17, 12.98, 13.07, 12.61, 12.77, 15.64, 13.36, 13.02, 13.4, 13.9, 13.2, 12.65, 12.74, 12.81, 13.81, 12.94, 12.94, 13.23, 13.52, 13.68, 13.11, 12.86, 13.97, 13.68, 13.13, 0, 11.11, 0, 0, 0,
      # 2020
      14.31, 13.23, 14.02, 13.2, 12.98, 12.45, 13.61, 12.65, 12.05, 12.87, 12.98, 12.5, 12.7, 15.59, 13.19, 12.89, 13.33, 13.7, 13.18, 12.6, 12.66, 12.68, 13.72, 12.93, 12.85, 13.17, 13.45, 13.65, 12.44, 12.77, 13.96, 13.67, 12.91, 0, 11.08, 0, 0, 0,
      # 2019
      14.3, 13.15, 14.01, 13.14, 12.93, 12.59, 13.59, 12.63, 11.94, 12.83, 12.97, 12.48, 12.68, 15.58, 13.16, 12.88, 13.27, 13.48, 13.15, 12.58, 12.57, 12.52, 13.69, 12.84, 12.73, 13.14, 13.36, 13.55, 13.06, 12.62, 13.94, 12.84, 12.72, 0, 11.05, 0, 0, 0
    ),
    
    APM = c(
      # 2024
      84.373, 83.183, 84.777, 82.543, 80.1, 79.27, 83.277, 81.423, 79.197, 87.783, 83.97, 81.273, 80.66, 89.143, 82.7, 81.757, 86.397, 84.403, 77.153, 76.227, 78.963, 79.027, 84.887, 81.563, 79.537, 79.337, 79.12, 80.37, 77.313, 76.897, 82.2, 81.257, 76.143, 78.74, 76.42, 60.893, 54.453, 59.943,
      # 2023
      85.173, 82.903, 82.763, 81.233, 80.053, 79.493, 82.26, 80.9, 78.61, 86.727, 81.4, 80.273, 80.493, 87.117, 81.513, 81.273, 86.05, 83.61, 75.867, 74.437, 77.917, 78.803, 83.927, 80.653, 78.7, 78.763, 78.987, 79.673, 77.473, 76.493, 80.67, 80.547, 78.38, 0, 63.073, 0, 0, 0,
      # 2022
      86.147, 82.703, 82.013, 80.7, 79.997, 79.253, 81.82, 81.107, 77.447, 86.5, 81.157, 79.897, 80.193, 86.403, 81.33, 80.713, 86.357, 84.163, 74.043, 72.57, 77.85, 78.337, 83.4, 79.573, 78.283, 78.2, 78.757, 80.05, 76.29, 75.463, 79.947, 80.01, 76.45, 0, 62.81, 0, 0, 0,
      # 2021
      85.567, 82.27, 82.187, 80.79, 80.283, 78.947, 81.647, 80.48, 77.093, 86.407, 80.587, 79.943, 79.89, 84.827, 81.443, 80.707, 86.377, 83.727, 73.44, 72.433, 77.353, 77.73, 82.983, 79.32, 77.887, 77.92, 78.543, 79.903, 76.003, 75.16, 79.053, 79.447, 76.04, 0, 60.907, 0, 0, 0,
      # 2020
      85.533, 82.097, 82.037, 80.74, 80.14, 78.777, 81.413, 79.97, 77.047, 86.36, 80.313, 79.443, 79.39, 84.85, 81.253, 79.913, 85.797, 83.523, 73.333, 72.16, 77.213, 77.507, 82.907, 79.1, 77.793, 77.56, 78.157, 79.583, 75.68, 74.61, 78.937, 79.453, 76.003, 0, 60.673, 0, 0, 0,
      # 2019
      85.317, 81.82, 81.767, 80.27, 79.823, 78.47, 80.993, 79.683, 76.757, 85.88, 80.013, 79.02, 78.987, 84.687, 80.873, 79.57, 85.523, 82.943, 73.01, 71.657, 76.89, 77.157, 82.46, 78.653, 77.417, 77.217, 78.007, 79.133, 75.403, 74.287, 78.373, 79.08, 75.61, 0, 60.233, 0, 0, 0
    )
  )
  
  main_data <- reactiveVal(initial_data)
  
  # ====================================================================
  # 3.3. RENDER UI UTAMA
  # ====================================================================
  
  output$main_ui_content <- renderUI({
    if (rv$page == "home") {
      addClass(selector = "body", class = "home-page")
      removeClass(selector = "body", class = "dashboard-page")
      includeHTML("www/home.html")
    } else if (rv$page == "dashboard") {
      addClass(selector = "body", class = "dashboard-page")
      removeClass(selector = "body", class = "home-page")
      
      div(
        tags$header(class="premium-header", role="banner",
                    div(class="brand", "EduLens"),
                    tags$button(class="menu-toggle-button", `aria-label`="Toggle navigation menu", span(class="material-icons", "menu"))
        ),
        tags$aside(class="sidebar", role="navigation", id="sidebar",
                   tags$nav(
                     tags$a(href="#", id="goToHomeBtn", span(class="material-icons", "home"), "Home"),
                     tags$a(href="#", id="goToUserGuideBtn", span(class="material-icons", "help_outline"), "Panduan Pengguna"),
                     tags$a(href="#", id="goToUploadBtn", span(class="material-icons", "upload_file"), "Unggah Data"),
                     tags$a(href="#", id="goToPreviewBtn", span(class="material-icons", "table_view"), "Preview Data"),
                     tags$a(href="#nationalData", id="goToDashboardViewBtn", span(class="material-icons", "public"), "Data Nasional & Provinsi"),
                     tags$a(href="#trendChartContainer", id="link_to_trend", span(class="material-icons", "show_chart"), "Tren Indikator"),
                     tags$a(href="#pcaChartContainer", id="link_to_pca", span(class="material-icons", "scatter_plot"), "Analisis Biplot (PCA)"),
                     tags$a(href="#heatmapChartContainer", id="link_to_heatmap", span(class="material-icons", "grid_on"), "Heatmap Similaritas"),
                     tags$a(href="#mapContainer", id="link_to_map", span(class="material-icons", "map"), "Peta Bivariat")
                   )
        ),
        div(class="sidebar-overlay", `tabindex`="-1", `aria-hidden`="true"),
        tags$main(class="content-area", role="main",
                  
                  div(id = "mainDashboardContainer",
                      div(class="header", id="nationalData",
                          h1("Dashboard Agregasi dan Tren Indikator Pendidikan Indonesia"),
                          p("Analisis komprehensif RLS (Rata-rata Lama Sekolah), HLS (Harapan Lama Sekolah), dan APM (Angka Partisipasi Murni) melalui Visualisasi Statistik Antar Provinsi maupun Nasional")
                      ),
                      tags$section(class="controls",
                                   div(class="control-group",
                                       div(class="control-item", uiOutput("yearSelectUI")),
                                       div(class="control-item", 
                                           selectInput("bivar_var1", "Peta Indikator X:", choices = c("RLS", "HLS", "APM"), selected = "RLS")
                                       ),
                                       div(class="control-item", 
                                           selectInput("bivar_var2", "Peta Indikator Y:", choices = c("RLS", "HLS", "APM"), selected = "APM")
                                       ),
                                       div(class="control-item", uiOutput("provinceSelectUI"))
                                   ),
                                   div(style="text-align: center; margin-top: 20px; margin-bottom: 20px;",
                                       downloadButton("downloadReport", "Unduh Laporan Analisis Lengkap", icon = icon("file-pdf"), class="btn-danger")
                                   )
                      ),
                      tags$section(class="stats-container", uiOutput("nationalStatsOutput"), uiOutput("provinceStatsOutput")),
                      div(class="dashboard-grid",
                          div(class="chart-container full-width", id="provincialSummaryContainer",
                              div(class="chart-title", "Ringkasan Statistik Agregat Provinsi"),
                              p(class="chart-description", "Tabel ini menampilkan ringkasan statistik deskriptif untuk indikator yang dianalisis menurut provinsi di Indonesia. Penyajian ini membantu memberikan gambaran umum mengenai variasi dan kecenderungan nilai antar wilayah."),
                              uiOutput("provincialSummaryOutput")
                          ),
                          div(class="chart-container", id="trendChartContainer", 
                              div(class="chart-title-container", div(class="chart-title", "Tren Indikator Pendidikan"), downloadButton("downloadTrendChart", "Unduh", class="btn-sm download-btn")), 
                              plotlyOutput("trendChart", height = "400px"),
                              p(class = "chart-description", "Visualisasi menunjukkan tren rata-rata nasional untuk indikator APM, HLS, dan RLS selama periode 2019–2024. Sumbu horizontal menampilkan tahun, sedangkan sumbu vertikal menunjukkan nilai rata-rata nasional. Garis biru merepresentasikan APM, hijau untuk HLS, dan merah untuk RLS.")
                          ),
                          div(class="chart-container", 
                              div(class="chart-title-container", div(class="chart-title", "Distribusi Indikator per Provinsi"), downloadButton("downloadDistChart", "Unduh", class="btn-sm download-btn")), 
                              plotlyOutput("distributionChart", height = "400px"),
                              p(class = "chart-description", "Visualisasi menampilkan distribusi nilai indikator RLS, HLS, dan APM per provinsi. Sumbu horizontal menunjukkan nama provinsi, sementara sumbu vertikal menampilkan nilai RLS & HLS (tahun) di sisi kiri dan APM (%) di sisi kanan. Warna merah mewakili RLS, hijau untuk HLS, dan biru untuk APM.")
                          ),
                          div(class="chart-container full-width", id="pcaChartContainer", 
                              div(class="chart-title-container", div(class="chart-title", "Analisis Biplot (PCA)"), downloadButton("downloadPcaChart", "Unduh", class="btn-sm download-btn")),
                              plotlyOutput("pcaChart", height = "500px"),
                              p(class = "chart-description", "Biplot menunjukkan hubungan antara APM (dependent) dengan RLS dan HLS (independent). Panah RLS dan HLS yang searah dengan APM menunjukkan keduanya berkontribusi positif terhadap peningkatan APM. Observasi yang dekat dengan ujung panah APM cenderung memiliki nilai APM lebih tinggi, sedangkan yang jauh menunjukkan nilai lebih rendah. Interpretasi ini mendukung bahwa peningkatan rata-rata lama sekolah dan harapan lama sekolah berkaitan dengan naiknya angka partisipasi murni.")
                          ),
                          div(class="chart-container full-width", id="heatmapChartContainer", 
                              div(class="chart-title-container", div(class="chart-title", "Heatmap Similaritas"), downloadButton("downloadHeatmapChart", "Unduh", class="btn-sm download-btn")),
                              plotlyOutput("heatmapChart", height = "600px"),
                              p(class = "chart-description", "Heatmap memperlihatkan heatmap yang menampilkan variasi nilai indikator antar provinsi (atau kategori) dan variabel. Warna pada sel merepresentasikan intensitas atau besaran nilai, dengan gradasi warna memudahkan perbandingan visual antar kategori dan indikator.")
                          ),
                          div(class="chart-container full-width", id="mapContainer", 
                              div(class="chart-title", "Peta Analisis Bivariat"), 
                              leafletOutput("indonesiaMap", height = "600px"),
                              p(class = "chart-description", "Peta choropleth menggambarkan distribusi nilai suatu indikator pada tingkat provinsi di Indonesia. Setiap provinsi diberi warna berdasarkan besaran nilai indikator, menggunakan gradasi warna dari rendah ke tinggi. Semakin gelap (atau terang) warna suatu wilayah, semakin tinggi (atau rendah) nilai indikator yang dimiliki. Visualisasi ini memudahkan identifikasi pola spasial, seperti konsentrasi nilai tinggi pada wilayah tertentu atau ketimpangan antar provinsi. Skala warna disesuaikan secara otomatis mengikuti rentang data tahun atau indikator yang ditampilkan.")
                          )
                      )
                  ),
                  
                  div(id = "uploadPageContainer", class = "page-container",
                      div(class="chart-container", style="max-width: 800px;",
                          div(class="chart-title", "Unggah File Data"),
                          p("Silakan unggah file Excel (.xlsx) atau CSV (.csv) Anda. Pastikan format file sesuai dengan panduan dan contoh tabel di bawah ini.", style="text-align:center; margin-bottom: 20px;"),
                          
                          div(class="table-example-container",
                              tags$h4("Contoh Format Data yang Benar"),
                              tags$table(class = "summary-table example-table",
                                         tags$thead(
                                           tags$tr(
                                             tags$th("year"),
                                             tags$th("Provinsi"),
                                             tags$th("RLS"),
                                             tags$th("HLS"),
                                             tags$th("APM")
                                           )
                                         ),
                                         tags$tbody(
                                           tags$tr(
                                             tags$td("2024"),
                                             tags$td("DKI Jakarta"),
                                             tags$td("11.52"),
                                             tags$td("14.80"),
                                             tags$td("99.5")
                                           ),
                                           tags$tr(
                                             tags$td("2024"),
                                             tags$td("Jawa Barat"),
                                             tags$td("9.05"),
                                             tags$td("13.10"),
                                             tags$td("98.8")
                                           ),
                                           tags$tr(
                                             tags$td("..."),
                                             tags$td("..."),
                                             tags$td("..."),
                                             tags$td("..."),
                                             tags$td("...")
                                           )
                                         )
                              ),
                              p(class="table-caption", "Nama kolom harus sama persis dan data indikator harus berupa angka.")
                          ),
                          
                          div(class="upload-box-center",
                              fileInput("fileInput", label = NULL, buttonLabel = "Cari File...", placeholder = "Tidak ada file yang dipilih", width = "100%")
                          )
                      )
                  ),
                  
                  div(id = "dataPreviewContainer", class = "page-container",
                      div(class="chart-container full-width",
                          div(style = "display: flex; justify-content: center; align-items: center; gap: 20px; margin-bottom: 15px;",
                              h3(class="chart-title", style="margin:0;", "Preview Data yang Diunggah"),
                              actionButton("resetDataBtn", "Reset Data", icon = icon("sync-alt"), class = "btn-warning btn-sm"),
                              downloadButton("downloadFilteredData", "Unduh Data (CSV)", class = "btn-success btn-sm")
                          ),
                          p("Gunakan tabel ini untuk memeriksa apakah data dari file Anda sudah terbaca dengan benar oleh sistem.", style="text-align:center; margin-bottom: 20px;"),
                          DTOutput("dataPreviewTable")
                      )
                  ),
                  
                  div(id = "userGuideContainer", class = "page-container",
                      div(class="chart-container full-width",
                          h2(class="chart-title", style="font-size: 1.8rem; border-bottom: 2px solid #667eea; padding-bottom: 10px;", "Panduan Penggunaan Dashboard EduLens"),
                          tags$br(),
                          div(style="padding: 0 20px; text-align: left; max-width: 800px; margin: 0 auto;",
                              p("Panduan ini akan memandu Anda melalui langkah-langkah utama penggunaan Dashboard, mulai dari halaman awal hingga analisis data."),
                              tags$br(),
                              tags$ol(
                                tags$li(
                                  strong("Mulai Eksplorasi:"),
                                  "Di halaman utama (Home), Anda akan melihat tombol ",
                                  span(
                                    class="cta-button", 
                                    style="display: inline-flex; align-items: center; gap: 4px; font-size: 0.9em; padding: 2px 8px; color: #667eea; background: white; vertical-align: middle;", 
                                    tagList(
                                      span(class="material-icons", style="font-size: 1.2em;", "analytics"),
                                      "Mulai Eksplorasi Data"
                                    )
                                  ),
                                  ". Klik tombol ini untuk masuk ke halaman dashboard utama."
                                ),
                                tags$br(),
                                tags$li(
                                  strong("Mengunggah Data Anda Sendiri:"),
                                  "Setelah masuk ke dashboard, lihat sidebar di sebelah kiri. Untuk menggunakan data Anda sendiri, klik tombol ",
                                  span(class="material-icons", style="vertical-align: middle; font-size: 1em;"),
                                  " 'Unggah Data'. Ini akan membuka halaman unggah."
                                ),
                                tags$br(),
                                tags$li(
                                  strong("Proses Unggah File:"),
                                  "Di halaman unggah, Anda akan melihat contoh format tabel yang benar. Pastikan file Excel (.xlsx) atau CSV (.csv) Anda memiliki kolom seperti ",
                                  code("year, Provinsi, RLS, HLS, APM"),
                                  ". Klik tombol 'Cari File...' untuk memilih file dari komputer Anda. Setelah dipilih, Dashboard akan otomatis memprosesnya."
                                ),
                                tags$br(),
                                tags$li(
                                  strong("Memeriksa Data (Preview):"),
                                  "Setelah berhasil mengunggah, klik tombol ",
                                  span(class="material-icons", style="vertical-align: middle; font-size: 1em;"),
                                  " 'Preview Data'",
                                  " di sidebar. Halaman ini akan menampilkan data Anda dalam sebuah tabel interaktif. Anda dapat memfilter, mencari, dan memastikan data sudah terbaca dengan benar."
                                ),
                                tags$br(),
                                tags$li(
                                  strong("Melihat Hasil Analisis:"),
                                  "Jika data sudah sesuai, klik salah satu menu analisis di sidebar, misalnya ",
                                  span(class="material-icons", style="vertical-align: middle; font-size: 1em;"),
                                  " 'Data Nasional & Provinsi'. ",
                                  "Semua grafik, peta, dan statistik di dashboard sekarang akan otomatis menggunakan data yang baru saja Anda unggah."
                                ),
                                tags$br(),
                                tags$li(
                                  strong("Reset Data:"),
                                  "Jika Anda ingin kembali menggunakan data default bawaan Dashboard, pergi ke halaman 'Preview Data' dan klik tombol 'Reset Data'."
                                )
                              ),
                              p("Sekarang Anda siap untuk menjelajahi semua fitur analisis yang ditawarkan oleh EduLens. Selamat mencoba!")
                          )
                      )
                  )
        ), # Akhir dari tags$main
        
        tags$script(HTML("
          document.querySelectorAll('.menu-toggle-button').forEach(button => {
            button.addEventListener('click', () => {
              const sidebar = document.getElementById('sidebar');
              const overlay = document.querySelector('.sidebar-overlay');
              sidebar.classList.toggle('open');
              if (overlay) overlay.classList.toggle('visible');
            });
          });
          document.querySelectorAll('.sidebar-overlay').forEach(overlay => {
            overlay.addEventListener('click', () => {
              document.getElementById('sidebar').classList.remove('open');
              overlay.classList.remove('visible');
            });
          });
          const navLinks = document.querySelectorAll('aside.sidebar nav a');
          navLinks.forEach(link => {
            link.addEventListener('click', function(event) {
              navLinks.forEach(l => l.classList.remove('active'));
              this.classList.add('active');
              if (window.innerWidth <= 767) {
                document.getElementById('sidebar').classList.remove('open');
                const overlay = document.querySelector('.sidebar-overlay');
                if (overlay) overlay.classList.remove('visible');
              }
            });
          });
        "))
      ) # Akhir dari div utama halaman dashboard
    }
  })
  
  # --- LOGIKA NAVIGASI, UNDUH, DAN RESET ---
  
  observe({ 
    shinyjs::hide("uploadPageContainer")
    shinyjs::hide("dataPreviewContainer")
    shinyjs::hide("userGuideContainer")
  })
  
  output$dataPreviewTable <- renderDT({ 
    datatable(main_data(), rownames = FALSE, filter = 'top', options = list(pageLength = 10, scrollX = TRUE, autoWidth = TRUE), class = 'cell-border stripe hover') 
  })
  
  onclick("goToUploadBtn", { 
    shinyjs::hide("mainDashboardContainer")
    shinyjs::hide("dataPreviewContainer")
    shinyjs::hide("userGuideContainer")
    shinyjs::show("uploadPageContainer")
  })
  
  onclick("goToPreviewBtn", { 
    shinyjs::hide("mainDashboardContainer")
    shinyjs::hide("uploadPageContainer")
    shinyjs::hide("userGuideContainer")
    shinyjs::show("dataPreviewContainer")
  })
  
  onclick("goToUserGuideBtn", {
    shinyjs::hide("mainDashboardContainer")
    shinyjs::hide("uploadPageContainer")
    shinyjs::hide("dataPreviewContainer")
    shinyjs::show("userGuideContainer")
  })
  
  showDashboard <- function() { 
    shinyjs::hide("uploadPageContainer")
    shinyjs::hide("dataPreviewContainer")
    shinyjs::hide("userGuideContainer")
    shinyjs::show("mainDashboardContainer")
  }
  
  onclick("goToDashboardViewBtn", showDashboard)
  onclick("link_to_trend", showDashboard)
  onclick("link_to_pca", showDashboard)
  onclick("link_to_heatmap", showDashboard)
  onclick("link_to_map", showDashboard)
  
  observeEvent(input$resetDataBtn, { 
    main_data(initial_data)
    showNotification("Data telah di-reset ke data semula.", type = "message") 
  })
  
  output$downloadFilteredData <- downloadHandler( 
    filename = function() { 
      paste0("data_pendidikan_", input$yearSelect, ".csv") 
    }, 
    content = function(file) { 
      write.csv(data_by_year(), file, row.names = FALSE, fileEncoding = "UTF-8") 
    } 
  )
  
  output$downloadReport <- downloadHandler(
    filename = function() {
      paste0("Laporan Analisis Pendidikan_", "Tahun ", input$yearSelect, ".pdf")
    },
    content = function(file) {
      progress <- shiny::Progress$new()
      on.exit(progress$close())
      progress$set(message = "Membuat Laporan PDF...", value = 0.1)
      
      tryCatch({
        temp_data_path <- tempfile(fileext = ".csv")
        write.csv(main_data(), temp_data_path, row.names = FALSE, fileEncoding = "UTF-8")
        progress$inc(0.3, detail = "Menyiapkan data")
        
        params <- list(
          selected_year = input$yearSelect,
          data_path = temp_data_path
        )
        
        temp_report <- file.path(tempdir(), "laporan.Rmd")
        file.copy("laporan.Rmd", temp_report, overwrite = TRUE)
        progress$inc(0.3, detail = "Merender laporan...")
        
        rmarkdown::render(
          temp_report, 
          output_file = file,
          params = params,
          envir = new.env(parent = globalenv())
        )
        progress$inc(0.4, detail = "Selesai!")
      }, error = function(e) {
        showNotification(
          paste("Gagal membuat PDF. Error:", e$message),
          duration = NULL,
          type = "error"
        )
        return(NULL)
      })
    }
  )
  
  # ====================================================================
  # 3.4. LOGIKA SERVER UNTUK DASHBOARD
  # ====================================================================
  
  data_by_year <- reactive({ req(input$yearSelect); main_data() %>% filter(year == input$yearSelect) })
  
  bivariate_data <- reactive({
    req(data_by_year(), input$bivar_var1, input$bivar_var2)
    df <- data_by_year()
    var1_name <- input$bivar_var1
    var2_name <- input$bivar_var2
    if(var1_name == var2_name) return(NULL)
    df_no_na <- df %>% drop_na(all_of(c(var1_name, var2_name)))
    req(nrow(df_no_na) >= 3)
    df_bivar <- df_no_na %>%
      mutate(
        var1_cat = cut(!!sym(var1_name), breaks = unique(quantile(!!sym(var1_name), probs = 0:3/3, na.rm = TRUE)), labels = FALSE, include.lowest = TRUE),
        var2_cat = cut(!!sym(var2_name), breaks = unique(quantile(!!sym(var2_name), probs = 0:3/3, na.rm = TRUE)), labels = FALSE, include.lowest = TRUE),
        bivar_cat = paste0(var1_cat, "-", var2_cat),
        province_join_key = toupper(Provinsi) 
      )
    return(df_bivar)
  })
  
  observeEvent(input$fileInput, { 
    req(input$fileInput)
    ext <- tools::file_ext(input$fileInput$name)
    df <- tryCatch({ 
      if (ext == "csv") { 
        read.csv(input$fileInput$datapath, stringsAsFactors = FALSE) 
      } else if (ext == "xlsx") { 
        read_excel(input$fileInput$datapath) 
      } else { 
        stop("Tipe file tidak didukung.") 
      } 
    }, error = function(e) { 
      showNotification(paste("Error membaca file:", e$message), type = "error")
      return(NULL) 
    })
    if (!is.null(df)) { 
      main_data(df)
      showNotification("File berhasil diunggah! Navigasikan ke 'Preview Data' untuk memeriksa.", type = "message", duration=7)
    } 
  })
  
  output$yearSelectUI <- renderUI({ 
    df <- main_data()
    years <- sort(unique(df$year), decreasing = TRUE)
    selectInput("yearSelect", "Tahun:", choices = years, selected = years[1]) 
  })
  
  output$provinceSelectUI <- renderUI({ 
    df <- main_data()
    provinces <- c("Semua Provinsi" = "all", sort(unique(df$Provinsi)))
    selectInput("provinceSelect", "Provinsi:", choices = provinces) 
  })
  
  output$nationalStatsOutput <- renderUI({
    req(data_by_year())
    df_year <- data_by_year()
    avg_rls <- mean(df_year$RLS, na.rm = TRUE)
    avg_hls <- mean(df_year$HLS, na.rm = TRUE)
    avg_apm <- mean(df_year$APM, na.rm = TRUE)
    top_prov <- df_year %>% 
      mutate(score = rowMeans(select(., RLS, HLS, APM), na.rm = TRUE)) %>% 
      filter(score == max(score, na.rm = TRUE)) %>% 
      pull(Provinsi) %>% 
      first()
    
    div(class = "stats-section", id = "nationalDataSection", 
        h3(HTML("&#x1F4CA; Data Nasional"), span(id = "nationalYear", input$yearSelect)), 
        div(class = "stats-grid", 
            div(class="stat-card rls", div(class="stat-value", round(avg_rls, 2)), div(class="stat-label", "Rata-rata RLS Nasional")), 
            div(class="stat-card hls", div(class="stat-value", round(avg_hls, 2)), div(class="stat-label", "Rata-rata HLS Nasional")), 
            div(class="stat-card apm", div(class="stat-value", paste0(round(avg_apm, 1), "%")), div(class="stat-label", "Rata-rata APM Nasional")), 
            div(class="stat-card top", div(class="stat-value", top_prov), div(class="stat-label", "Provinsi Terbaik"))
        ),
        div(class="chart-description",
            h4(class="interpretation-title", "Interpretasi Data Nasional"),
            p(HTML(paste0("Pada tahun ", strong(input$yearSelect), ", Rata-rata Lama Sekolah (RLS) nasional mencapai ", strong(round(avg_rls, 2), " tahun"), ". Angka ini merepresentasikan durasi pendidikan formal rata-rata yang telah diselesaikan oleh penduduk usia 25 tahun ke atas, menjadi proksi untuk tingkat kapabilitas dan modal manusia di tingkat nasional."))),
            p(HTML(paste0("Harapan Lama Sekolah (HLS) berada di angka ", strong(round(avg_hls, 2), " tahun"), ", yang mengindikasikan ekspektasi durasi pendidikan yang akan dijalani oleh anak usia 7 tahun. Nilai ini mencerminkan optimisme terhadap aksesibilitas dan keberlanjutan sistem pendidikan di masa depan."))),
            p(HTML(paste0("Angka Partisipasi Murni (APM) nasional tercatat sebesar ", strong(paste0(round(avg_apm, 1), "%")), ". Persentase ini menunjukkan efektivitas sistem pendidikan dalam menjangkau populasi usia sekolah pada jenjang yang sesuai, di mana nilai yang tinggi menandakan partisipasi yang luas."))),
            p(HTML(paste0("Berdasarkan agregasi ketiga indikator, ", strong(top_prov), " menunjukkan performa pendidikan terbaik secara keseluruhan pada tahun ini, mengindikasikan keunggulan komparatif dalam pencapaian output dan akses pendidikan.")))
        )
    )
  })
  
  output$provinceStatsOutput <- renderUI({
    req(input$provinceSelect, input$provinceSelect != "all")
    df_year <- data_by_year()
    prov_data <- df_year %>% filter(Provinsi == input$provinceSelect)
    ranking <- df_year %>% 
      mutate(score = rowMeans(select(., RLS, HLS, APM), na.rm = TRUE)) %>% 
      arrange(desc(score)) %>% 
      mutate(rank = row_number()) %>% 
      filter(Provinsi == input$provinceSelect) %>% 
      pull(rank)
    
    div(class = "stats-section", id = "provinceStatsSection", 
        h3(HTML("&#x1F3DB;&#xFE0F; Data Provinsi:"), span(id = "selectedProvinceName", input$provinceSelect), paste0(" (", input$yearSelect, ")")), 
        div(class = "stats-grid", 
            div(class="stat-card rls", div(class="stat-value", prov_data$RLS), div(class="stat-label", "RLS Provinsi")), 
            div(class="stat-card hls", div(class="stat-value", prov_data$HLS), div(class="stat-label", "HLS Provinsi")), 
            div(class="stat-card apm", div(class="stat-value", paste0(prov_data$APM, "%")), div(class="stat-label", "APM Provinsi")), 
            div(class="stat-card top", div(class="stat-value", paste0("#", ranking)), div(class="stat-label", "Ranking Nasional"))
        ),
        div(class="chart-description",
            h4(class="interpretation-title", paste("Interpretasi Data Provinsi", input$provinceSelect)),
            p(HTML(paste0("Untuk Provinsi ", strong(input$provinceSelect), " pada tahun ", strong(input$yearSelect), ", Rata-rata Lama Sekolah (RLS) tercatat sebesar ", strong(prov_data$RLS, " tahun"), ". Nilai ini memberikan gambaran tingkat pendidikan aktual yang telah dicapai oleh populasi dewasanya."))),
            p(HTML(paste0("Harapan Lama Sekolah (HLS) di provinsi ini adalah ", strong(prov_data$HLS, " tahun"), ", yang merefleksikan proyeksi durasi pendidikan bagi generasi mendatang di wilayah tersebut."))),
            p(HTML(paste0("Angka Partisipasi Murni (APM) mencapai ", strong(paste0(prov_data$APM, "%")), ", menunjukkan proporsi anak usia sekolah yang berpartisipasi dalam pendidikan formal sesuai jenjangnya di provinsi ini."))),
            p(HTML(paste0("Secara komparatif, ", strong(input$provinceSelect), " menempati peringkat ke-", strong(ranking), " secara nasional berdasarkan agregasi ketiga indikator. Peringkat ini mengontekstualisasikan performa pendidikan provinsi relatif terhadap daerah lain di Indonesia.")))
        )
    )
  })
  
  output$provincialSummaryOutput <- renderUI({
    req(data_by_year())
    df_year <- data_by_year()
    summary_stats <- df_year %>% 
      summarise(across(c(RLS, HLS, APM), 
                       list(min = ~min(.x, na.rm = TRUE), 
                            max = ~max(.x, na.rm = TRUE), 
                            sd = ~sd(.x, na.rm = TRUE)), 
                       .names = "{.col}_{.fn}"))
    html_string <- paste0("<table class='summary-table'>", 
                          "<thead><tr><th>Indikator</th><th>Nilai Minimum</th><th>Nilai Maksimum</th><th>Standar Deviasi</th></tr></thead>", 
                          "<tbody>", 
                          "<tr><th>RLS (Tahun)</th><td>", round(summary_stats$RLS_min, 2), "</td><td>", round(summary_stats$RLS_max, 2), "</td><td>", round(summary_stats$RLS_sd, 2), "</td></tr>", 
                          "<tr><th>HLS (Tahun)</th><td>", round(summary_stats$HLS_min, 2), "</td><td>", round(summary_stats$HLS_max, 2), "</td><td>", round(summary_stats$HLS_sd, 2), "</td></tr>", 
                          "<tr><th>APM (%)</th><td>", round(summary_stats$APM_min, 2), "</td><td>", round(summary_stats$APM_max, 2), "</td><td>", round(summary_stats$APM_sd, 2), "</td></tr>", 
                          "</tbody></table>")
    return(HTML(html_string))
  })
  
  # --- REFAKTOR PLOT MENJADI OBJEK REAKTIF ---
  trend_plot_object <- reactive({ main_data() %>% group_by(year) %>% summarise(RLS = mean(RLS, na.rm = TRUE), HLS = mean(HLS, na.rm = TRUE), APM = mean(APM, na.rm = TRUE)) %>% pivot_longer(cols = c(RLS, HLS, APM), names_to = "indicator", values_to = "value") %>% mutate(indicator = factor(indicator, levels = c("APM", "HLS", "RLS"))) %>% plot_ly(x = ~year, y = ~value, color = ~indicator, type = 'scatter', mode = 'lines+markers', colors = c("APM" = "#3498db", "HLS" = "#2ecc71", "RLS" = "#e74c3c")) %>% layout(xaxis = list(title = "Tahun", tickvals = unique(main_data()$year), ticktext = unique(main_data()$year)), yaxis = list(title = "Nilai Rata-rata Nasional"), plot_bgcolor = "rgba(0,0,0,0)", paper_bgcolor = "rgba(0,0,0,0)", legend = list(orientation = "h", x = 0.5, y = 1.1, xanchor = 'center', yanchor = 'top', title = list(text='Indikator'))) })
  dist_plot_object <- reactive({ df <- data_by_year(); plot_ly(df, x = ~Provinsi, y = ~RLS, type = 'bar', name = 'RLS', marker = list(color = '#e74c3c')) %>% add_trace(y = ~HLS, name = 'HLS', marker = list(color = '#2ecc71')) %>% add_trace(y = ~APM, name = 'APM', yaxis = 'y2', marker = list(color = '#3498db')) %>% layout(xaxis = list(title = "Provinsi", tickangle = -45), yaxis = list(title = "RLS & HLS (Tahun)"), yaxis2 = list(title = "APM (%)", overlaying = "y", side = "right"), barmode = 'group', plot_bgcolor = "rgba(0,0,0,0)", paper_bgcolor = "rgba(0,0,0,0)", legend = list(orientation = "h", x = 0.5, y = 1.1, xanchor = 'center', yanchor = 'top', title = list(text='Indikator'))) })
  pca_plot_object <- reactive({ df <- data_by_year(); df_clean <- df %>% select(Provinsi, RLS, HLS, APM) %>% na.omit(); req(nrow(df_clean) > 2); df_numeric_for_pca <- df_clean %>% select(RLS, HLS, APM); pca_res <- prcomp(df_numeric_for_pca, scale. = TRUE); scores_data <- as.data.frame(pca_res$x); scores_data$Provinsi <- df_clean$Provinsi; loadings_data <- as.data.frame(pca_res$rotation); loadings_data$variables <- rownames(loadings_data); arrow_scale <- 4; plot_ly() %>% add_trace(data = scores_data, x = ~PC1, y = ~PC2, type = 'scatter', mode = 'markers+text', text = ~Provinsi, textposition = 'top right', marker = list(size = 10, color = '#3498db', opacity = 0.7), name = "Provinsi") %>% add_segments(data = loadings_data, x = 0, y = 0, xend = ~PC1 * arrow_scale, yend = ~PC2 * arrow_scale, color = I("#e74c3c"), linewidth = I(2.5), name = "Pengaruh Variabel") %>% add_annotations(data = loadings_data, x = ~PC1 * arrow_scale * 1.15, y = ~PC2 * arrow_scale * 1.15, text = ~variables, showarrow = FALSE, font = list(color = '#e74c3c', size = 12)) %>% layout(title = "", xaxis = list(title = paste0("PC1 (", round(summary(pca_res)$importance[2,1]*100, 1), "%)"), zeroline = TRUE), yaxis = list(title = paste0("PC2 (", round(summary(pca_res)$importance[2,2]*100, 1), "%)"), zeroline = TRUE), plot_bgcolor = "rgba(0,0,0,0)", paper_bgcolor = "rgba(0,0,0,0)", showlegend = TRUE, legend = list(orientation = "h", x = 0.5, y = 1.1, xanchor = 'center')) })
  heatmap_plot_object <- reactive({ df <- data_by_year(); df_numeric <- df %>% select(RLS, HLS, APM) %>% as.data.frame(); rownames(df_numeric) <- df$Provinsi; req(nrow(df_numeric) > 1); df_scaled <- scale(df_numeric); dist_matrix <- as.matrix(dist(df_scaled)); sim_matrix <- 1 - (dist_matrix / max(dist_matrix, na.rm = TRUE)); plot_ly(x = rownames(sim_matrix), y = colnames(sim_matrix), z = sim_matrix, type = "heatmap", colorscale = 'Viridis') %>% layout(xaxis = list(title = "", tickangle = -45), yaxis = list(title = ""), margin = list(l = 100, r = 50, b = 100, t = 50)) })
  
  # --- Render Plot dari Objek Reaktif ---
  output$trendChart <- renderPlotly({ trend_plot_object() })
  output$distributionChart <- renderPlotly({ dist_plot_object() })
  output$pcaChart <- renderPlotly({ pca_plot_object() })
  output$heatmapChart <- renderPlotly({ heatmap_plot_object() })
  
  # --- Logika untuk Tombol Unduh Grafik ---
  save_widget_and_webshot <- function(widget, file, vwidth = 992, vheight = 558) { temp_html <- tempfile(fileext = ".html"); saveWidget(widget, temp_html, selfcontained = TRUE); webshot(temp_html, file = file, delay = 0.5, vwidth = vwidth, vheight = vheight, cliprect = "viewport"); unlink(temp_html) }
  output$downloadTrendChart <- downloadHandler(filename = function() { paste0("tren_indikator_", Sys.Date(), ".png") }, content = function(file) { save_widget_and_webshot(trend_plot_object(), file) })
  output$downloadDistChart <- downloadHandler(filename = function() { paste0("distribusi_provinsi_", input$yearSelect, "_", Sys.Date(), ".png") }, content = function(file) { save_widget_and_webshot(dist_plot_object(), file) })
  output$downloadPcaChart <- downloadHandler(filename = function() { paste0("analisis_biplot_", input$yearSelect, "_", Sys.Date(), ".png") }, content = function(file) { save_widget_and_webshot(pca_plot_object(), file, vwidth = 1100, vheight = 600) })
  output$downloadHeatmapChart <- downloadHandler(filename = function() { paste0("heatmap_similaritas_", input$yearSelect, "_", Sys.Date(), ".png") }, content = function(file) { save_widget_and_webshot(heatmap_plot_object(), file, vwidth = 1100, vheight = 700) })
  
  # --- Logika untuk Peta Bivariat ---
  output$indonesiaMap <- renderLeaflet({
    req(indonesia_map_data, input$yearSelect, input$bivar_var1, input$bivar_var2)
    
    map_data_for_join <- indonesia_map_data %>%
      mutate(province_join_key = toupper(as.character(Propinsi)))
    
    stat_data <- bivariate_data()
    
    if(is.null(stat_data)) {
      return(
        leaflet() %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          setView(lng = 118, lat = -2, zoom = 5) %>%
          addControl("<h3>Pilih dua indikator yang berbeda untuk menampilkan Peta Bivariat.</h3>", position = "topright")
      )
    }
    
    merged_data <- map_data_for_join %>%
      left_join(stat_data, by = "province_join_key")
    
    bivar_colors <- c(
      "1-1"="#e8e8e8", "2-1"="#e4acac", "3-1"="#c85a5a",
      "1-2"="#b0d5df", "2-2"="#ad9ea5", "3-2"="#985356",
      "1-3"="#64acbe", "2-3"="#627f8c", "3-3"="#574249"
    )
    
    merged_data$fill_color <- bivar_colors[merged_data$bivar_cat]
    merged_data$fill_color[is.na(merged_data$fill_color)] <- "#d9d9d9"
    
    legend_html <- createBivariateLegend(input$bivar_var1, input$bivar_var2)
    
    popup_text <- paste0("<strong>", merged_data$Propinsi, "</strong><br>",
                         input$bivar_var1, ": ", round(merged_data[[input$bivar_var1]], 2), "<br>",
                         input$bivar_var2, ": ", round(merged_data[[input$bivar_var2]], 2)) %>%
      lapply(htmltools::HTML)
    
    leaflet(data = merged_data) %>%
      addProviderTiles(providers$CartoDB.Positron, options = providerTileOptions(minZoom = 4, maxZoom = 10)) %>%
      setView(lng = 118, lat = -2, zoom = 5) %>%
      addPolygons(
        fillColor = ~fill_color,
        weight = 1, opacity = 1, color = "white", dashArray = "3", fillOpacity = 0.8,
        label = ~Propinsi,
        popup = popup_text
      ) %>%
      addControl(html = legend_html, position = "bottomright")
  })
}

# ====================================================================
# 4. MENJALANKAN APLIKASI SHINY
# ====================================================================
shinyApp(ui = ui, server = server)
```