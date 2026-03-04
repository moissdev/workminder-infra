-- Tabla de Perfiles
-- Esta tabla se conectará a un esquema privado (auth.users) de Supabase para crear un nuevo registro
-- en esta tabla de manera automática cuando un usuario se logee exitosamente

CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  first_name TEXT,
  last_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

==================================================

-- Tabla de Materias

CREATE TABLE subjects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  subject_name TEXT NOT NULL,
  color TEXT DEFAULT '#3b82f6',
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL
);

==================================================

-- Tabla de Tareas

CREATE TABLE tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  subject_id UUID REFERENCES subjects(id) ON DELETE SET NULL,
  task_title TEXT NOT NULL,
  extra_note TEXT,
  due_date TIMESTAMPTZ NOT NULL,
  importance INT DEFAULT 3,
  complexity INT DEFAULT 3,
  task_status TEXT DEFAULT 'Pendiente',
  urgency FLOAT DEFAULT 0.0,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

==================================================

-- Tabla de Subtareas

CREATE TABLE subtasks (
  subtask_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  subtask_id TEXT NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE
);

==================================================

-- Tabla de Recordatorios

CREATE TABLE reminders (
  reminder_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  days_advance INT NOT NULL
);

====================================================================================================

-- SECCIÓN DE RLS Y POLICIES PARA LAS TABLAS

-- RLS para todas las tablas del esquema

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE subtasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

==================================================

-- Perfiles policies

CREATE POLICY select_own_profile 
ON profiles FOR SELECT 
USING (auth.uid() = id);

CREATE POLICY update_own_profile 
ON profiles FOR UPDATE 
USING (auth.uid() = id);

==================================================

-- Materias policies

CREATE POLICY select_own_subjects 
ON subjects FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY insert_own_subjects 
ON subjects FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY update_own_subjects 
ON subjects FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY delete_own_subjects 
ON subjects FOR DELETE 
USING (auth.uid() = user_id);

==================================================

-- Tareas policies

CREATE POLICY select_own_tasks 
ON tasks FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY insert_own_tasks
ON tasks FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY update_own_tasks
ON tasks FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY delete_own_tasks
ON tasks FOR DELETE 
USING (auth.uid() = user_id);

==================================================

-- Subtareas policies

CREATE POLICY select_own_subtasks 
ON subtasks FOR SELECT 
USING (EXISTS (
  SELECT 1 FROM tasks 
  WHERE taks.id = subtasks.task_id 
  AND tasks.user_id = auth.uid()
));

CREATE POLICY insert_own_subtasks
ON subtasks FOR INSERT 
WITH CHECK (EXISTS (
  SELECT 1 FROM tareas 
  WHERE tasks.id = subtasks.task_id 
  AND tasks.user_id = auth.uid()
));

==================================================

-- Recordatorios policies

CREATE POLICY select_own_reminders
ON reminders FOR SELECT 
USING (EXISTS (
  SELECT 1 FROM tareas 
  WHERE tasks.id = reminders.task_id 
  AND tasks.user_id = auth.uid()
));
