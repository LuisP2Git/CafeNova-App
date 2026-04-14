UPDATE usuarios 
SET rol = 'admin', 
    estado = 'activo' 
WHERE id_usuario = 1 
  AND rol != 'admin';
