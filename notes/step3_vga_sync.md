# Step 3 VGA Sync

ไฟล์ชุดนี้เพิ่มตัวสร้าง timing สำหรับจอ VGA มาตรฐาน `640x480 @ 60Hz`

## มีอะไรบ้าง

- `src/vga_sync.v`
  สร้าง `hsync`, `vsync`, `active_video`, พิกัดจอ และ address สำหรับ frame buffer
- `sim/tb_vga_sync.v`
  ทดสอบจำนวนพิกเซล active และความยาวช่วง sync ใน 1 frame

## แนวคิด

- นับ `h_count` และ `v_count` ครบ frame แบบมาตรฐาน VGA
- sync เป็น active-low
- ใช้ `x[9:1]` และ `y[9:1]` เพื่อทำ 2x scaling จาก `640x480` ไป `320x240`
- เวอร์ชันล่าสุดเปลี่ยน `image_x`, `image_y`, `frame_addr` เป็น combinational output เพื่อให้ address พร้อมสำหรับ BRAM lookup ทันที
- คำนวณ `frame_addr = image_y * 320 + image_x` ภายในโมดูลเลย เพื่อให้ต่อกับ `frame_buffer` ได้ง่าย

## ข้อจำกัดของเวอร์ชันนี้

- ตัวนับ `x`, `y`, `hsync`, `vsync`, `active_video` ยังเป็น register ใน clock domain ของ VGA ตามเดิม
- การชดเชย latency จริงของ BRAM และ filter ไม่ได้ทำในโมดูลนี้ แต่ทำใน `src/top.v`
- `sim/tb_vga_sync.v` ยังมี sample expectation เดิมอย่างน้อย 1 จุดที่ไม่ตรงกับพฤติกรรมปัจจุบันของ address/output timing จึงยังรันไม่ผ่านครบ
