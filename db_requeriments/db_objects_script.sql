-- Views para la base de datos

-- a) View de JOIN con 3 tablas (Profiles, Tasks, Subjects)
CREATE VIEW view_user_task_details AS
SELECT p.first_name || ' ' || p.last_name AS full_name, t.task_title, s.subject_name, t.due_date
FROM profiles p
JOIN tasks t ON p.id = t.user_id
LEFT JOIN subjects s ON t.subject_id = s.id;

-- b) View para obtener un resumen por materia
CREATE VIEW view_subject_workload AS
SELECT s.subject_name, COUNT(t.id) AS total_tasks, AVG(t.importance) AS avg_importance
FROM subjects s
LEFT JOIN tasks t ON s.id = t.subject_id
GROUP BY s.subject_name;


-- ================================================================================

-- Stored Procedures para la base de datos

-- a) Stored Procedure para reprogramar la fecha de entrega de las tareas de una materia
CREATE OR REPLACE PROCEDURE sp_reschedule_subject_tasks(p_subject_id UUID, p_days_delay INT)
AS $$
BEGIN
  UPDATE tasks 
  SET due_date = due_date + (p_days_delay || ' days')::INTERVAL
  WHERE subject_id = p_subject_id AND task_status != 'Completada';
END;
$$ LANGUAGE plpgsql;


-- ================================================================================

-- Functions para la base de datos

-- a) Function que ayuda a calcular la urgencia de forma dinámica
CREATE OR REPLACE FUNCTION fn_calculate_urgency(p_importance INT, p_complexity INT, p_due_date TIMESTAMPTZ)
RETURNS FLOAT AS $$
DECLARE
  days_left INT;
BEGIN
  days_left := EXTRACT(DAY FROM (p_due_date - NOW()));
  IF days_left <= 0 THEN RETURN (p_importance * p_complexity)::FLOAT; END IF;
  RETURN (p_importance * p_complexity)::FLOAT / days_left;
END;
$$ LANGUAGE plpgsql;

-- b) Function que retorna una tabla com las tareas críticas por usuario
CREATE OR REPLACE FUNCTION fn_get_critical_tasks(p_user_id UUID)
RETURNS TABLE (task_title TEXT, due_date TIMESTAMPTZ, score FLOAT) AS $$
BEGIN
  RETURN QUERY 
  SELECT t.task_title, t.due_date, t.urgency
  FROM tasks t
  WHERE t.user_id = p_user_id AND t.importance >= 4 AND t.task_status != 'Completada';
END;
$$ LANGUAGE plpgsql;


-- ================================================================================

-- Triggers para la base de datos

ALTER TABLE tasks ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

-- a) Trigger para llevar una auditoría de updates
CREATE OR REPLACE FUNCTION trg_fn_update_timestamp() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_tasks 
BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE PROCEDURE trg_fn_update_timestamp();


-- ================================================================================

-- Transacciones para la base de datos

-- No logramos hallar transacciones que cumplieran con los requsitos solicitados

-- ================================================================================

-- CTEs para la base de datos

-- Este CTE ayuda a obtener las tareas vencidas y la subconsulta en WHERE ayuda a filtrar los usuarios activos
WITH OverdueTasks AS (
  SELECT task_title, user_id, due_date
  FROM tasks
  WHERE due_date < NOW() AND task_status != 'Completada'
)
SELECT ot.task_title, 
  (SELECT first_name FROM profiles WHERE id = ot.user_id) AS user_name
FROM OverdueTasks ot
WHERE ot.user_id IN (SELECT id FROM profiles);
