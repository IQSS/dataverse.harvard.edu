SELECT DISTINCT CAST(o.id AS BIGINT) as id, COUNT(f.id) as numFiles 
       FROM dvobject o 
       LEFT JOIN dvobject f ON f.owner_id = o.id 
       WHERE o.dtype = 'Dataset' 
       GROUP BY o.id 
       ORDER BY numfiles ASC, id;
