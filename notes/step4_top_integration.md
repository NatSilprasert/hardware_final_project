# Step 4 Top Integration

ไฟล์ชุดนี้เริ่มเชื่อมระบบจริงจากกล้องไป VGA แบบ raw video

## มีอะไรบ้าง

- `src/clock_gen.v`
  สร้าง clock 25 MHz จาก clock 100 MHz ของ Basys 3
- `src/top.v`
  รวม SCCB, camera capture, frame buffer, VGA timing และ output VGA
- `constraints/basys3_ov7670_vga.xdc`
  กำหนด pin ของ Basys 3, VGA, switch, LED และ OV7670

## แนวคิด

- ใช้ `cam_pclk` เป็น clock ฝั่งเขียน frame buffer
- ใช้ `vga_clk` 25 MHz เป็น clock ฝั่งอ่าน frame buffer
- ใช้ `config_done` เป็นเงื่อนไขก่อนปล่อยภาพออก VGA
- หน่วงสัญญาณ VGA ออก 1 clock เพื่อชดเชย read latency ของ frame buffer
- ตอนนี้ยังแสดง raw video เท่านั้น ยังไม่ผ่าน filter

## LED debug

- `led[0]` = config กล้องเสร็จแล้ว
- `led[1]` = เคยเห็น frame start จากกล้องแล้ว
- `led[2:3]` = mirror สถานะ `sw[0:1]`

## ข้อจำกัดของเวอร์ชันนี้

- `clock_gen` ยังเป็น divider แบบง่าย ไม่ได้ใช้ PLL/MMCM
- top ยังไม่ใช้ switch เลือก filter
- ยังไม่ได้รัน Vivado synthesis ในเครื่องนี้ เพราะไม่มี `vivado` ติดตั้งอยู่ใน environment ตอนนี้
