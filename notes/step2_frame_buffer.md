# Step 2 Frame Buffer

ไฟล์ชุดนี้เพิ่มหน่วยความจำกลางสำหรับคั่นระหว่าง clock ฝั่งกล้องกับ clock ฝั่ง VGA

## มีอะไรบ้าง

- `src/frame_buffer.v`
  หน่วยความจำภาพแบบ dual-clock
- `sim/tb_frame_buffer.v`
  ทดสอบเขียนด้วย clock หนึ่ง แล้วอ่านด้วยอีก clock หนึ่ง

## แนวคิด

- ฝั่งเขียนใช้ `wr_clk` จากกล้อง
- ฝั่งอ่านใช้ `rd_clk` จาก VGA
- เก็บข้อมูลต่อพิกเซลเป็น `RGB444` ขนาด 12 บิต
- address ใช้รูปแบบ `y * 320 + x`

## ข้อจำกัดของเวอร์ชันนี้

- เวอร์ชันนี้ใช้ behavioral memory เพื่อให้ simulation และโครงสร้างรวมชัดก่อน
- ตอน integrate กับ Vivado ภายหลังอาจต้องดูว่า synthesis map เป็น BRAM ตามที่ต้องการหรือไม่
