# EduLens
Sebuah dasbor interaktif yang dibangun dengan R dan Shiny untuk menganalisis dan memvisualisasikan data indikator pendidikan kunci di Indonesia.

📖 Deskripsi Proyek
EduLens adalah alat analisis data yang dirancang untuk mengubah data statistik pendidikan yang kompleks menjadi wawasan yang mudah dicerna. Dasbor ini fokus pada tiga indikator utama dari Badan Pusat Statistik (BPS):

RLS (Rata-rata Lama Sekolah): Mengukur tingkat pendidikan aktual populasi.

HLS (Harapan Lama Sekolah): Mengukur ekspektasi dan akses terhadap pendidikan.

APM (Angka Partisipasi Murni): Mengukur efektivitas sistem pendidikan.

Dengan antarmuka yang intuitif, pengguna dapat melakukan eksplorasi data secara nasional maupun per provinsi, mengidentifikasi tren, membandingkan antar wilayah, dan menemukan pola tersembunyi dalam data.

✨ Fitur Utama
📊 Dashboard Interaktif: Visualisasi data yang dinamis dan responsif terhadap input pengguna (pemilihan tahun dan provinsi).

🌐 Analisis Data Nasional & Provinsi: Tampilan agregat statistik nasional dan perbandingan detail untuk setiap provinsi, lengkap dengan interpretasi statistik.

📈 Visualisasi Tren: Grafik garis untuk melihat perkembangan indikator dari tahun ke tahun.

🗺️ Analisis Spasial: Peta Bivariat interaktif untuk menganalisis korelasi antara dua indikator secara geografis.

🔬 Analisis Statistik Lanjutan:

Analisis Biplot (PCA): Memetakan hubungan antar indikator dan posisi relatif setiap provinsi.

Heatmap Similaritas: Mengelompokkan provinsi berdasarkan kemiripan profil pendidikannya.

📤 Unggah Data Kustom: Pengguna dapat mengunggah file data sendiri (.xlsx atau .csv) untuk dianalisis oleh dasbor.

📋 Manajemen Data: Fitur pratinjau data (data preview) yang interaktif, serta fungsi untuk me-reset data kembali ke data awal.

📄 Unduh Laporan & Grafik: Opsi untuk mengunduh laporan analisis lengkap dalam format PDF dan mengunduh setiap grafik sebagai gambar (.png).

📦 Teknologi yang Digunakan
Proyek ini dibangun sepenuhnya menggunakan ekosistem R, dengan beberapa pustaka utama:

Backend & Frontend: Shiny

Manipulasi Data: dplyr, tidyr

Visualisasi: plotly (Grafik Interaktif), leaflet (Peta)

Tabel Data: DT

Laporan PDF: rmarkdown
