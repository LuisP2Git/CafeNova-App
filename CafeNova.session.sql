UPDATE usuarios 
SET rol = 'admin', 
    estado = 'activo' 
WHERE id_usuario = 4
  AND rol != 'admin';
