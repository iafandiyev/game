# 🚀 CyberNeon: Quantum Rogue (iOS Oyunu)

Futuristik kiberpank mövzusunda hazırlanmış, sürətli və asılılıq yaradan **Rogue-Lite Space Arcade** iOS oyunu!

Bu layihə birbaşa **GitHub**-a yüklənib, **GitHub Actions** vasitəsilə avtomatik `.ipa` faylı kimi yığılır və **Sideloadly** ilə istənilən iPhone-a problemsiz quraşdırılır.

---

## 🎮 Oyunun Əsas Funksiyaları və Mexanikası

- 🕹️ **Dinamik Coystik və Toxunuşla İdarəetmə**: Hamar və həssas uçuş dinamikası, ProMotion (120 Hz) dəstəyi.
- ⚡ **Zəngin Silah Arsenali**:
  - **Qoşa Lazer** (Laser Blaster)
  - **Ağır Plazma Topu** (Plasma Cannon)
  - **Tesla Zəncirvari İldırımı** (Tesla Arc)
  - **Hədəfə Yönələn Raketlər** (Homing Missiles)
  - **Kvant Qara Dəliyi** (Quantum Singularity Vortex)
- 🃏 **Rogue-Lite Səviyyə Sistemi (In-game Perks)**:
  - Düşmənlərdən XP toplayaraq hər səviyyədə 3 təsadüfi kartdan birini seçmə (Multi-shot, Dondurma, Kritik Partlayış, Müdafiə Dronları, Qalxan Bərpası).
- 👾 **Düşmənlər və Nəhəng Titan Boss Döyüşləri**:
  - Kamikadze Swarmer-lər, Kəşfiyyatçı Dronlar, Ağır Kiber Kruyzerlər, Görünməz Phantom-lar və çoxmərhələli Mega Boss-lar!
- 🔊 **Procedural Audio & Səs Sintezi**:
  - `AVAudioEngine` ilə real-vaxt sintez olunan lazer, partlayış və xəbərdarlıq səsləri (xarici fayl asılılığı olmadan 100% işləyir).
- 📳 **iPhone Haptic Feedback (Taptic Engine)**:
  - Zərbələr, atəşlər və qalxan qırılmalarında fiziki toxunuş vibrasiyaları.
- 🛸 **4 Fərqli Kosmik Gəmi Anqarı**:
  - *Cyber Striker*, *Vortex Phantom*, *Titan Dreadnought*, *Solar Spectre*.
- 💎 **Daimi Təkmilləşdirmə Mağazası**:
  - Toplanan kiber-kristallar ilə HP, Qalxan, Zərbə Gücü, Atəş Tezliyi və Maqnit radiusunun artırılması.
- 🎨 **Fərdiləşdirmə & Mövzular**:
  - *Cyber Neon*, *Synthwave 80s*, *Void Matrix*, *Solar Flare*.

---

## 📲 1. GitHub-a Yükləmək və Avtomatik `.ipa` Almaq

Bu qovluğu GitHub-a yükləmək üçün kompüterinizdə terminal və ya PowerShell açıb aşağıdakı əmrləri icra edin:

```bash
cd "c:\Users\User\Desktop\Lahiyeler\CyberNeonRogue"
git init
git add .
git commit -m "CyberNeon iOS Game Initial Release"
git branch -M main
git remote add origin https://github.com/SİZİN_GITHUB_ADINIZ/CyberNeonRogue.git
git push -u origin main
```

*(Əgər GitHub-da yeni repo yaratsanız, `SİZİN_GITHUB_ADINIZ/CyberNeonRogue.git` yerinə öz linkinizi qoyun)*

---

## ⚙️ 2. `.ipa` Faylını GitHub-dan Yükləmək

1. GitHub-da reponuza daxil olun və yuxarı menyudan **"Actions"** bölməsinə keçin.
2. **"Build iOS IPA for Sideloadly"** adlı işin (workflow) avtomatik başladığını görəcəksiniz.
3. Təxminən 2-3 dəqiqə ərzində tamamlandıqdan sonra həmin workflow-un üzərinə vurun.
4. Səhifənin aşağısında **Artifacts** bölməsində **`CyberNeonRogue-IPA`** faylını görəcəksiniz. Üzərinə vuraraq zip-i kompüterinizə endirin və içindəki **`CyberNeonRogue.ipa`** faylını çıxarın.

---

## 📱 3. Sideloadly ilə iPhone-a Yükləmək

1. Kompüterinizdə **Sideloadly** proqramını açın.
2. iPhone-u USB kabel ilə kompüterə qoşun (iPhone ekranında *"Bu kompüterə etibar et"* çıxsa, **Etibar et** seçin).
3. **`CyberNeonRogue.ipa`** faylını Sideloadly pəncərəsinə sürükləyib buraxın (və ya sol tərəfdəki IPA ikonuna basıb seçin).
4. **Apple ID** xanasına öz Apple ID e-poçtunuzu yazın.
5. **"Start"** düyməsinə vurun. Təxminən 30-60 saniyə ərzində oyun iPhone-unuza quraşdırılacaq!

---

## 🔓 4. iPhone-da İlk Dəfə Açılış İcazəsi

Sideloadly ilə yüklənən proqramları ilk dəfə açarkən iOS təhlükəsizlik icazəsi tələb edir:
1. iPhone-da **Tənzimləmələr (Settings)** -> **Ümumi (General)** bölməsinə daxil olun.
2. **VPN və Cihaz İdarəetməsi (VPN & Device Management)** bölməsini açın.
3. Apple ID-nizin üzərinə vurun və **"Etibar et" (Trust Developer)** düyməsini seçin.
4. *(iOS 16+ üçün)*: **Tənzimləmələr -> Məxfilik və Təhlükəsizlik -> Tərtibatçı Modu (Developer Mode)** bölməsindən Tərtibatçı rejimini aktiv edin və telefonu yenidən başladın.

**Cyber Neon: Quantum Rogue** hazırdır! Oyunu açıb zövq ala bilərsiniz! 🎮✨
