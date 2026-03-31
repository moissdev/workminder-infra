CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);


CREATE TABLE subjects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  subject_name TEXT NOT NULL UNIQUE,
  color TEXT DEFAULT '#3b82f6'
);


CREATE TABLE tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  subject_id UUID REFERENCES subjects(id) ON DELETE SET NULL,
  task_title TEXT NOT NULL,
  due_date TIMESTAMPTZ NOT NULL,
  importance INT DEFAULT 3,
  complexity INT DEFAULT 3,
  urgency FLOAT DEFAULT 1.0,
  extra_note TEXT,
  task_status TEXT DEFAULT 'Pendiente',
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);



CREATE TABLE subtasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  subtask_name TEXT NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE
);


CREATE TABLE reminders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  reminder_date TIMESTAMPTZ NOT NULL
);

-- ================================================================================

-- CHECKS útiles para las tablas de la base de datos

ALTER TABLE profiles 
ADD CONSTRAINT check_names_not_empty 
CHECK (char_length(first_name) >= 2 AND char_length(last_name) >= 2);


ALTER TABLE tasks
ADD CONSTRAINT check_task_ranges 
  CHECK (importance BETWEEN 1 AND 5 AND complexity BETWEEN 1 AND 5),
ADD CONSTRAINT check_urgency_positive 
  CHECK (urgency >= 0),
ADD CONSTRAINT check_task_status_values 
  CHECK (task_status IN ('Pendiente', 'Completada', 'Atrasada'));


ALTER TABLE subtasks 
ADD CONSTRAINT check_subtask_name_length 
CHECK (char_length(subtask_name) >= 3);


