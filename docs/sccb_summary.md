# SCCB Summary

สรุปนี้อธิบายเฉพาะสิ่งที่โปรเจกต์นี้ใช้จริงในโค้ด เพื่อให้ดูแล้วเข้าใจว่า `src/sccb_master.v` ทำอะไร และมันคุยกับ `src/ov7670_registers.v` อย่างไร

## SCCB ในโปรเจกต์นี้มีหน้าที่อะไร

SCCB คือ bus สำหรับตั้งค่า register ของ OV7670 ก่อนเริ่มรับภาพ

ในโปรเจกต์นี้ SCCB ไม่ได้ใช้ส่งภาพ และไม่ได้ใช้ read register กลับมาเพื่อตรวจสอบสถานะเป็นหลัก

หน้าที่ของ `sccb_master` มีแค่นี้:

1. รอให้กล้องนิ่งหลังเปิดเครื่อง
2. ไล่หยิบคำสั่ง `{register_address, value}` จาก ROM
3. ส่งออกไปที่ OV7670 ทีละ register ผ่าน `SCL` และ `SDA`
4. เมื่อส่งครบทั้งหมดแล้วจึงยก `config_done`

## โมดูลที่เกี่ยวข้อง

- `src/sccb_master.v`
  ตัว master ที่สร้างสัญญาณ SCCB และไล่ส่ง register table
- `src/ov7670_registers.v`
  ROM ของค่าที่จะเขียนเข้า OV7670
- `src/top.v`
  instantiate `sccb_master` แล้วเอา `config_done` ไปแสดงที่ `led[0]`

## สัญญาณที่โค้ดใช้จริง

จาก `src/sccb_master.v`

| Signal | ทิศทาง | ใช้ทำอะไร |
| --- | --- | --- |
| `clk` | input | clock ระบบ 100 MHz ที่ใช้ขับ FSM ของ SCCB |
| `rst` | input | reset โมดูล SCCB |
| `scl` | output | clock ของ SCCB |
| `sda` | inout | data line แบบ open-drain |
| `config_done` | output | เป็น `1` เมื่อเขียน register ครบแล้ว |
| `busy` | output | เป็น `1` ระหว่างกำลัง config |
| `current_index` | output | index ของ register entry ที่กำลังทำอยู่ |

## พารามิเตอร์ที่ตั้งไว้ในโค้ด

ค่าปัจจุบันใน `src/sccb_master.v` คือ:

```text
CLK_DIVIDER  = 5000
START_DELAY  = 1000000
RESET_DELAY  = 1000000
REG_COUNT    = 172
SLAVE_ADDR_W = 0x42
```

ความหมาย:

- `CLK_DIVIDER = 5000`
  ใช้หาร clock 100 MHz เพื่อให้ SCL ช้าและปลอดภัย
  ในคอมเมนต์ระบุว่าเป็น half-period 50 us
- `START_DELAY = 1000000`
  รอประมาณ 10 ms หลัง reset ก่อนเริ่มคุยกับกล้อง
- `RESET_DELAY = 1000000`
  รอประมาณ 10 ms หลังส่ง `COM7 reset`
- `REG_COUNT = 172`
  จำนวน entry ที่ ROM report ว่า valid
- `SLAVE_ADDR_W = 0x42`
  slave address ฝั่ง write ของ OV7670

## การขับ `SDA` ในโค้ด

โค้ดใช้แนว open-drain แบบง่าย:

```verilog
assign sda = sda_drive_low ? 1'b0 : 1'bz;
```

แปลว่า:

- ถ้า `sda_drive_low = 1` โมดูลจะดึงเส้น `SDA` ลง `0`
- ถ้า `sda_drive_low = 0` โมดูลจะปล่อยเส้นเป็น high-Z

ดังนั้นค่าระดับ `1` บนบัสไม่ได้มาจาก master drive เอง แต่มาจากการปล่อยเส้นและให้ pull-up ทำงาน

## รูปแบบ transaction ที่โค้ดส่ง

สำหรับ register 1 ตัว โค้ดจะส่ง 3 byte:

```text
0x42 -> register address -> register value
```

ตัวอย่างเช่น reset กล้อง:

```text
0x42 -> 0x12 -> 0x80
```

## FSM ที่ใช้จริงใน `sccb_master`

สถานะหลักที่มีอยู่ในโค้ด:

```text
ST_POWERUP
ST_FETCH
ST_START_0
ST_START_1
ST_SEND_BIT_LO
ST_SEND_BIT_HI
ST_ACK_LO
ST_ACK_HI
ST_NEXT_BYTE
ST_STOP_LO
ST_STOP_HI
ST_STOP_REL
ST_BUS_FREE
ST_RESET_WAIT
ST_DONE
```

หน้าที่แต่ละช่วง:

- `ST_POWERUP`
  รอ `START_DELAY` ก่อนเริ่ม config
- `ST_FETCH`
  อ่าน entry ปัจจุบันจาก `ov7670_registers`
- `ST_START_0`, `ST_START_1`
  สร้าง start condition
- `ST_SEND_BIT_LO`, `ST_SEND_BIT_HI`
  ส่ง data ทีละบิต โดยเปลี่ยน `SDA` ตอน `SCL=0` และให้ slave sample ตอน `SCL=1`
- `ST_ACK_LO`, `ST_ACK_HI`
  ปล่อย `SDA` ในบิตที่ 9
- `ST_NEXT_BYTE`
  เลือกว่าจะส่ง byte ถัดไปเป็น register address, register value หรือไป stop
- `ST_STOP_LO`, `ST_STOP_HI`, `ST_STOP_REL`
  สร้าง stop condition
- `ST_BUS_FREE`
  เว้น bus idle ระหว่าง transaction
- `ST_RESET_WAIT`
  รอเพิ่มหลังส่ง `COM7 reset`
- `ST_DONE`
  ยก `config_done=1` และ `busy=0`

## การจัดการ ACK ในโค้ด

จุดสำคัญคือโค้ด “ปล่อย” `SDA` ในช่วง ACK แต่ยังไม่ได้ “ตรวจ” ค่าที่ slave ตอบกลับจริง

พฤติกรรมปัจจุบันคือ:

- มี state `ST_ACK_LO` และ `ST_ACK_HI`
- master ปล่อย `SDA`
- แต่ไม่มี logic อ่านค่า `sda` มาเช็กว่า ACK เป็น `0` หรือไม่

ดังนั้น implementation นี้เป็น write-only baseline ที่เน้นให้กล้องถูก config ได้ก่อน

## ROM register ทำงานยังไง

`sccb_master` ไม่ได้มี table อยู่ในตัวเอง แต่ไปอ่านจาก `ov7670_registers`

interface คือ:

```text
input  index
output reg_word
output valid
```

โดย `reg_word` เก็บข้อมูลแบบ:

```text
reg_word[15:8] = register address
reg_word[7:0]  = register value
```

แล้ว `current_index` จะไล่จาก `0` ขึ้นไปเรื่อย ๆ จน `valid=0`

## การ detect ว่า entry ไหนเป็น reset

ใน `ST_FETCH` โค้ดจะเช็กว่า entry ปัจจุบันคือ:

```text
register = 0x12
value    = 0x80
```

ถ้าใช่ จะตั้ง `latched_is_reset`

หลังส่ง transaction นี้เสร็จและผ่าน `ST_BUS_FREE` แล้ว state machine จะไม่ไป entry ถัดไปทันที แต่จะเข้า `ST_RESET_WAIT` เพื่อรอ `RESET_DELAY`

นี่คือเหตุผลที่โค้ดรองรับกรณี “ต้องหยุดหลัง COM7 reset” โดยอัตโนมัติ

## `config_done` ใช้ทำอะไรในระบบ

ใน `src/top.v`

- `config_done` ถูกต่อไปที่ `led[0]`
- ใช้เป็นสัญญาณบอกว่า SCCB เขียน register ครบแล้ว

สรุปเชิงระบบคือ ถ้า `led[0]` ไม่ติด แปลว่า configuration ฝั่งกล้องยังไม่จบ หรือ `sccb_master` ยังไม่วิ่งถึง `ST_DONE`

## สิ่งที่โค้ดนี้ยังไม่ได้ทำ

เพื่อไม่ให้ summary สวยเกินจริง ส่วนนี้คือข้อจำกัดของ implementation ปัจจุบัน:

- ยังไม่ตรวจ ACK จริงจาก OV7670
- ยังไม่มี read transaction เช่นอ่าน `PID` / `VER`
- ยังไม่มี retry ถ้าการเขียนล้มเหลว
- ใช้ ROM table แบบคงที่ ไม่ได้เปลี่ยน config ตาม switch หรือ mode runtime

## สรุปสั้นที่สุด

ถ้าจะอธิบาย `sccb_master` แบบประโยคเดียว:

```text
มันคือ FSM ที่ค่อย ๆ ส่ง register table 172 entries ไปยัง OV7670 ผ่าน SCCB โดยมี power-up delay, post-reset delay, และสัญญาณ config_done ปิดงานเมื่อเขียนครบ
```
