# 🚀 n8n AWS Self-Hosting Kurulum Scripti

Bu proje, AWS üzerinde **n8n**'i hızlı ve otomatik bir şekilde kurmak isteyenler için hazırlanmış bir `setup-n8n.sh` betiğidir.  
Script ile birlikte Docker, Nginx, SSL (Let's Encrypt) ve n8n kurulumu tek komutla yapılabilir.

---

## 📦 Özellikler

- AWS EC2 (Amazon Linux 2023) üzerinde çalışır
- Docker kurulumu ve başlatılması
- Nginx kurulumu ve yapılandırılması
- SSL (Let's Encrypt) kurulumu
- n8n Docker container başlatılması
- SSL otomatik yenileme cron job'u

---

## ⚙️ Kurulum Adımları

1. Sunucunuza SSH ile bağlanın
2. Script dosyasını oluşturun:
   ```bash
   nano setup-n8n.sh
   ```
→ Bu repodaki setup-n8n.sh içeriğini yapıştırın ve kaydedin.

Script’i çalıştırılabilir yapın:

```bash
chmod +x setup-n8n.sh
```
Script’i çalıştırın:

```bash
./setup-n8n.sh
```
Script sizden domain adınızı soracak (örnek: n8n.seninwebsiten.com)


