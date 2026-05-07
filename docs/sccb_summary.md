# SCCB Summary

สรุปนี้ดึงเฉพาะสิ่งที่จำเป็นจาก `SCCBSpec_AN.pdf` สำหรับตั้งค่า OV7670 ด้วย FPGA

## SCCB คืออะไร

SCCB คือ Serial Camera Control Bus ของ OmniVision

คิดแบบง่ายที่สุดคือมันคล้าย I2C มาก ใช้สำหรับเขียนค่า register ในกล้อง เช่น เลือก format ภาพ, ตั้ง clock, เปิด scaling

ในโปรเจกต์นี้:

- FPGA เป็น master
- OV7670 เป็น slave
- ใช้ 2 เส้นคือ `SIO_C` และ `SIO_D`

## สัญญาณหลัก

| Signal | ความหมาย |
| --- | --- |
| `SIO_C` | clock ของ SCCB คล้าย SCL |
| `SIO_D` | data ของ SCCB คล้าย SDA |

`SIO_D` เป็น bidirectional ต้องทำเป็น tri-state ได้ เพราะบางจังหวะ master ต้องปล่อยเส้นนี้

## Address ของ OV7670

OV7670 ใช้ device slave address:

```text
0x42 = write
0x43 = read
```

สำหรับโปรเจกต์นี้ ส่วนใหญ่ใช้แค่ write ก็พอ

## รูปแบบการเขียน register

การเขียน register หนึ่งตัวใช้ 3 phase:

```text
phase 1: device address
phase 2: register address หรือ sub-address
phase 3: data ที่จะเขียน
```

ตัวอย่าง:

```text
เขียน register 0x12 ด้วยค่า 0x80

ส่ง:
0x42 -> 0x12 -> 0x80
```

ความหมายคือบอกกล้องว่า:

```text
ฉันจะเขียนค่า 0x80 ไปที่ register 0x12
```

## 1 phase มีอะไรบ้าง

1 phase มี 9 bit:

```text
8 data bits + 1 don't-care bit
```

ส่ง MSB ก่อนเสมอ:

```text
bit 7, bit 6, bit 5, ..., bit 0, X
```

`X` คือ don't-care bit สำหรับ write phase

ใน implementation เบื้องต้น master สามารถปล่อยหรือ ignore bit ที่ 9 ได้ ตามแนวทาง SCCB

## Timing แบบง่าย

Datasheet บอกว่า single bit transmission cycle `tCYC` typical คือ `10 us`

แปลว่า SCCB ไม่ต้องเร็วมาก ทำ clock ประมาณ `100 kHz` ก็เข้าใจง่ายและปลอดภัย

หลักง่าย ๆ:

- เปลี่ยนค่า `SIO_D` ตอน `SIO_C = 0`
- ให้กล้องอ่านค่าตอน `SIO_C = 1`
- ตอน idle ให้ `SIO_C = 1`
- `SIO_D` ควรอยู่ high หรือ tri-state ตามจังหวะ

## Start และ stop ใน 2-wire SCCB

OV7670 module ใช้ 2-wire SCCB ไม่มี `SCCB_E` ภายนอก

แนวคิดคล้าย I2C:

```text
start: SIO_D เปลี่ยนจาก 1 เป็น 0 ขณะ SIO_C = 1
stop:  SIO_D เปลี่ยนจาก 0 เป็น 1 ขณะ SIO_C = 1
```

แม้เอกสาร SCCB จะอธิบาย 3-wire ด้วย แต่สำหรับ OV7670 module ที่ใช้ในงานนี้ให้โฟกัส 2-wire

## สิ่งที่ SCCB module ต้องทำ

ควรทำ FSM ประมาณนี้:

```text
IDLE
START
SEND_DEVICE_ADDR
IGNORE_OR_RELEASE_9TH_BIT
SEND_REGISTER_ADDR
IGNORE_OR_RELEASE_9TH_BIT
SEND_REGISTER_VALUE
IGNORE_OR_RELEASE_9TH_BIT
STOP
NEXT_REGISTER
DONE
```

## Register table

ควรสร้าง ROM หรือ array ของ register configuration เช่น:

```text
{register_address, value}
{0x12, 0x80}  // reset
{... , ... }  // RGB444 / QVGA setup
```

แล้วให้ `sccb_master` ไล่เขียนทีละคู่จนหมด

## Read จำเป็นไหม

ไม่จำเป็นสำหรับ baseline

แต่ read มีประโยชน์ตอน debug เช่นอ่าน `PID` และ `VER`:

```text
PID = register 0x0A
VER = register 0x0B
```

ถ้าอ่านได้ถูก แปลว่า SCCB ติดต่อกล้องได้จริง

สำหรับงานแรกให้ทำ write ให้สำเร็จก่อน

## ข้อควรระวัง

- `SIO_D` ต้องเป็น `inout` และควบคุม output enable ให้ถูก
- ต้องมี pull-up หรือวงจรที่ทำให้ line กลับเป็น high ได้
- หลัง reset กล้องควรรอสักพักก่อนเริ่ม SCCB config
- หลังเขียน `COM7 reset` ควรรออีกช่วงหนึ่งก่อนเขียน config ถัดไป
- อย่าส่ง SCCB เร็วเกินไป เริ่มที่ประมาณ 100 kHz ง่ายกว่า

## สรุปสำหรับ implementation

สำหรับโปรเจกต์นี้ SCCB มีหน้าที่เดียว:

```text
ตอนเปิดเครื่อง:
    reset กล้อง
    เขียน register config ผ่าน SCCB
    เมื่อ config เสร็จ ค่อยเริ่ม capture ภาพ
```

SCCB ไม่ได้ส่งภาพ ภาพจริงออกทาง `D[7:0]`, `PCLK`, `HREF`, `VSYNC`
