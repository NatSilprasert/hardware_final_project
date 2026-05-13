# Step 4 Top Integration

ไฟล์ชุดนี้เริ่มเชื่อมระบบจริงจากกล้องไป VGA แบบ raw video

## มีอะไรบ้าง

- `src/clock_gen.v`
  สร้าง clock 25 MHz จาก clock 100 MHz ของ Basys 3 ด้วย MMCM + BUFG และขับ `cam_xclk` ด้วย ODDR
- `src/top.v`
  รวม SCCB, camera capture, frame buffer, VGA timing และ output VGA
- `constraints/basys3_ov7670_vga.xdc`
  กำหนด pin ของ Basys 3, VGA, switch, LED และ OV7670

## แนวคิด

- ใช้ `cam_pclk` เป็น clock ฝั่งเขียน frame buffer
- ใช้ `vga_clk` 25 MHz เป็น clock ฝั่งอ่าน frame buffer
- ใช้ `mmcm_locked` รวมกับ `btnC` เพื่อสร้าง `sys_rst`
- หน่วงสัญญาณ VGA ออก 2 stage: stage แรกชดเชย BRAM read latency, stage ที่สองชดเชย `filter_core`
- ทุกโหมดภาพอ่านผ่าน BRAM และผ่าน `filter_core` แล้ว โดยเลือกโหมดจาก `sw[1:0]`

## LED debug

- `led[0]` = config กล้องเสร็จแล้ว
- `led[1]` = เคยเห็น frame start จากกล้องแล้ว
- `led[2:3]` = mirror สถานะ `sw[0:1]`

## ข้อจำกัดของเวอร์ชันนี้

- `frame_seen_latched` ถูกตั้งใน `cam_pclk` domain แล้วส่งไป LED ตรง ๆ จึงเป็น debug path ที่ยังไม่มี synchronizer กลับมาฝั่งระบบ
- XDC ล่าสุดเพิ่ม `create_clock` ให้ `cam_pclk`, จัด clock groups เป็น asynchronous, และใส่ `CLOCK_DEDICATED_ROUTE FALSE` สำหรับ input `cam_pclk`
- ยังไม่ได้ยืนยันด้วย Vivado implementation ใน environment นี้ว่าข้อจำกัด clock/pin ใหม่ผ่านครบทุกอย่าง
