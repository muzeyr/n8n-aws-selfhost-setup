### 📄 `README.md` (Yapıştırmaya Hazır – Türkçe)

# 🚀 n8n AWS Self-Hosting Otomatik Kurulum Scripti

Bu repoda, AWS EC2 sunucusu üzerinde **n8n**'i hızlıca kurabilmeniz için hazırladığım `setup-n8n.sh` adlı otomatik kurulum scripti yer almaktadır.

Script hem **subdomain** (örnek: `n8n.orneksite.com`) hem de **public IP adresi** ile çalışacak şekilde yapılandırılmıştır. Domain girerseniz **Let's Encrypt ile SSL kurulumu** yapılır, sadece IP adresi girerseniz **HTTP üzerinden** hızlı kurulum yapılır.

---

## 📌 Neler Yapıyor?

- Amazon Linux 2023 üzerinde:
  - `nginx` kurulumu ve ayarları
  - `docker` kurulumu ve kullanıcı izinleri
  - Let's Encrypt ile SSL sertifikası (subdomain verilirse)
  - n8n container kurulumu
  - SSL için otomatik yenileme cron job’u
  - IP ya da domain'e göre ortam değişkenleri ayarı

---

## 💻 Gereksinimler

- AWS EC2'de çalışan bir Amazon Linux 2023 AMI
- Açık 80 ve 443 portları
- (Opsiyonel) Subdomain ve yönlendirilmiş A kaydı
- Sabit IP kullanacaksanız: Elastic IP önerilir

---

## ⚙️ Kurulum

### 1️⃣ Reposu Klonla

```bash
git clone https://github.com/kullaniciadi/n8n-aws-selfhost-setup.git
cd n8n-aws-selfhost-setup
```

> Not: `kullaniciadi` yerine GitHub kullanıcı adınızı yazmalısınız.

### 2️⃣ Scripti Çalıştırılabilir Yap

```bash
chmod +x setup-n8n.sh
```

### 3️⃣ Scripti Başlat

```bash
./setup-n8n.sh
```

Script sizden:

- Subdomain adresinizi (örnek: `n8n.orneksite.com`)
- AWS EC2 Public IP adresinizi (örnek: `3.121.45.67`)

isteyecek ve ardından kurulumu başlatacaktır.

Subdomain girerseniz HTTPS, sadece IP girerseniz HTTP kurulumu yapılır.

## 🌐 Erişim

Kurulum tamamlandığında n8n'e şu şekilde erişebilirsiniz:

- Subdomain ile: `https://n8n.orneksite.com` ✅
- Sadece IP ile: `http://3.121.45.67` ⚠️ (SSL'siz)
