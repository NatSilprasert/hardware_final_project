# OV7670 Summary

สรุปนี้เขียนให้ตรงกับสิ่งที่มีอยู่ในโค้ดตอนนี้ เพื่อให้เปิดอ่านแล้วเข้าใจได้ว่าโปรเจกต์ใช้ OV7670 แบบไหน, ใช้ pin ไหน, ตั้งค่าอะไรบ้าง, และข้อมูลภาพถูกเอาไปใช้อย่างไร

## OV7670 ในโปรเจกต์นี้มีบทบาทอะไร

OV7670 คือแหล่งภาพของระบบ

โปรเจกต์นี้ใช้กล้องเพื่อ:

1. รับภาพเข้าทาง parallel bus
2. เก็บภาพขนาด `320x240` ลง frame buffer
3. เอาไปแสดงบน VGA `640x480` ด้วยการขยาย 2 เท่า
4. ให้ FPGA ทำ filter เองในภายหลัง

ดังนั้น OV7670 ในโค้ดนี้ไม่ได้เป็นแค่ “กล้องดิบ” แต่เป็นต้นทางของ stream ที่ถูก configure ให้เหมาะกับ pipeline นี้โดยเฉพาะ

## โมดูลในโค้ดที่เกี่ยวข้องกับ OV7670

- `src/top.v`
  ต่อ pin จริงของกล้องเข้าระบบ
- `src/clock_gen.v`
  สร้าง `cam_xclk`
- `src/sccb_master.v`
  ตั้งค่า register ผ่าน SCCB
- `src/ov7670_registers.v`
  เก็บ register table ที่จะเขียน
- `src/camera_capture.v`
  รับ `PCLK`, `HREF`, `VSYNC`, `D[7:0]` แล้วแปลงเป็น pixel สำหรับ frame buffer

## Pin ของกล้องที่โปรเจกต์ใช้จริง

จาก `src/top.v` และไฟล์ constraints ระบบใช้สัญญาณเหล่านี้:

| Camera Pin | ในโค้ดใช้ชื่อ | หน้าที่ในระบบ |
| --- | --- | --- |
| `XCLK` | `cam_xclk` | clock ที่ FPGA ส่งให้กล้อง |
| `PCLK` | `cam_pclk` | clock ที่กล้องส่งกลับมาให้ FPGA ใช้รับ byte ภาพ |
| `D[7:0]` | `cam_d[7:0]` | ข้อมูลภาพทีละ 8 บิต |
| `HREF` | `cam_href` | บอกว่าช่วงนี้ข้อมูลในแถวกำลัง valid |
| `VSYNC` | `cam_vsync` | ใช้บอก frame ใหม่ |
| `SIO_C` | `cam_scl` | clock ของ SCCB |
| `SIO_D` | `cam_sda` | data ของ SCCB |
| `PWDN` | `cam_pwdn` | ในโค้ดบังคับเป็น `0` ตลอด ให้กล้องทำงานตลอด |
| `RESET#` | `cam_reset_n` | ในโค้ดบังคับเป็น `1` ตลอด ไม่ได้กด reset pin กล้องโดยตรง |

## Clock ที่ใช้กับกล้อง

จาก `src/clock_gen.v`

- input คือ `clk_100mhz`
- โค้ดใช้ `MMCME2_BASE` สร้าง clock `25 MHz`
- clock นี้ถูก buffer ด้วย `BUFG`
- จากนั้นใช้ `ODDR` สร้าง `cam_xclk`

สรุปง่าย ๆ:

```text
100 MHz จากบอร์ด
-> MMCM
-> 25 MHz
-> ส่งเป็น XCLK ให้ OV7670
```

ส่วนฝั่งรับข้อมูล:

- OV7670 ส่ง `cam_pclk` กลับมา
- `camera_capture` ใช้ `posedge cam_pclk` เป็น clock domain รับข้อมูลภาพ

## กล้องถูกตั้งให้ส่งภาพแบบไหน

เป้าหมายของ register table ปัจจุบันคือ:

- ใช้ output แบบ `RGB`
- ใช้ pixel format ที่แปลงต่อได้ง่ายใน FPGA
- ลดขนาดภาพลงไปแนว `QVGA`
- ใช้ภาพขนาดประมาณ `320x240` เพื่อให้พอดีกับ frame buffer ที่ออกแบบไว้

ภาพที่ pipeline ฝั่ง FPGA คาดหวังคือ `RGB565` แล้วค่อยลดเป็น `RGB444`

## รูปแบบข้อมูลภาพที่โค้ดฝั่งรับภาพใช้

`src/camera_capture.v` ถูกเขียนโดยสมมติว่าข้อมูลจากกล้องมาเป็น `RGB565`

1 pixel ใช้ 2 byte:

```text
byte 1 = RRRRRGGG
byte 2 = GGGBBBBB
```

จากนั้นโค้ดลดเป็น `RGB444` แบบนี้:

```text
R4 = byte1[7:4]
G4 = bits[10:7] จากข้อมูล 16 บิตที่ latch ไว้
B4 = byte2[4:1]
```

ในโค้ดจริง:

```verilog
pixel_data <= {
    d_latch[15:12],
    d_latch[10:7],
    d_latch[4:1]
};
```

ดังนั้น summary ที่ควรจำคือ:

```text
OV7670 -> RGB565 2 bytes/pixel -> camera_capture ลดเหลือ RGB444 12-bit -> เขียนลง BRAM
```

## `camera_capture` รับภาพจาก OV7670 ยังไง

`src/camera_capture.v` คือโมดูลที่ตีความสัญญาณจากกล้องโดยตรง

สิ่งที่มันทำ:

- ใช้ `vsync` เพื่อเริ่ม frame ใหม่
- ใช้ `href` เพื่อตัดสินว่ากำลังอยู่ในช่วง byte ภาพ
- ใช้ `d_latch` เก็บ byte 2 ตัวให้รวมเป็น 1 pixel
- ใช้ `wr_hold` เพื่อสร้างจังหวะ `pixel_valid`
- ใช้ `x_count` และ `y_count` ไล่ตำแหน่งภาพ
- สร้าง `pixel_addr = y * FRAME_WIDTH + x`

พฤติกรรมสำคัญ:

- เมื่อ `vsync=1` จะ reset ตัวนับตำแหน่งกลับไปต้นเฟรม
- ขอบขึ้นของ `vsync` จะยก `frame_start`
- ทุกครั้งที่ครบ 2 byte และ `wr_hold[1]` เป็นจริง จะได้ pixel ใหม่ 1 จุด

## `test_mode` ใน `camera_capture` คืออะไร

โค้ดปัจจุบันมี input `test_mode`

ถ้า `test_mode = 1`

- โมดูลจะไม่ใช้ข้อมูลจาก `cam_data` มาสร้างสีจริง
- แต่จะเขียน pattern ทดสอบลง BRAM ตามตำแหน่ง `x_count`, `y_count`

pattern ที่ใช้คือ:

```text
{x_count[3:0], y_count[3:0], 4'hA}
```

มันมีไว้เพื่อทดสอบ path:

```text
camera timing -> frame buffer -> VGA
```

โดยไม่ต้องพึ่งว่ากล้องส่งภาพถูกแล้วหรือยัง

ใน `src/top.v` ตอนนี้ต่อ `test_mode(1'b0)` อยู่ จึงยังใช้โหมดภาพจริงตามปกติ

## Register table ปัจจุบันตั้งค่าอะไรบ้าง

`src/ov7670_registers.v` มี `REG_COUNT = 172`

ความหมายในทางปฏิบัติคือ:

- 1 entry แรกคือ reset
- หลังจากนั้นเป็นชุด register ที่ configure กล้องให้ทำงานในโหมดที่ระบบนี้ต้องการ

กลุ่ม register สำคัญที่เห็นชัดในโค้ด:

- `0x12 = 0x80`
  reset กล้อง
- `0x12 = 0x14`
  `COM7` สำหรับโหมด `QVGA + RGB`
- `0x40 = 0xD0`
  `COM15` สำหรับรูปแบบ RGB/range ที่ใช้กับ pipeline นี้
- `0x0C = 0x04`
  `COM3` เปิด scaling/DCW
- `0x3E = 0x19`
  `COM14` ใช้ manual scaling และ PCLK divider
- `0x70 = 0x3A`, `0x71 = 0x35`, `0x72 = 0x11`, `0x73 = 0xF1`
  กลุ่ม `SCALING_*` สำหรับลง QVGA
- `0x1E = 0x31`
  `MVFP` เกี่ยวกับ mirror/flip

นอกจากนี้ท้าย table ยังมี register เพิ่มสำหรับภาพคมขึ้น:

- `0x3F = 0x05`
  edge enhancement factor
- `0x75 = 0x19`
  lower limit ของ edge enhancement
- `0x76 = 0x11`
  edge + white/black pixel correction
- `0x4C = 0x04`
  de-noise threshold
- `0x41 = 0x08`
  เปิด edge enhancement
- `0x56 = 0x40`
  contrast center point

## สิ่งที่โปรเจกต์ “ให้กล้องทำ” กับ “ไม่ให้กล้องทำ”

สิ่งที่ให้กล้องทำ:

- สร้างภาพ RGB
- downsample/scaling ไปทาง QVGA
- ตั้งค่าโทนภาพพื้นฐานตาม register table
- เปิด edge enhancement/sharpness บางส่วนใน sensor DSP

สิ่งที่ไม่พึ่งกล้องทำเป็น requirement หลัก:

- grayscale mode
- negative mode
- edge detection สำหรับโหมดแสดงผล

สามอย่างนี้ทำใน `src/filter_core.v` ฝั่ง FPGA ไม่ได้ใช้ effect mode ของ OV7670 มาแทน

## ความสัมพันธ์กับ frame buffer และ VGA

ภาพรวม data path ในโค้ดคือ:

```text
OV7670
-> cam_pclk / cam_href / cam_vsync / cam_d[7:0]
-> camera_capture
-> pixel_addr + pixel_data + pixel_valid
-> frame_buffer
-> vga_sync อ่านกลับด้วย address แบบ 2x scaling
-> filter_core
-> VGA output
```

นี่เป็นจุดสำคัญมาก เพราะหมายความว่า OV7670 ไม่ได้ต่อออก VGA ตรง ๆ แต่ส่งผ่าน BRAM ก่อนเสมอ

## สิ่งที่ควรระวังเวลาอ่านโค้ดส่วนนี้

- `cam_reset_n` ถูกตรึงเป็น `1` ใน `top` ดังนั้นการ reset กล้องหลัก ๆ พึ่ง `COM7 reset` ผ่าน SCCB
- `cam_pwdn` ถูกตรึงเป็น `0` เพื่อไม่ให้กล้องเข้าสู่ power-down
- clock domain ของกล้องคือ `cam_pclk` และแยกจากฝั่ง VGA
- `frame_start` ถูกสร้างจากขอบขึ้นของ `vsync`
- โค้ดรับภาพคาดหวัง byte stream ที่ตรงกับ `RGB565`; ถ้า register format เปลี่ยน `camera_capture` จะไม่ decode ถูก

## สรุปสั้นที่สุด

ถ้าจะอธิบาย OV7670 ในโปรเจกต์นี้แบบประโยคเดียว:

```text
OV7670 ถูกตั้งผ่าน SCCB ให้ส่งภาพแนว QVGA/RGB565, จากนั้น FPGA รับข้อมูลใน clock domain ของ PCLK, ลดเป็น RGB444, เก็บลง BRAM, แล้วค่อยนำไปแสดงและทำ filter ต่อบน VGA path
```
