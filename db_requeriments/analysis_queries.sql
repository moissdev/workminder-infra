-- Querie de análisis 1: índice deéxito por usuario
-- Se encarga de calcular el porcentaje de tareas entregadas con un día de anticipación

SELECT 
  p.first_name || ' ' || p.last_name AS estudiante, COUNT(t.id) AS total_tareas_completadas,
  SUM(CASE WHEN t.completed_at <= (t.due_date - INTERVAL '1 day') THEN 1 ELSE 0 END) AS entregas_anticipadas,
  ROUND((SUM(CASE WHEN t.completed_at <= (t.due_date - INTERVAL '1 day') THEN 1 ELSE 0 END)::FLOAT / COUNT(t.id)) * 100, 2) AS porcentaje_exito
FROM profiles p
JOIN tasks t ON p.id = t.user_id
WHERE t.task_status = 'Completada' 
  AND t.completed_at IS NOT NULL
GROUP BY p.id, p.first_name, p.last_name
HAVING COUNT(t.id) >= 3;


-- ================================================================================

-- Querie de análisis 2: Relación entre Urgencia y anticipación de entrega
-- Analiza si las tareas que tengan mayor Urgencia realmente se completan más rápido

SELECT 
  s.subject_name AS materia, AVG(COALESCE(t.urgency, 0)) AS urgencia_promedio,
  AVG(EXTRACT(EPOCH FROM (t.due_date - t.completed_at))/3600) AS horas_adelantadas_promedio,
  MAX(t.importance) AS importancia_maxima_registrada
FROM subjects s
JOIN tasks t ON s.id = t.subject_id
WHERE t.task_status = 'Completada'
GROUP BY s.subject_name
HAVING AVG(t.urgency) > 0
ORDER BY urgencia_promedio DESC;


-- ================================================================================

-- Querie de análisis 3: Utilidad de recordatorios con tareas superdifíciles
-- Con esta querie se puede avaluar si el uso de recordatorios en tareas con complejidad e importancia de 5
-- ayudan a entregar las tareas con un día de anticipación

SELECT 
  t.task_title, t.urgency, COALESCE(COUNT(r.id), 0) AS recordatorios_configurados,
  (t.importance * t.complexity) AS factor_esfuerzo,
  CASE 
    WHEN t.completed_at <= (t.due_date - INTERVAL '1 day') THEN 'Logrado'
      ELSE 'No logrado'
  END AS meta_un_dia
FROM tasks t
LEFT JOIN reminders r ON t.id = r.task_id
JOIN subjects s ON s.id = t.subject_id
WHERE t.task_status = 'Completada'
GROUP BY t.id, t.task_title, t.urgency, t.importance, t.complexity, t.completed_at, t.due_date
HAVING (t.importance * t.complexity) > 5;
