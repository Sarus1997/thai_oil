# Fuel_TH — แอพตรวจสอบราคาน้ำมัน

## 🗺️ ตัวอย่าง UI ของแอพ

<center>

<img src="./assets/ex/ex1.png" alt="FuelTH Demo 1" width="160" /> 
<img src="./assets/ex/ex2.png" alt="FuelTH Demo 2" width="160" /> 
<img src="./assets/ex/ex3.png" alt="FuelTH Demo 3" width="160" /> 
<img src="./assets/ex/ex4.png" alt="FuelTH Demo 4" width="160" /> 

</center>

<br/>
<p align="center"> 
<a href="https://flutter.dev"> <img src="https://img.shields.io/badge/Flutter-3.22+-02569B?style=flat&logo=flutter&logoColor=white" alt="Flutter"> </a> 
<a href="https://dart.dev"> <img src="https://img.shields.io/badge/Dart-3.4+-0175C2?style=flat&logo=dart&logoColor=white" alt="Dart"> </a> 
<a href="https://www.openstreetmap.org"> <img src="https://img.shields.io/badge/OpenStreetMap-7EBC6F?style=flat&logo=openstreetmap&logoColor=white" alt="OSM"> </a> 
<a href="https://github.com/yourusername/fuelth/blob/main/LICENSE"> <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License"> </a> <br> <strong>📍 รู้ราคาน้ำมันจริงรายวัน · 🔍 ค้นหาปั้มใกล้คุณด้วย OpenStreetMap</strong> </p>


## 📚 APIs ที่ใช้

| API                                                       | ใช้สำหรับ              | ค่าใช้จ่าย |
| --------------------------------------------------------- | ------------------- | ------- |
| [Thai Oil API](https://api.chnwt.dev/thai-oil-api/latest) | ราคาน้ำมัน             | ฟรี      |
| [Overpass API](https://overpass-api.de)                   | ค้นหาปั้มใกล้เคียง       | ฟรี      |
| [Nominatim](https://nominatim.openstreetmap.org)          | Geocoding (ค้นหาพื้นที่) | ฟรี      |
| [OpenStreetMap + CartoDB](https://carto.com)              | แผนที่ Dark Theme     | ฟรี      |

## 📁 โครงสร้างโปรเจค

```
lib/
├── main.dart
├── theme/app_theme.dart
├── models/fuel_model.dart
├── services/
│   ├── fuel_service.dart        # Thai Oil API (cache 30 นาที)
│   ├── places_service.dart      # Overpass API + Nominatim
│   └── app_provider.dart        # Provider state
├── screens/
│   ├── home_screen.dart         # หน้าหลัก + ราคา
│   ├── nearby_screen.dart       # OSM Map + ค้นหา
│   └── station_detail_screen.dart
└── widgets/
    └── common_widgets.dart
```

## 🚀 วิธีติดตั้ง

```bash
flutter pub get
flutter run
```

## ✨ Features

- ✅ ราคาน้ำมันจาก Thai Oil API (ข้อมูลจริงรายวัน)
- ✅ เลือกปั้ม: PTT, Shell, BCP, PT, Caltex, SUSCO, IRPC, Pure
- ✅ แผนที่ Dark Theme (CartoDB Dark Matter)
- ✅ ค้นหาปั้มใกล้เคียงด้วย Overpass API
- ✅ ค้นหาพื้นที่ด้วย Nominatim geocoding
- ✅ เลือกรัศมี 1/3/5/10 กม.
- ✅ กรองตามแบรนด์
- ✅ Custom Map Pin สีแยกตามแบรนด์
- ✅ แตะ Pin บนแผนที่ → เปิด detail
- ✅ นำทางผ่าน Google Maps / Apple Maps
- ✅ Cache 30 นาที

## 📄 License
```
โครงการนี้เผยแพร่ภายใต้ MIT License — สามารถนำไปใช้ แก้ไข และแจกจ่ายได้อย่างอิสระ
(โปรดให้เครดิต OpenStreetMap และ Thai Oil API ตามข้อกำหนดของแต่ละ provider)
```

<br>
<hr>
<p align="center"> <strong>Made with Flutter & OpenStreetMap</strong>
<br><strong> Developed by <a href="https://www.facebook.com/saharat.suwannapapond.7/">Sarus</a></strong> ⭐ อย่าลืมกดดาว Github ถ้าชอบโปรเจคนี้! </p>