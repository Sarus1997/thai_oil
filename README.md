# FuelTH — แอพตรวจสอบราคาน้ำมัน

แอพ Flutter สำหรับดูราคาน้ำมัน Realtime พร้อมหาปั้มใกล้เคียง

## โครงสร้างโปรเจค

```
lib/
├── main.dart                    # Entry point
├── theme/
│   └── app_theme.dart           # สี, font, ThemeData
├── models/
│   └── fuel_model.dart          # FuelBrand, FuelPrice, GasStation
├── services/
│   ├── fuel_service.dart        # API calls + Mock data
│   └── app_provider.dart        # State management (Provider)
├── screens/
│   ├── home_screen.dart         # หน้าหลัก + Bottom Nav
│   ├── nearby_screen.dart       # แผนที่ + รายการปั้มใกล้เคียง
│   └── station_detail_screen.dart  # รายละเอียดปั้ม
└── widgets/
    └── common_widgets.dart      # BrandChip, PriceCard, Shimmer ฯลฯ
```

## วิธีติดตั้ง

### 1. ติดตั้ง Dependencies
```bash
flutter pub get
```

### 2. ตั้งค่า Google Maps API Key

**Android** — แก้ไขใน `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_ACTUAL_API_KEY"/>
```

**iOS** — แก้ไขใน `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps
GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY")
```

สร้าง API Key ได้ที่: https://console.cloud.google.com/
เปิดใช้: Maps SDK for Android, Maps SDK for iOS, Directions API

### 3. เพิ่ม Font (Sarabun)
ดาวน์โหลดจาก Google Fonts แล้วใส่ใน `assets/fonts/`
แล้วเพิ่มใน `pubspec.yaml`:
```yaml
flutter:
  fonts:
    - family: Sarabun
      fonts:
        - asset: assets/fonts/Sarabun-Regular.ttf
        - asset: assets/fonts/Sarabun-Medium.ttf  weight: 500
        - asset: assets/fonts/Sarabun-Bold.ttf    weight: 700
        - asset: assets/fonts/Sarabun-ExtraBold.ttf weight: 800
```

### 4. รัน
```bash
flutter run
```

## ต่อยอด — API จริง

### แหล่งข้อมูลราคาน้ำมัน
- **กรมธุรกิจพลังงาน (DOEB)**: https://www.doeb.go.th
- **PTT API**: ตรวจสอบผ่าน app.pttplc.com
- **Mockup API ของตัวเอง**: สร้าง backend ที่ scrape ราคาจากเว็บปั้ม

แก้ไขใน `lib/services/fuel_service.dart`:
```dart
Future<List<FuelPrice>> fetchPrices(String brandId) async {
  final response = await http.get(
    Uri.parse('https://your-api.com/prices?brand=$brandId'),
    headers: {'Authorization': 'Bearer $apiKey'},
  );
  final data = jsonDecode(response.body) as List;
  return data.map((e) => FuelPrice.fromJson(e)).toList();
}
```

## Features

- [x] ดูราคาน้ำมันแยกตามปั้ม (PTT, Shell, BCP, PT, Caltex, SUSCO)
- [x] แสดงการเปลี่ยนแปลงราคา (ขึ้น/ลง/คงที่)
- [x] ค้นหาปั้มใกล้เคียงด้วย GPS
- [x] แผนที่แสดง Pin ปั้ม
- [x] กรองตามแบรนด์
- [x] ค้นหาตามชื่อหรือพื้นที่
- [x] นำทางไปปั้มผ่าน Google Maps
- [x] รายการโปรด (UI พร้อม)
- [x] Dark theme สวยงาม

## Packages ที่ใช้

| Package               | ใช้สำหรับ           |
| --------------------- | ---------------- |
| `google_maps_flutter` | แผนที่             |
| `geolocator`          | GPS              |
| `provider`            | State management |
| `http`                | API calls        |
| `url_launcher`        | เปิด Google Maps  |
| `shared_preferences`  | บันทึก settings    |
| `intl`                | จัดรูปแบบวันที่/เวลา  |
