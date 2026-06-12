-- ============================================================
-- PPE STOCK · กฟภ. อำเภอเบตง
-- Schema + seed data for Supabase (Postgres)
-- ============================================================
-- วิธีใช้: เปิด Supabase Dashboard → SQL Editor → New query →
-- paste ไฟล์นี้ทั้งหมด → Run
-- ============================================================

-- ---------- TABLES ----------
create table if not exists items (
  id          text primary key,
  code        text not null unique,
  name        text not null,
  cat         text not null,
  unit        text not null,
  qty         int  not null default 0,
  min_qty     int  not null default 0,
  loc         text,
  created_at  timestamptz default now()
);

create table if not exists workers (
  id          text primary key,
  name        text not null,
  pos         text,
  dept        text,
  created_at  timestamptz default now()
);

create table if not exists vehicles (
  id          text primary key,
  plate       text not null,
  type        text,
  team        text,
  created_at  timestamptz default now()
);

create table if not exists teams (
  id          text primary key,
  name        text not null,
  lead_id     text references workers(id) on delete set null,
  member_ids  text[] not null default '{}',
  plates      text[] not null default '{}',
  created_at  timestamptz default now()
);

create table if not exists movements (
  id          text primary key,
  type        text not null check (type in ('in','out')),
  kind        text check (kind in ('individual','team')),
  item        text not null,
  qty         int  not null,
  unit        text,
  party       text,
  sub         text,
  ref         text,
  date_text   text,
  created_at  timestamptz default now()
);

create index if not exists movements_created_idx on movements(created_at desc);
create index if not exists movements_party_idx   on movements(party);

-- meta: เก็บ refSeq (running number ของใบเบิก)
create table if not exists app_meta (
  k text primary key,
  v int not null
);
insert into app_meta(k,v) values ('refSeq', 24) on conflict (k) do nothing;

-- ---------- ROW LEVEL SECURITY ----------
-- ระบบนี้ใช้ single account (จนท.คลัง) — เปิด RLS
-- และอนุญาตเฉพาะผู้ที่ login แล้วเท่านั้น (authenticated)
alter table items     enable row level security;
alter table workers   enable row level security;
alter table vehicles  enable row level security;
alter table teams     enable row level security;
alter table movements enable row level security;
alter table app_meta  enable row level security;

do $$
declare t text;
begin
  for t in select unnest(array['items','workers','vehicles','teams','movements','app_meta']) loop
    execute format('drop policy if exists "auth_all" on %I', t);
    execute format(
      'create policy "auth_all" on %I for all to authenticated using (true) with check (true)', t
    );
  end loop;
end$$;

-- ---------- SEED DATA (ตัวอย่างเหมือนใน prototype) ----------
-- ลบ block นี้ออกได้ถ้าต้องการเริ่มจากฐานข้อมูลว่าง

insert into items (id,code,name,cat,unit,qty,min_qty,loc) values
('i1','PPE-001','หมวกนิรภัย (Safety Helmet)','ศีรษะ','ใบ',42,15,'ชั้น A-1'),
('i2','PPE-002','แว่นตานิรภัย (Safety Glass)','ตา/ใบหน้า','อัน',8,10,'ชั้น A-2'),
('i3','PPE-003','หน้ากากป้องกันอันตราย','ตา/ใบหน้า','อัน',24,8,'ชั้น A-2'),
('i4','PPE-004','ถุงมือยางแรงสูงพร้อมถุงมือหนัง','มือ','คู่',6,8,'ชั้น B-1'),
('i5','PPE-005','ถุงมือยางแรงต่ำพร้อมถุงมือหนัง','มือ','คู่',15,8,'ชั้น B-1'),
('i6','PPE-006','ถุงมือปีนเสา','มือ','คู่',0,6,'ชั้น B-2'),
('i7','PPE-007','ถุงมือผ้า','มือ','คู่',120,30,'ชั้น B-2'),
('i8','PPE-008','เสื้อกั๊กสะท้อนแสง','ลำตัว','ตัว',33,12,'ชั้น C-1'),
('i9','PPE-009','รองเท้าบู๊ทปีนเสา เบอร์ 38-46','เท้า','คู่',18,6,'ชั้น D-1'),
('i10','PPE-010','รองเท้าบู๊ทยางกันไฟแรงสูง','เท้า','คู่',4,5,'ชั้น D-1'),
('i11','PPE-011','เข็มขัดนิรภัย (Safety Belt)','กันตก','เส้น',21,8,'ชั้น E-1'),
('i12','PPE-012','สายกันตก (Safety Strap)','กันตก','เส้น',14,6,'ชั้น E-1'),
('i13','PPE-013','เข็มขัดนิรภัยชนิดเต็มตัว','กันตก','ชุด',9,4,'ชั้น E-2'),
('i14','PPE-014','อุปกรณ์เชือกช่วยชีวิต (Lifelines)','กันตก','ชุด',3,4,'ชั้น E-2'),
('i15','PPE-015','รองเท้านิรภัย (Safety Shoes) เบอร์ 38-46','เท้า','คู่',27,10,'ชั้น D-2'),
('i16','PPE-016','เสื้อกันฝน','ลำตัว','ตัว',40,12,'ชั้น C-2'),
('i17','PPE-017','กรวยจราจร','อื่นๆ','อัน',56,20,'ลานพัสดุ'),
('i18','PPE-018','ป้ายเตือนเขตปฏิบัติงาน','อื่นๆ','อัน',30,10,'ลานพัสดุ')
on conflict (id) do nothing;

insert into workers (id,name,pos,dept) values
('w1','สมชาย ใจดี','หัวหน้าชุดปฏิบัติการ','แผนกปฏิบัติการและบำรุงรักษา'),
('w2','ประสิทธิ์ มั่นคง','พนักงานช่าง 4','แผนกปฏิบัติการและบำรุงรักษา'),
('w3','วิรัตน์ แซ่ลิ้ม','พนักงานช่าง 3','แผนกก่อสร้าง'),
('w4','อนุชา ทองแท้','พนักงานช่าง 3','แผนกก่อสร้าง'),
('w5','กิตติศักดิ์ ศรีสุข','พนักงานขับรถ','แผนกปฏิบัติการและบำรุงรักษา'),
('w6','ธนากร พงษ์ไพร','ผู้ช่วยช่าง','แผนกมิเตอร์'),
('w7','นพดล เกตุแก้ว','หัวหน้าชุดก่อสร้าง','แผนกก่อสร้าง'),
('w8','สุรชัย บุญมา','พนักงานขับรถ','แผนกก่อสร้าง')
on conflict (id) do nothing;

insert into vehicles (id,plate,type,team) values
('v1','ผก-1234 เบตง','รถกระเช้าแก้ไฟ','ชุดปฏิบัติการที่ 1'),
('v2','ผก-5678 เบตง','รถเครน','ชุดก่อสร้างที่ 1'),
('v3','ผง-2345 เบตง','รถเครนเจาะ','ชุดก่อสร้างที่ 1'),
('v4','ผก-9012 เบตง','รถกระเช้าแก้ไฟ','ชุดปฏิบัติการที่ 2'),
('v5','บท-7788 เบตง','รถบรรทุก','ชุดก่อสร้างที่ 1')
on conflict (id) do nothing;

insert into teams (id,name,lead_id,member_ids,plates) values
('t1','ชุดปฏิบัติการที่ 1','w1','{w1,w2,w5}','{"ผก-1234 เบตง"}'),
('t2','ชุดก่อสร้างที่ 1','w7','{w7,w3,w4,w8}','{"ผก-5678 เบตง","ผง-2345 เบตง"}'),
('t3','ชุดปฏิบัติการที่ 2','w2','{w2,w6}','{"ผก-9012 เบตง"}')
on conflict (id) do nothing;

insert into movements (id,type,kind,item,qty,unit,party,sub,ref,date_text) values
('m1','out','team','หมวกนิรภัย (Safety Helmet)',4,'ใบ','ชุดปฏิบัติการที่ 1','รถ ผก-1234 เบตง','ISS-0023','10 มิ.ย. 69'),
('m2','in',null,'ถุงมือผ้า',50,'คู่','รับเข้าคลัง','PO-2569-013','RCV-0041','10 มิ.ย. 69'),
('m3','out','individual','รองเท้านิรภัย (Safety Shoes) เบอร์ 38-46',1,'คู่','วิรัตน์ แซ่ลิ้ม','แผนกก่อสร้าง','ISS-0022','9 มิ.ย. 69'),
('m4','out','team','เข็มขัดนิรภัยชนิดเต็มตัว',3,'ชุด','ชุดก่อสร้างที่ 1','รถ ผก-5678 เบตง','ISS-0021','9 มิ.ย. 69'),
('m5','in',null,'หมวกนิรภัย (Safety Helmet)',20,'ใบ','รับเข้าคลัง','PO-2569-012','RCV-0040','8 มิ.ย. 69'),
('m6','out','individual','แว่นตานิรภัย (Safety Glass)',2,'อัน','ธนากร พงษ์ไพร','แผนกมิเตอร์','ISS-0020','8 มิ.ย. 69'),
('m7','out','team','เสื้อกั๊กสะท้อนแสง',5,'ตัว','ชุดปฏิบัติการที่ 2','รถ ผก-9012 เบตง','ISS-0019','7 มิ.ย. 69'),
('m8','in',null,'รองเท้านิรภัย (Safety Shoes) เบอร์ 38-46',12,'คู่','รับเข้าคลัง','PO-2569-011','RCV-0039','6 มิ.ย. 69'),
('m9','out','individual','หมวกนิรภัย (Safety Helmet)',1,'ใบ','อนุชา ทองแท้','แผนกก่อสร้าง','ISS-0018','6 มิ.ย. 69'),
('m10','out','individual','ถุงมือผ้า',2,'คู่','สมชาย ใจดี','แผนกปฏิบัติการและบำรุงรักษา','ISS-0017','5 มิ.ย. 69'),
('m11','out','individual','แว่นตานิรภัย (Safety Glass)',1,'อัน','สมชาย ใจดี','แผนกปฏิบัติการและบำรุงรักษา','ISS-0016','3 มิ.ย. 69'),
('m12','out','individual','ถุงมือผ้า',2,'คู่','สมชาย ใจดี','แผนกปฏิบัติการและบำรุงรักษา','ISS-0015','28 พ.ค. 69'),
('m13','out','individual','หมวกนิรภัย (Safety Helmet)',1,'ใบ','สมชาย ใจดี','แผนกปฏิบัติการและบำรุงรักษา','ISS-0014','20 พ.ค. 69'),
('m14','out','individual','ถุงมือยางแรงสูงพร้อมถุงมือหนัง',1,'คู่','ประสิทธิ์ มั่นคง','แผนกปฏิบัติการและบำรุงรักษา','ISS-0013','19 พ.ค. 69'),
('m15','out','individual','ถุงมือผ้า',3,'คู่','ประสิทธิ์ มั่นคง','แผนกปฏิบัติการและบำรุงรักษา','ISS-0012','14 พ.ค. 69'),
('m16','out','individual','รองเท้านิรภัย (Safety Shoes) เบอร์ 38-46',1,'คู่','วิรัตน์ แซ่ลิ้ม','แผนกก่อสร้าง','ISS-0011','12 พ.ค. 69'),
('m17','out','individual','ถุงมือปีนเสา',1,'คู่','วิรัตน์ แซ่ลิ้ม','แผนกก่อสร้าง','ISS-0010','2 พ.ค. 69'),
('m18','out','individual','แว่นตานิรภัย (Safety Glass)',1,'อัน','ธนากร พงษ์ไพร','แผนกมิเตอร์','ISS-0009','29 เม.ย. 69'),
('m19','out','individual','เสื้อกั๊กสะท้อนแสง',1,'ตัว','อนุชา ทองแท้','แผนกก่อสร้าง','ISS-0008','24 เม.ย. 69'),
('m20','out','individual','ถุงมือผ้า',2,'คู่','อนุชา ทองแท้','แผนกก่อสร้าง','ISS-0007','18 เม.ย. 69')
on conflict (id) do nothing;
