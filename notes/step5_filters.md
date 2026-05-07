# Step 5 Filters

ไฟล์ชุดนี้เพิ่ม filter สำหรับ raw, grayscale, negative และ edge detection

## มีอะไรบ้าง

- `src/filter_core.v`
  โมดูลเลือกโหมดภาพตาม switch และทำ edge detection แบบใช้ line buffer
- `sim/tb_filter_core.v`
  ทดสอบทั้ง 4 โหมด

## แนวคิด

- `00` = raw
- `01` = grayscale
- `10` = negative
- `11` = edge detection
- edge detection ใช้ภาพ grayscale และหน้าต่าง 3x3 แบบเลื่อนด้วย line buffer 2 แถว
- ใช้ Sobel แบบคร่าว ๆ แล้ว quantize กลับเป็น grayscale 4 บิต

## ข้อจำกัดของเวอร์ชันนี้

- edge filter ทำงานบน stream ฝั่ง VGA หลังผ่านการขยาย 2x
- เวอร์ชันนี้เน้นให้ hardware path ทำงานครบก่อน ยังไม่จูนคุณภาพ edge ให้สวยที่สุด
