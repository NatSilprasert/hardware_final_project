# Instruction Summary

สรุปนี้ดึงเฉพาะสิ่งที่ต้องใช้จาก `instruction.md` สำหรับโปรเจกต์กล้อง OV7670 บน Basys 3

## เป้าหมายโปรเจกต์

สร้างระบบรับภาพแบบ real-time ด้วย FPGA:

1. รับภาพจากกล้อง OV7670
2. เก็บภาพลง frame buffer ใน BRAM
3. แสดงภาพออกจอผ่าน VGA
4. ใส่ image filters 3 แบบ และสลับโหมดได้ด้วย switch

## Hardware ที่ใช้

- Basys 3 FPGA Board
- OV7670 Camera Module
- VGA cable และจอ VGA

## Resolution ที่ควรเลือก

ควรเลือก baseline เป็น `320x240`

เหตุผล:

- Basys 3 มี BRAM ประมาณ `1,800 Kbits`
- ภาพ `320x240` แบบ 12-bit RGB ใช้:

```text
320 * 240 * 12 = 921,600 bits
```

ซึ่งพอใส่ใน BRAM

แต่ภาพ `640x480` แบบ 12-bit RGB ใช้:

```text
640 * 480 * 12 = 3,686,400 bits
```

ซึ่งเกิน BRAM ของ Basys 3

## VGA ที่ต้องทำจริง

ถึงภาพที่เก็บจะเป็น `320x240` แต่ VGA ต้อง generate timing เป็น `640x480 @ 60Hz`

วิธีแสดงภาพ 320x240 บนจอ 640x480:

- แนวนอน: pixel หนึ่งตัวจาก memory แสดงซ้ำ 2 clock
- แนวตั้ง: row หนึ่งแถวจาก memory แสดงซ้ำ 2 line

เรียกง่าย ๆ ว่า pixel doubling

## Filters ที่เลือก

โปรเจกต์นี้เลือก 3 filter:

1. Grayscale conversion
2. Color inversion หรือ Negative
3. Basic edge detection หรือ convolution

ควรทำ filter ใน FPGA ไม่ควรเปิด filter สำเร็จรูปในกล้อง เพราะ requirement ต้องการ hardware-based image filters

## โหมดที่ควรมี

ใช้ slide switches บน Basys 3 เลือกโหมด:

```text
00 = raw video
01 = grayscale
10 = negative
11 = edge detection
```

## Module หลักที่ควรมี

- `clock_gen`: สร้าง clock สำหรับ VGA และกล้อง
- `vga_sync`: สร้าง HSYNC, VSYNC, pixel coordinate
- `sccb_master`: ตั้งค่า register กล้อง OV7670
- `camera_capture`: อ่าน D[7:0], PCLK, HREF, VSYNC จากกล้อง
- `frame_buffer`: เก็บภาพ 320x240 ใน BRAM
- `filter_core`: เลือก raw/grayscale/negative/edge
- `top`: รวมทุกอย่างและต่อ pin จริง

## สิ่งที่ต้อง demo

- ภาพจากกล้องขึ้นจอ
- ความละเอียด baseline 320x240 หรือ 320x200
- สลับ raw และ 3 filters ได้แบบ real-time
- มี block diagram อธิบาย data path, clock domains, memory usage

## สิ่งที่ต้องส่ง

- Source code Verilog/SystemVerilog
- XDC constraints
- Testbenches ของ module สำคัญ
- Final report
- AI usage disclosure ถ้ามีการใช้ AI ช่วย

## ลำดับทำงานที่แนะนำ

1. ทำ VGA color pattern ให้ขึ้นจอก่อน
2. ทำ frame buffer 320x240 และอ่านออก VGA แบบ pixel doubling
3. ทำ SCCB ตั้งค่ากล้อง
4. ทำ camera capture
5. แสดงภาพ raw จากกล้อง
6. เพิ่ม grayscale
7. เพิ่ม negative
8. เพิ่ม edge detection
9. เขียน testbench
10. เตรียม block diagram และ report
