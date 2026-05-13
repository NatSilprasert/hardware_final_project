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
- เวอร์ชันล่าสุดเปลี่ยนจากการใช้ `integer` ไปเป็น signed reg สำหรับ `gx/gy` เพื่อให้สังเคราะห์ง่ายขึ้น
- ใช้ Sobel แบบประมาณค่า `|Gx| + |Gy|` แล้ว quantize กลับเป็น grayscale 4 บิตแบบหลาย threshold

## ข้อจำกัดของเวอร์ชันนี้

- edge filter ทำงานบน stream ฝั่ง VGA หลังผ่านการขยาย 2x
- มีการบังคับขอบภาพช่วงต้นและท้ายให้เป็นสีดำเพื่อลด artifact จากหน้าต่าง 3x3 ที่ยังไม่เต็ม
- เวอร์ชันนี้เน้นให้ hardware path ทำงานครบก่อน ยังไม่จูน threshold ให้เหมาะกับสภาพแสงทุกแบบ
- `sim/tb_filter_core.v` ยังใช้เงื่อนไขทดสอบเดิมที่ไม่สอดคล้องกับ Sobel/threshold เวอร์ชันล่าสุด ทำให้เคส edge detection ยังไม่ผ่านตาม expected เดิม
