import 'package:flutter/material.dart'; // นำเข้าแพ็กเกจ Flutter สำหรับสร้าง UI
import 'package:firebase_auth/firebase_auth.dart'; // นำเข้า Firebase Authentication สำหรับจัดการผู้ใช้

// สร้าง StatelessWidget ชื่อ ProfileScreen ซึ่งเป็นหน้าจอแสดงโปรไฟล์
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key}); // Constructor ที่ใช้ Key แบบ default

  // ฟังก์ชัน logout ผู้ใช้จาก Firebase และนำทางกลับไปยังหน้าหลัก (เช่นหน้า login หรือหน้าแรก)
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance
        .signOut(); // เรียกใช้ method สำหรับออกจากระบบผู้ใช้ปัจจุบัน

    // หลังจาก logout แล้ว ให้เปลี่ยนหน้าจอไปยัง route ชื่อ '/home'
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลผู้ใช้ที่ล็อกอินอยู่ในปัจจุบัน
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // จัดวาง widget ตรงกลางแนวตั้ง
          children: [
            const Icon(Icons.person, size: 100), // แสดงไอคอนรูปคน
            const SizedBox(height: 20), // เว้นระยะห่างแนวตั้ง 20 พิกเซล
            Text(
              user?.email ??
                  'No email', // แสดงอีเมลของผู้ใช้ ถ้าไม่มีจะแสดง 'No email'
              style: const TextStyle(
                color: Colors.grey,
              ), // กำหนดสีข้อความเป็นเทา
            ),
            const SizedBox(height: 40), // เว้นระยะห่างแนวตั้ง 40 พิกเซล
            ElevatedButton.icon(
              onPressed:
                  () => _logout(context), // เรียกฟังก์ชัน logout เมื่อกดปุ่ม
              icon: const Icon(Icons.logout), // ไอคอน logout
              label: const Text("Logout"), // ข้อความบนปุ่ม
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ), // กำหนดสีพื้นหลังของปุ่มเป็นสีแดง
            ),
          ],
        ),
      ),
    );
  }
}