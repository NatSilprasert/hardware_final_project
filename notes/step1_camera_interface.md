# Step 1 Camera Interface

ไฟล์ชุดนี้ทำเฉพาะส่วนติดต่อกล้องก่อน ยังไม่รวม frame buffer หรือ VGA

## มีอะไรบ้าง

- `src/ov7670_registers.v`
  เก็บตาราง register config สำหรับ OV7670 แบบ baseline
- `src/sccb_master.v`
  ส่งคำสั่ง SCCB ไปตั้งค่ากล้องทีละ register
- `src/camera_capture.v`
  รับข้อมูลจาก `D[7:0]`, `PCLK`, `HREF`, `VSYNC` แล้วรวม RGB565 เป็น RGB444 พร้อม `test_mode`
- `sim/tb_sccb_master.v`
  ทดสอบว่า FSM ของ SCCB วิ่งจนตั้งค่าเสร็จ
- `sim/tb_camera_capture.v`
  ทดสอบการรวม 2 byte เป็น 1 pixel และการสร้าง address

## ข้อจำกัดของเวอร์ชันนี้

- `sccb_master` ยังไม่ได้ตรวจ ACK จริงจังจากกล้อง
- register set ปรับตาม Vivado reference เดิม แต่ย้ายมาอยู่ใน `src/ov7670_registers.v` โดยตรงและขยายเป็น table `172` entries
- เพิ่ม `COM7 reset` ก่อน register table, แทรก `RESET_DELAY`, และเขียน FSM SCCB ให้มี state ชัดขึ้นทั้ง start/bit/ack/stop/bus-free
- `camera_capture` เปลี่ยนจาก state แบบ `byte_phase` มาเป็น `d_latch + wr_hold` เพื่อหน่วง `pixel_valid` ให้สอดคล้องกับการจับคู่ byte
- `camera_capture` คำนวณ `pixel_addr` แบบ combinational จาก `y_count * FRAME_WIDTH + x_count` และมี `test_mode` สำหรับเขียน gradient pattern ลง BRAM โดยไม่พึ่งข้อมูลกล้องจริง
- ยังไม่มี top module, frame buffer, VGA, หรือ filters

## หมายเหตุล่าสุด

- ตาราง register มีการเปิด scaling/QVGA ชัดขึ้น เช่น `COM3`, `COM14`, `SCALING_XSC`, `SCALING_YSC`, `SCALING_PCLK_DIV`
- มีการเพิ่มกลุ่ม register ด้าน sharpness/edge enhancement ท้ายตาราง
- `sim/tb_camera_capture.v` ยังอ้างพารามิเตอร์ `MAX_ADDRESS` ที่ถูกลบออกจาก `src/camera_capture.v` แล้ว ดังนั้น testbench นี้ยัง compile ไม่ผ่านจนกว่าจะอัปเดตตาม interface ใหม่
