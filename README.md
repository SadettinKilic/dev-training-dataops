<p align="left">
  <strong>Language:</strong>
    <img src="https://img.shields.io/badge/T%C3%BCrk%C3%A7e-red">
  <a href="./README_EN.md">
    <img src="https://img.shields.io/badge/English-lightgrey">
  </a>
</p>
<p align="left">
  <!-- Core Tech -->
  <img src="https://img.shields.io/badge/dbt-Analytics-orange">
  <img src="https://img.shields.io/badge/Microsoft%20Azure-Cloud-blue">

  <!-- Architecture -->
  <img src="https://img.shields.io/badge/Architecture-Medallion-success">

  <!-- REAL CI BADGE -->
  <img src="https://github.com/SadettinKilic/dev-training-dataops/actions/workflows/dbt_ci.yml/badge.svg">

  <!-- DataOps -->
  <img src="https://img.shields.io/badge/DataOps-Automated-informational">
</p>

* * *

# 🏅 Paris 2024 Olympics DataOps & Analytics Project

Bu proje, Paris 2024 Yaz Olimpiyat Oyunları verilerini kullanarak **End-to-End (Uçtan Uca)** bir Data Engineering pipeline'ı oluşturmayı hedefler. Azure ekosistemi üzerinde **Medallion Architecture** prensiplerine uygun olarak tasarlanmış; Docker, ADF, Databricks ve dbt teknolojilerini bir araya getiren modern, konteynerize edilmiş bir veri platformudur.
* * *
## 🏗️ Mimari ve Kapsam
Proje, verinin ham halinden (CSV/Parquet) raporlanabilir Altın (Gold) tablolar haline gelene kadar geçtiği tüm süreçleri kapsar.
### **Teknoloji Stack'i**
-   **Konteynerizasyon:** Docker (Portable dbt Runtime)
-   **Orkestrasyon:** Azure Data Factory (ADF)
-   **Veri Ambarı & İşleme:** Azure Databricks (Spark & Serverless SQL Warehouse)
-   **Transformasyon:** dbt (data build tool)
-   **Veri Gölü:** Azure Data Lake Storage Gen2 (ADLS Gen2)
-   **Güvenlik:** Azure Key Vault & Managed Identity (RBAC)
-   **Sürüm Kontrolü:** GitHub (ADF & dbt integration)
### 📂 Proje Depoları (Repositories)

Proje, DataOps prensipleri gereği transformasyon kodları ve orkestrasyon yapılandırması olarak iki ayrı depoda yönetilmektedir:

| **Repository** | **İçerik** | **Link** |
| --- | --- | --- |
| **dbt Repository** | dbt Modelleri, SQL logic, CI/CD (SQLFluff, Freshness) | [🔗 dev-training-dataops](https://github.com/SadettinKilic/dev-training-dataops) |
| **ADF Repository** | Azure Data Factory Pipeline'ları, JSON tanımları, Linked Services, Triggers | [🔗 dev-training-dataops-adf](https://github.com/SadettinKilic/dev-training-dataops-adf) |
* * *
## 📂 Azure Kaynak Yapısı (Resource Group: `rg-training-dataops`)

| **Kaynak Adı** | **Türü** | **Görevi** |
| --- | --- | --- |
| `sttrainingdataops` | Storage Account | Bronze, Silver, Gold katmanlarını barındıran veri gölü. |
| `kv-training-dataops` | Key Vault | Token ve bağlantı bilgilerinin güvenli depolanması. |
| `dev-training-dataops-adf` | Data Factory | Pipeline'ların yönetimi ve zamanlanması. |
| `dbx-training-dataops-dev` | Databricks | dbt modellerinin çalıştırıldığı ana işlem motoru. |
| `dbx-connector-training-dataops-dev` | Access Connector | Databricks'in Storage'a erişimi için yönetilen kimlik. |

* * *

## 🚀 Kurulum ve Uygulama Adımları

Bu projeyi sıfırdan ayağa kaldırmak için aşağıdaki adımları izleyin:

### 1\. Altyapı ve Veri Katmanlarının Hazırlanması

Storage Account üzerinde aşağıdaki container yapısını oluşturun:
-   `source/raw_data`: Kaggle'dan indirilen ham CSV dosyaları.
-   `bronze`, `silver`, `gold`: İşlenmiş veri katmanları.
-   `dbx-managed`: Databricks Managed Catalog için ayrılmış alan.
-   `monitoring`: monitoring tablolarını içeriyor. Dashboard için kullanılacak.

### 2\. IAM ve Güvenlik Yapılandırması (Önemli)

Azure üzerinde servislerin birbiriyle konuşabilmesi için şu yetkileri tanımlayın:
-   **Storage Account:** Databricks Access Connector'a `Storage Blob Data Contributor` yetkisi verin.
-   **Key Vault:** ADF'e şifreleri okuyabilmesi için `Key Vault Secrets User` yetkisi verin. Kendi kullanıcınıza ise `Key Vault Administrator` yetkisi tanımlayın.
-   **RBAC:** Tüm kaynakları tek bir Resource Group altında toplayarak erişim yönetimini merkezileştirin.
    

### 3\. Databricks Katalog ve Şema Kurulumu

Databricks SQL Editor üzerinden Unity Catalog yapısını kurun (Öncesinde external locationları oluşturmanız gerekecektir):
```sql
    CREATE CATALOG IF NOT EXISTS dataops MANAGED LOCATION 'abfss://dbx-managed@sttrainingdataops.dfs.core.windows.net/';
    USE CATALOG dataops; 
    
    CREATE SCHEMA IF NOT EXISTS bronze MANAGED LOCATION 'abfss://bronze@sttrainingdataops.dfs.core.windows.net/';
    CREATE SCHEMA IF NOT EXISTS silver MANAGED LOCATION 'abfss://silver@sttrainingdataops.dfs.core.windows.net/';
    CREATE SCHEMA IF NOT EXISTS gold MANAGED LOCATION 'abfss://gold@sttrainingdataops.dfs.core.windows.net/';
    CREATE SCHEMA IF NOT EXISTS monitoring MANAGED LOCATION 'abfss://monitoring@sttrainingdataops.dfs.core.windows.net/';
```
### 4. Veri Tanımlama ve Bronze Tablo Yapıları

###   
Bronze katmanındaki tablolar, ham verilerin (CSV/Parquet) şemalarını koruyarak Unity Catalog altında şu şekilde tanımlanmıştır:

### 
```sql
    /* Katalog ve Şema Bağlamını Ayarla */
    USE CATALOG dataops;
    USE SCHEMA bronze;
    
    /* Sporcu Tablosu (Parquet Formatı) */
    CREATE TABLE IF NOT EXISTS bronze.raw_athletes
    USING PARQUET
    LOCATION 'abfss://bronze@sttrainingdataops.dfs.core.windows.net/athletes/';
    
    /* Antrenör Tablosu (Parquet Formatı) */
    CREATE TABLE IF NOT EXISTS bronze.raw_coaches
    USING PARQUET
    LOCATION 'abfss://bronze@sttrainingdataops.dfs.core.windows.net/coaches/';
    
    /* Etkinlik Tablosu (Parquet Formatı) */
    CREATE TABLE IF NOT EXISTS bronze.raw_events
    USING PARQUET
    LOCATION 'abfss://bronze@sttrainingdataops.dfs.core.windows.net/events/';
    
    /* NOC (Milli Olimpiyat Komiteleri) Tablosu (CSV Formatı) */
    CREATE TABLE IF NOT EXISTS bronze.raw_nocs
    USING CSV
    OPTIONS (header='true', inferSchema='true')
    LOCATION 'abfss://bronze@sttrainingdataops.dfs.core.windows.net/nocs/';

    CREATE TABLE IF NOT EXISTS dataops.monitoring.audit_logs (
      model_name STRING,
      execution_time TIMESTAMP,
      row_count LONG,
      status STRING
    ) USING DELTA;
```
### 5\. ADF Pipeline Yapılandırması
ADF üzerinde iki ana süreç yönetilmektedir:
-   **Ingestion:** `raw_to_bronze` pipeline'ı, `bronze/param.json` dosyasındaki metadata'yı okuyarak ham verileri dinamik olarak Bronze katmanına taşır.
-   **Transformation:** `dbt_dataops_gold_daily` pipeline'ı, Key Vault üzerinden aldığı token ile Databricks API'sini tetikler ve dbt modellerini koşturur.  

### 6\. dbt (Data Build Tool) Entegrasyonu
Bu repoyu bilgisayarınıza çekin.
Proje dizininde yer alan `.env.example`  dosyasını Databricks bağlantı bilgilerinizle güncelleyin ve aşağıdaki komutu çalıştırın:
```bash
    mv .env.example .env
```
Docker Compose kullanarak tüm dbt modellerini Databricks üzerinde koşturabilirsiniz:
```bash
    docker-compose up
```
### 3\. CI/CD Süreci (GitHub Actions)
### 
Proje, her kod değişikliğinde otomatik olarak devreye giren gelişmiş bir pipeline yapısına sahiptir:
-   **Static Analysis:** `sqlfluff` ile SQL kod standartları denetlenir ve otomatik düzeltilir.
-   **Containerized Execution:** dbt komutları, GitHub Actions üzerinde özel olarak hazırlanmış `dataops-dbt-runner` Docker imajı içinde koşturulur. Bu sayede kurulum süreleri %70 oranında optimize edilmiştir.
-   **Automated Docs:** Her başarılı run sonrası dbt dokümantasyonu otomatik olarak üretilir ve **GitHub Pages** üzerinde yayınlanır.
* * *

### 📊 İzleme ve Gözlemlenebilirlik (DataOps Dashboard)
### 
Projenin sağlığı, performansı ve veri kalitesi **Databricks SQL Dashboard** üzerinden anlık olarak takip edilmektedir.
-   **Pipeline Güvenilirliği:** Günlük başarılı/hatalı model çalışmaları.  
-   **Model Performansı (Wall of Shame):** En çok kaynak tüketen ve optimizasyon gerektiren modellerin tespiti.
-   **Veri Akış Hızı (Throughput):** Saniyede işlenen satır sayısı bazında SQL verimlilik analizi.
-   **Veri Hacmi Drift Analizi:** Kaynak sistemlerden gelen veri miktarındaki ani değişimlerin takibi.

### 📖 Canlı Dökümantasyon ve Veri Soyağacı (Lineage)
### 
Projenin teknik detayları ve tablolar arası ilişkiler **dbt Docs** ile otomatik olarak belgelenmektedir.
-   **[dbt Docs Sayfası](https://sadettinkilic.github.io/dev-training-dataops/)** Sağ alttaki 'Lineage' butonuna tıklayarak akış şemasını inceleyebilirsiniz.
-   **İnteraktif Soyağacı:** Bronze -> Silver -> Gold katmanları arasındaki veri akışını görsel olarak inceleyebilirsiniz.
-   **Veri Kataloğu:** Tablo şemaları, sütun açıklamaları ve uygulanan dbt testleri.
  
* * *

## ⚙️ Ekstra Konfigürasyon Notları

Projeyi kendi ortamında çalıştırmak isteyenlerin şu ayarları yapması gerekir:

-   **GitHub Secrets:** GitHub deponuzun `Settings > Secrets and variables > Actions` kısmına aşağıdaki değişkenleri eklemelisiniz:
    -   `DATABRICKS_HOST`: Databricks instance URL'iniz.
    -   `DATABRICKS_HTTP_PATH`: SQL Warehouse HTTP yolu.
    -   `DATABRICKS_TOKEN`: Key Vault'ta da sakladığınız erişim token'ı.
        
-   **Environment Variables:** dbt'nin bu secret'lara erişebilmesi için `profiles.yml` dosyasında env\_var kullanımı (Örn: `{{ env_var('DBT_HOST') }}`) yapılandırılmıştır.
    

* * *

## 🛠️ Projenin Öne Çıkan Yetenekleri
-   **Portable Runtime (Docker):** Geliştirme ortamı ile canlı ortam arasındaki farkları sıfıra indiren konteyner yapısı.
-   **Dinamik Ingestion:** Yeni bir tablo eklemek için kod yazmaya gerek kalmadan sadece `param.json` dosyasını güncellemek yeterlidir.
-   **Secure Secrets:** Hiçbir şifre veya token kodun içerisinde (hardcoded) bulunmaz; tamamen Azure Key Vault üzerinden dinamik olarak çekilir.
-   **Medallion Architecture:** Veri kalitesi her katmanda artırılarak (Raw -> Bronze -> Silver -> Gold) güvenilir bir "Single Source of Truth" oluşturulur.
-   **Zero-Install CI:** GitHub Actions'ın boş makinelerde kütüphane kurmak yerine hazır Docker imajlarını kullanarak hızlanması.
-   **Automated DataOps:** GitHub Actions ile kod kalitesi (SQLFluff) ve veri tazeliği (dbt Freshness) otomatik olarak denetlenerek hata payı minimize edilmiştir.
-   **Separation of Concerns:** Veri dönüşüm mantığı (dbt) ile veri taşıma/orkestrasyon mantığı (ADF) ayrı depolarda yönetilerek modüler ve bakımı kolay bir yapı sunulur.

* * *

## 📈 Veri Seti Hakkında

Projede kullanılan veri seti Kaggle'daki [Paris 2024 Olympic Summer Games](https://www.kaggle.com/datasets/piterfm/paris-2024-olympic-summer-games) setidir. Sporcular, antrenörler, madalyalar ve etkinlikler hakkında detaylı bilgiler içerir.

* * *

_Bu döküman, modern DataOps prensiplerine sadık kalınarak hazırlanmıştır._

