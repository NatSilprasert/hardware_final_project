# Step 1 Camera Interface

ไฟล์ชุดนี้ทำเฉพาะส่วนติดต่อกล้องก่อน ยังไม่รวม frame buffer หรือ VGA

## มีอะไรบ้าง

- `src/ov7670_registers.v`
  เก็บตาราง register config สำหรับ OV7670 แบบ baseline
- `src/sccb_master.v`
  ส่งคำสั่ง SCCB ไปตั้งค่ากล้องทีละ register
- `src/camera_capture.v`
  รับข้อมูลจาก `D[7:0]`, `PCLK`, `HREF`, `VSYNC` แล้วรวม RGB565 เป็น RGB444
- `sim/tb_sccb_master.v`
  ทดสอบว่า FSM ของ SCCB วิ่งจนตั้งค่าเสร็จ
- `sim/tb_camera_capture.v`
  ทดสอบการรวม 2 byte เป็น 1 pixel และการสร้าง address

## ข้อจำกัดของเวอร์ชันนี้

- `sccb_master` ยังไม่ได้ตรวจ ACK จริงจังจากกล้อง
- register set เป็น baseline ที่ตั้งใจให้เริ่มต้นง่ายก่อน
- ยังไม่มี top module, frame buffer, VGA, หรือ filters
