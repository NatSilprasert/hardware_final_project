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
- register set ปรับตาม Vivado reference ที่ภาพขึ้นถูกใน `project_1.srcs 2` โดยใช้ RGB565/QVGA table แบบ 165 writes
- เพิ่ม `COM7 reset` ก่อน register table และชะลอ SCCB ลงใกล้ reference เพื่อกันกล้องไม่รับ config ตอน power-up ยังไม่นิ่ง
- `camera_capture` sample ที่ `posedge PCLK` และนับ address ทุก 320 pixel เอง เพื่อลดปัญหา frame หลุดเมื่อ timing ของ `HREF` ไม่ตรงกับความกว้างที่ต้องการ
- ยังไม่มี top module, frame buffer, VGA, หรือ filters
