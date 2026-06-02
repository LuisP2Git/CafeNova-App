UPDATE usuarios 
SET rol = 'admin', 
    estado = 'activo' 
WHERE id_usuario = 9
  AND rol != 'admin';
