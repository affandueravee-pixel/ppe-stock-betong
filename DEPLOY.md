# คู่มือ Deploy PPE STOCK ไปใช้งานจริง

ทำตามขั้นตอนตามลำดับ ใช้เวลารวมประมาณ **20–30 นาที** ค่าใช้จ่าย **0 บาท**

---

## ขั้นที่ 1 — สร้าง Supabase project (10 นาที)

### 1.1 สมัครและสร้างโปรเจกต์
1. ไปที่ https://supabase.com → **Start your project** → sign in ด้วย GitHub
2. กด **New project**
   - Name: `ppe-stock-betong`
   - Database Password: ตั้งให้ปลอดภัย (เก็บไว้ในที่ปลอดภัย)
   - Region: เลือก **Southeast Asia (Singapore)** — ใกล้ไทยที่สุด
   - Plan: **Free**
3. รอราว 1–2 นาทีให้ project provisioning เสร็จ

### 1.2 ใส่ schema + ข้อมูลตัวอย่าง
1. ในแถบซ้าย กด **SQL Editor** → **New query**
2. เปิดไฟล์ [supabase/schema.sql](supabase/schema.sql) ในโปรเจกต์นี้ → copy ทั้งหมด → paste ลง editor
3. กด **Run** (มุมขวาล่าง)
4. ควรเห็น "Success. No rows returned." — เสร็จแล้ว

### 1.3 สร้าง user สำหรับ จนท. คลัง
1. ไปที่ **Authentication** → **Users** → **Add user** → **Create new user**
2. ใส่:
   - Email: เช่น `stock@pea-betong.local` (ใช้อะไรก็ได้ที่จำง่าย — ไม่ต้องเป็น email จริง)
   - Password: ตั้งรหัสที่ปลอดภัย
   - ✅ **Auto Confirm User** (สำคัญ! ไม่งั้นต้องยืนยัน email)
3. กด **Create user**

### 1.4 คัดลอก URL + Anon Key
1. ไปที่ **Project Settings** (เฟือง) → **API**
2. คัดลอก 2 ค่า:
   - **Project URL** เช่น `https://abcdefgh.supabase.co`
   - **anon public** key (เป็น string ยาว ๆ)
3. ⚠️ ห้ามคัดลอก `service_role` key — อันนั้นห้ามเปิดสาธารณะ

---

## ขั้นที่ 2 — ใส่ค่า config ลงในเว็บ (1 นาที)

เปิดไฟล์ [index.html](index.html) หาบรรทัดประมาณ 14–22:

```javascript
window.PPE_CONFIG = {
  SUPABASE_URL: 'PASTE_YOUR_PROJECT_URL_HERE',
  SUPABASE_ANON_KEY: 'PASTE_YOUR_ANON_KEY_HERE'
};
```

แทนที่ค่า `PASTE_...` ด้วยที่ copy มาจากขั้น 1.4 → save

ทดสอบในเครื่อง: เปิด http://localhost:4321/ → ควรเห็นหน้า login → ใส่ email/password ที่สร้างไว้ → เข้าได้

---

## ขั้นที่ 3 — Push ขึ้น GitHub (5 นาที)

```powershell
cd "D:\PPE PAY"
git init
git add index.html supabase/schema.sql DEPLOY.md README.md .claude
git commit -m "Initial commit: PPE STOCK app"
```

> ⚠️ อย่า commit ไฟล์ `_design_src/` — ไฟล์นั้นเป็นแหล่งต้นทาง ไม่ใช่โค้ดที่ deploy

จากนั้นไปที่ https://github.com/new สร้าง repo ใหม่ (private ก็ได้) ชื่อ `ppe-stock-betong` → ทำตามคำสั่งที่ GitHub แสดง:

```powershell
git remote add origin https://github.com/<your-username>/ppe-stock-betong.git
git branch -M main
git push -u origin main
```

---

## ขั้นที่ 4 — Deploy ไป Cloudflare Pages (5 นาที)

1. สมัคร/login ที่ https://dash.cloudflare.com
2. ในเมนูซ้าย → **Workers & Pages** → **Create application** → **Pages** → **Connect to Git**
3. Authorize Cloudflare ให้เข้าถึง GitHub → เลือก repo `ppe-stock-betong`
4. ตั้งค่า build:
   - Project name: `ppe-stock-betong`
   - Production branch: `main`
   - Framework preset: **None**
   - Build command: *(เว้นว่าง)*
   - Build output directory: `/`
5. กด **Save and Deploy**
6. รอสัก 30 วินาที → จะได้ URL เช่น `https://ppe-stock-betong.pages.dev`

🎉 **เสร็จแล้ว!** เปิด URL นั้น → login → ใช้งานได้จริง

---

## การ deploy เวอร์ชันใหม่

แค่ push code → Cloudflare Pages auto-deploy ภายใน 1 นาที:

```powershell
git add .
git commit -m "อัปเดต ..."
git push
```

---

## หมายเหตุด้านความปลอดภัย

- ✅ **anon key เปิดเผยใน HTML ได้** — มันถูกปกป้องด้วย RLS (Row Level Security) ที่ schema.sql ตั้งไว้แล้ว: ต้อง login จึงจะอ่าน/เขียนได้
- ⚠️ **อย่าใส่ `service_role` key** ใน index.html เด็ดขาด — มันข้าม RLS ทุกอย่าง
- 🔒 หาก จนท. ลาออก/เปลี่ยนคน → ไป Supabase → Auth → Users → reset password หรือสร้าง user ใหม่
- 💾 ข้อมูลทั้งหมดอยู่ใน Supabase — **backup ได้** ที่ Project Settings → Database → Backups (free tier ให้ daily backup 7 วัน)

---

## ปัญหาที่อาจเจอ

**"เข้าสู่ระบบไม่สำเร็จ: Email not confirmed"**
→ ไป Auth → Users → คลิก user → กด "Send magic link" หรือลบแล้วสร้างใหม่โดยติ๊ก **Auto Confirm User**

**โหลดข้อมูลไม่สำเร็จ**
→ เช็คว่า SUPABASE_URL และ ANON_KEY ใน index.html ถูกต้อง (ไม่มี space ต้น/ท้าย)

**Cloudflare deploy fail**
→ เช็คว่า Build output directory เป็น `/` ไม่ใช่ `dist` หรือ `build`

**อยากเริ่มจากฐานข้อมูลว่าง (ไม่มี seed)**
→ ก่อน paste schema.sql ลบบล็อก `-- SEED DATA` ตั้งแต่ `insert into items` ลงไปจนจบไฟล์

---

## สถาปัตยกรรมที่ deploy

```
ผู้ใช้ (เบราว์เซอร์)
      │
      ▼
Cloudflare Pages  ◄── push code → GitHub → auto build
(static HTML, ฟรี, มี PoP ที่กรุงเทพ)
      │
      │ Supabase JS SDK
      ▼
Supabase (Singapore)
├── PostgreSQL — items / workers / vehicles / teams / movements
├── Auth — single user (จนท.คลัง)
└── Row Level Security — ต้อง login จึงเข้าถึงได้
```
