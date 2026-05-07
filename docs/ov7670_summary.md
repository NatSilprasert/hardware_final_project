# OV7670 Summary

สรุปนี้ดึงเฉพาะสิ่งที่จำเป็นจาก `OV7670_2006.pdf` สำหรับโปรเจกต์ Basys 3 + OV7670 + VGA

## OV7670 คืออะไร

OV7670 เป็นกล้อง CMOS ที่รับภาพได้สูงสุดระดับ VGA คือ `640x480`

กล้องตัวนี้ไม่ได้ส่งภาพผ่าน HDMI หรือ USB แต่ส่งข้อมูลภาพออกมาแบบ parallel bus:

- ข้อมูลภาพ 8 บิตผ่าน `D[7:0]`
- มี clock และ sync signal ช่วยบอกจังหวะ
- ต้องตั้งค่าผ่าน SCCB ก่อนใช้งาน

## Pin สำคัญ

| Pin | ความหมาย | ใช้ทำอะไร |
| --- | --- | --- |
| `XCLK` | input clock จาก FPGA ไปกล้อง | ทำให้กล้องทำงาน |
| `PCLK` | pixel clock จากกล้อง | FPGA ใช้จังหวะนี้อ่านข้อมูลภาพ |
| `D[7:0]` | video data | byte ของภาพ |
| `HREF` | horizontal reference | เป็น 1 ตอนข้อมูลในแถวนั้น valid |
| `VSYNC` | vertical sync | บอก frame ใหม่ |
| `SIO_C` | SCCB clock | ใช้ตั้งค่า register |
| `SIO_D` | SCCB data | ใช้ตั้งค่า register |
| `PWDN` | power down | `0` = normal mode |
| `RESET#` | reset | `0` = reset, `1` = normal mode |

## Clock

FPGA ต้องส่ง `XCLK` ให้กล้องก่อน กล้องจึงจะทำงาน

ใน datasheet ใช้ตัวอย่าง `24 MHz` เป็นหลัก แต่ในงาน FPGA อาจสร้าง clock ใกล้เคียง เช่น 25 MHz ได้ ขึ้นกับ register setup และ implementation

กล้องจะส่ง `PCLK` กลับมาให้ FPGA ใช้เป็นจังหวะอ่าน `D[7:0]`

## วิธีรับข้อมูลภาพ

หลักคิดง่าย ๆ:

```text
VSYNC บอก frame ใหม่
HREF บอกว่า byte ตอนนี้อยู่ใน active row
PCLK เป็นจังหวะอ่าน D[7:0]
D[7:0] คือข้อมูลภาพทีละ byte
```

ควรอ่านข้อมูลเฉพาะตอน `HREF = 1`

เมื่อเจอ frame ใหม่จาก `VSYNC` ให้ reset address ของ frame buffer กลับไปต้นภาพ

## Format ภาพที่แนะนำ

แนะนำใช้ `RGB565`

เหตุผล:

- ทำ grayscale, negative, edge detection ได้ตรงไปตรงมา
- แปลงไป VGA 12-bit RGB ได้ง่าย
- 1 pixel ใช้ 2 byte

รูปแบบ RGB565:

```text
byte 1 = RRRRRGGG
byte 2 = GGGBBBBB
```

แยกสี:

```text
R5 = byte1[7:3]
G6 = {byte1[2:0], byte2[7:5]}
B5 = byte2[4:0]
```

แปลงเป็น RGB444 สำหรับ VGA:

```text
R4 = R5[4:1]
G4 = G6[5:2]
B4 = B5[4:1]
```

## Register สำคัญ

ไม่ต้องเข้าใจ register ทุกตัวใน datasheet ใช้เฉพาะกลุ่มนี้ก่อน

| Register | Address | ใช้ทำอะไร |
| --- | --- | --- |
| `COM7` | `0x12` | reset register, เลือก output format, เลือก QVGA |
| `CLKRC` | `0x11` | ตั้ง clock divider ภายในกล้อง |
| `COM15` | `0x40` | ตั้ง RGB565/RGB555 และ range สี |
| `COM3` | `0x0C` | เปิด scaling / downsampling |
| `COM14` | `0x3E` | คุม PCLK และ manual scaling |
| `SCALING_XSC` | `0x70` | horizontal scaling |
| `SCALING_YSC` | `0x71` | vertical scaling |
| `SCALING_DCWCTR` | `0x72` | downsampling control |
| `SCALING_PCLK_DIV` | `0x73` | scaling PCLK divider |
| `MVFP` | `0x1E` | mirror / vertical flip |

## Register reset

`COM7[7]` ใช้ reset register ทั้งหมดกลับค่า default

ขั้นตอนที่ควรทำ:

1. เขียน `COM7` ให้ reset ก่อน
2. รอสักพัก
3. เขียน register configuration จริง

## Timing ที่ต้องจำ

ข้อมูล `D[7:0]` valid ตามจังหวะ `PCLK`

ในการออกแบบ FPGA ให้ capture ข้อมูลด้วย clock domain ของ `PCLK` แล้วค่อยเขียนเข้า BRAM

ต้องระวัง clock domain:

- กล้องใช้ `PCLK`
- VGA ใช้ pixel clock ฝั่ง VGA

ดังนั้น frame buffer จะเป็นจุดเชื่อมระหว่างสอง clock domain

## Negative และ Edge ในตัวกล้อง

OV7670 มี register บางตัวที่ทำ negative หรือ edge enhancement ได้เอง แต่โปรเจกต์นี้ควรทำ filter ใน FPGA

เหตุผล:

- requirement ต้องการ hardware-based filters
- ต้องสาธิตว่า Verilog ของเราทำ image processing จริง
- raw/grayscale/negative/edge ควรถูกเลือกด้วย switch ฝั่ง FPGA

## การต่อ pin จาก instruction

| FPGA Pin | Camera Pin |
| --- | --- |
| `P17` | `D0` |
| `N17` | `D1` |
| `M19` | `D2` |
| `M18` | `D3` |
| `L17` | `D4` |
| `K17` | `D5` |
| `C16` | `D6` |
| `B16` | `D7` |
| `A17` | `HREF` |
| `A16` | `PCLK` |
| `R18` | `PWDN` |
| `P18` | `RST` |
| `A14` | `SCL` |
| `A15` | `SDA` |
| `B15` | `VSYNC` |
| `C15` | `XCLK` |

## สรุปสำหรับ implementation

ระบบรับภาพควรทำแบบนี้:

```text
PCLK domain:
    อ่าน D[7:0] ตอน HREF = 1
    รวม 2 byte เป็น 1 pixel RGB565
    ลดเหลือ RGB444
    เขียนลง BRAM address 0 ถึง 320*240-1

VGA domain:
    สร้าง x,y ของจอ 640x480
    แปลงเป็น image_x = x / 2, image_y = y / 2
    อ่าน pixel จาก BRAM
    ส่งผ่าน filter_core
    output RGB ไป VGA
```
