-- ════════════════════════════════════════════════════════
-- FIX DE SEGURIDAD — restringir acceso a solo usuarios autenticados
-- ════════════════════════════════════════════════════════
-- Este script reemplaza las políticas anteriores (que daban acceso
-- total al rol "anon", es decir a cualquiera que tuviera la
-- publishable key — que está visible en el HTML público del sitio).
--
-- A partir de este script, SOLO un usuario que haya iniciado sesión
-- real contra Supabase Auth (rol "authenticated") puede leer o
-- escribir en estas tablas. El rol "anon" queda sin ningún acceso.
--
-- Requisito antes de correr esto: ya debe existir el usuario en
-- Authentication → Users con el que Constanza inicia sesión
-- (ver checklist aparte). Si corres esto antes de crear ese usuario,
-- la app dejará de poder leer/escribir datos hasta que actualices
-- también el HTML con el login real.

-- Borrar las políticas anteriores (las que daban acceso a "anon")
drop policy if exists "anon_full_access_patients" on patients;
drop policy if exists "anon_full_access_appointments" on appointments;
drop policy if exists "anon_full_access_invoices" on invoices;
drop policy if exists "anon_full_access_app_config" on app_config;
drop policy if exists "Allow all access to patients" on patients;
drop policy if exists "Allow all access to appointments" on appointments;
drop policy if exists "Allow all access to invoices" on invoices;
drop policy if exists "Allow all access to app_config" on app_config;

-- Crear políticas nuevas: SOLO rol "authenticated"
create policy "authenticated_only_patients" on patients
  for all to authenticated
  using (true) with check (true);

create policy "authenticated_only_appointments" on appointments
  for all to authenticated
  using (true) with check (true);

create policy "authenticated_only_invoices" on invoices
  for all to authenticated
  using (true) with check (true);

create policy "authenticated_only_app_config" on app_config
  for all to authenticated
  using (true) with check (true);

-- Confirmar que RLS sigue habilitado (no debería haber cambiado)
alter table patients enable row level security;
alter table appointments enable row level security;
alter table invoices enable row level security;
alter table app_config enable row level security;

-- ════════════════════════════════════════════════════════
-- VERIFICACIÓN
-- ════════════════════════════════════════════════════════
-- Después de correr esto, revisa que las políticas quedaron así:
select schemaname, tablename, policyname, roles, cmd
from pg_policies
where tablename in ('patients','appointments','invoices','app_config');
-- La columna "roles" debe mostrar {authenticated} en las 4 filas,
-- NO debe aparecer "anon" en ninguna.

-- ════════════════════════════════════════════════════════
-- IMPORTANTE: también revisar el Storage (buckets "examenes" y "recetas")
-- ════════════════════════════════════════════════════════
-- Este script solo cubre las tablas. Los buckets de Storage tienen sus
-- propias políticas (Storage → Policies en el dashboard de Supabase).
-- Ve a esa sección y aplica el mismo criterio: solo "authenticated"
-- debería poder subir/leer archivos de examenes y recetas, no "anon".
