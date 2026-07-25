-- ════════════════════════════════════════════════════════
-- DIAGNÓSTICO: ver qué políticas existen actualmente
-- ════════════════════════════════════════════════════════
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where tablename in ('patients','appointments','invoices','app_config');

-- Si la consulta de arriba muestra políticas pero igual no insertan datos,
-- el problema es casi siempre que la policy solo cubre el rol "authenticated"
-- y no el rol "anon" (que es el que usa la publishable key sin login).

-- ════════════════════════════════════════════════════════
-- SOLUCIÓN: recrear las políticas explícitamente para anon + authenticated
-- ════════════════════════════════════════════════════════

-- Borrar políticas anteriores (por si quedaron mal configuradas)
drop policy if exists "Allow all access to patients" on patients;
drop policy if exists "Allow all access to appointments" on appointments;
drop policy if exists "Allow all access to invoices" on invoices;
drop policy if exists "Allow all access to app_config" on app_config;

-- Recrear políticas explícitas para los roles anon y authenticated
create policy "anon_full_access_patients" on patients
  for all to anon, authenticated
  using (true) with check (true);

create policy "anon_full_access_appointments" on appointments
  for all to anon, authenticated
  using (true) with check (true);

create policy "anon_full_access_invoices" on invoices
  for all to anon, authenticated
  using (true) with check (true);

create policy "anon_full_access_app_config" on app_config
  for all to anon, authenticated
  using (true) with check (true);

-- Verificar que RLS esté habilitado (debería estarlo ya, pero por si acaso)
alter table patients enable row level security;
alter table appointments enable row level security;
alter table invoices enable row level security;
alter table app_config enable row level security;

-- ════════════════════════════════════════════════════════
-- PRUEBA: insertar un registro de prueba para confirmar que funciona
-- ════════════════════════════════════════════════════════
insert into patients (id, name, species, breed, age, weight, tutor, phone, email, addresses, color, vaccinations, history)
values (999999, 'Prueba Conexión', 'dog', 'Test', '1', '10', 'Tutor Prueba', '+56900000000', '', '[]'::jsonb, '#1e8fa0', '[]'::jsonb, '[]'::jsonb)
on conflict (id) do nothing;

-- Si el insert anterior funcionó sin error, puedes verificarlo:
select * from patients where id = 999999;

-- Y luego eliminar el registro de prueba:
delete from patients where id = 999999;
