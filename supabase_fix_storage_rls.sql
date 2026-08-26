-- ════════════════════════════════════════════════════════
-- FIX DE SEGURIDAD — Storage (buckets "examenes" y "recetas")
-- ════════════════════════════════════════════════════════
-- Mismo criterio que ya aplicamos a las tablas: reemplaza el acceso
-- del rol "anon" por acceso restringido a "authenticated". La condición
-- (bucket_id = 'examenes' / 'recetas') se mantiene igual a como estaba,
-- solo cambia el rol permitido.

-- Borrar las políticas actuales (con acceso "anon")
drop policy if exists "examenes_insert" on storage.objects;
drop policy if exists "examenes_select" on storage.objects;
drop policy if exists "examenes_delete" on storage.objects;
drop policy if exists "recetas_insert" on storage.objects;
drop policy if exists "recetas_select" on storage.objects;
drop policy if exists "recetas_delete" on storage.objects;

-- Recrear, ahora solo para "authenticated"
create policy "examenes_insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'examenes'::text);

create policy "examenes_select" on storage.objects
  for select to authenticated
  using (bucket_id = 'examenes'::text);

create policy "examenes_delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'examenes'::text);

create policy "recetas_insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'recetas'::text);

create policy "recetas_select" on storage.objects
  for select to authenticated
  using (bucket_id = 'recetas'::text);

create policy "recetas_delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'recetas'::text);

-- ════════════════════════════════════════════════════════
-- VERIFICACIÓN
-- ════════════════════════════════════════════════════════
select policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'storage' and tablename = 'objects'
and policyname in ('recetas_delete','recetas_select','recetas_insert','examenes_delete','examenes_select','examenes_insert');
-- La columna "roles" debe mostrar {authenticated} en las 6 filas.
