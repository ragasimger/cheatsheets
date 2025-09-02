-- ============================================
-- POSTGRESQL CHEATSHEET
-- Daily-use SQL commands with examples & notes
-- ============================================

-- ======================
-- 1. ACCESSING DATABASE
-- ======================
-- Login as a specific user:
-- Terminal: psql -U postgres
-- Connect to a database:
\c dvdrental;

-- Quit psql
\q

-- List all databases
\l

-- List all schemas
\dn

-- List all users/roles
\du

-- List all tables in current database/schema
\dt

-- List all tables of all schemas in current database
-- public
------ branch1 (user, profile)
------ branch2 (user, profile)
------ branch3 (user, profile)
\dt *.*

-- Output:
------ branch1.user
------ branch1.profile
------ branch2.user
------ branch2.profile
------ branch3.user
------ branch3.profile



-- List all views
\dv

-- List all functions & procedures
\df

-- Get detailed table info
\d+ employees

-- Pretty print query results
\x


-- ======================
-- 2. USER & ROLE MANAGEMENT
-- ======================
-- Create a role
CREATE ROLE analyst;

-- Create a user with password
CREATE ROLE myuser LOGIN PASSWORD 'mypassword';

-- Grant privileges on a database
GRANT ALL PRIVILEGES ON DATABASE dvdrental TO myuser;

-- Allow role_1 to assume role_2
GRANT role_2 TO role_1;

-- Change current role in session
SET ROLE analyst;


-- ======================
-- 3. DATABASE MANAGEMENT
-- ======================
-- Create database
CREATE DATABASE mydb;

-- Drop database (permanently)
DROP DATABASE IF EXISTS mydb;


-- ======================
-- 4. SCHEMA MANAGEMENT
-- ======================
-- Create schema
CREATE SCHEMA sales;

-- Drop schema and everything in it
DROP SCHEMA sales CASCADE;

-- Use schema in search path
SET search_path TO sales, public;


-- ======================
-- 5. TABLE COMMANDS
-- ======================
-- Create table
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    department_id INT,
    salary NUMERIC(10,2) CHECK (salary > 0),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Temporary table
CREATE TEMP TABLE temp_employees AS SELECT * FROM employees;

-- Rename table
ALTER TABLE employees RENAME TO staff;

-- Drop table (and its dependencies)
DROP TABLE IF EXISTS staff CASCADE;


-- ======================
-- 6. COLUMN COMMANDS
-- ======================
ALTER TABLE employees ADD COLUMN age INT;
ALTER TABLE employees RENAME COLUMN name TO full_name;
ALTER TABLE employees DROP COLUMN age;
ALTER TABLE employees ALTER COLUMN salary TYPE INT;
ALTER TABLE employees ALTER COLUMN department_id SET DEFAULT 1;


-- ======================
-- 7. CONSTRAINTS
-- ======================
-- Add a primary key
ALTER TABLE employees ADD PRIMARY KEY (id);

-- Add a unique constraint
ALTER TABLE employees ADD CONSTRAINT unique_email UNIQUE (email);

-- Add a foreign key
ALTER TABLE employees
ADD CONSTRAINT fk_department FOREIGN KEY (department_id) REFERENCES departments(id);

-- Remove constraint
ALTER TABLE employees DROP CONSTRAINT fk_department;


-- ======================
-- 8. QUERYING DATA
-- ======================
-- Select everything
SELECT * FROM employees;

-- Select specific columns
SELECT name, salary FROM employees;

-- Filtering
SELECT * FROM employees WHERE salary > 50000;

-- Pattern match
SELECT * FROM employees WHERE name LIKE '%John%';

-- Range
SELECT * FROM employees WHERE salary BETWEEN 40000 AND 80000;

-- IN list
SELECT * FROM employees WHERE department_id IN (1, 2, 3);

-- Sorting & limiting
SELECT * FROM employees ORDER BY salary DESC LIMIT 5 OFFSET 10;

-- Aggregate
SELECT COUNT(*) FROM employees;

-- Grouping
SELECT department_id, AVG(salary) FROM employees GROUP BY department_id;

-- Filtering groups
SELECT department_id, AVG(salary) FROM employees GROUP BY department_id HAVING AVG(salary) > 60000;


-- ======================
-- 9. JOINS
-- ======================
-- INNER JOIN (only matching rows)
SELECT e.name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.id;

-- LEFT JOIN (all from left, matching from right)
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id;

-- RIGHT JOIN (all from right, matching from left)
SELECT e.name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.department_id = d.id;

-- FULL OUTER JOIN (all from both sides)
SELECT e.name, d.dept_name
FROM employees e
FULL OUTER JOIN departments d ON e.department_id = d.id;

-- CROSS JOIN (Cartesian product)
SELECT e.name, d.dept_name
FROM employees e
CROSS JOIN departments d;

-- SELF JOIN (employees with managers)
SELECT e1.name AS employee, e2.name AS manager
FROM employees e1
JOIN employees e2 ON e1.manager_id = e2.id;


-- ======================
-- 10. SET OPERATIONS
-- ======================
-- UNION (combine without duplicates)
SELECT name FROM employees
UNION
SELECT name FROM contractors;

-- INTERSECT (common rows)
SELECT name FROM employees
INTERSECT
SELECT name FROM contractors;

-- EXCEPT (rows in first not in second)
SELECT name FROM employees
EXCEPT
SELECT name FROM contractors;


-- ======================
-- 11. MODIFYING DATA
-- ======================
-- Insert
INSERT INTO employees (name, email, department_id, salary)
VALUES ('Alice', 'alice@example.com', 1, 50000);

-- Insert multiple
INSERT INTO employees (name, email, department_id, salary)
VALUES 
  ('Bob', 'bob@example.com', 2, 60000),
  ('Charlie', 'charlie@example.com', 3, 55000);

-- UPSERT (insert or update on conflict)
INSERT INTO employees (id, name, salary)
VALUES (1, 'Alice', 70000)
ON CONFLICT (id) DO UPDATE SET salary = EXCLUDED.salary;

-- Update
UPDATE employees SET salary = salary * 1.1 WHERE department_id = 1;

-- Delete
DELETE FROM employees WHERE id = 5;


-- ======================
-- 12. VIEWS
-- ======================
-- Create view
CREATE OR REPLACE VIEW high_salary_employees AS
SELECT name, salary FROM employees WHERE salary > 60000;

-- Materialized view
CREATE MATERIALIZED VIEW sales_summary AS
SELECT department_id, SUM(salary) AS total_salary
FROM employees GROUP BY department_id;

-- Refresh materialized view
REFRESH MATERIALIZED VIEW sales_summary;

-- Drop view
DROP VIEW high_salary_employees;


-- ======================
-- 13. INDEXES
-- ======================
-- Simple index
CREATE INDEX idx_name ON employees(name);

-- Unique index
CREATE UNIQUE INDEX idx_unique_email ON employees(email);

-- Drop index
DROP INDEX idx_name;


-- ======================
-- 14. TRANSACTIONS
-- ======================
BEGIN;
    UPDATE employees SET salary = salary - 1000 WHERE id = 1;
    UPDATE employees SET salary = salary + 1000 WHERE id = 2;
COMMIT;

-- Rollback example
BEGIN;
    DELETE FROM employees WHERE department_id = 3;
ROLLBACK;


-- ======================
-- 15. CTE (COMMON TABLE EXPRESSIONS)
-- ======================
WITH dept_avg AS (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
)
SELECT e.name, e.salary, d.avg_salary
FROM employees e
JOIN dept_avg d ON e.department_id = d.department_id;

-- Recursive CTE
WITH RECURSIVE subordinates AS (
    SELECT id, manager_id, name FROM employees WHERE id = 1
    UNION
    SELECT e.id, e.manager_id, e.name
    FROM employees e
    INNER JOIN subordinates s ON e.manager_id = s.id
)
SELECT * FROM subordinates;


-- ======================
-- 16. WINDOW FUNCTIONS
-- ======================
SELECT name, salary,
       RANK() OVER (ORDER BY salary DESC) AS rank,
       ROW_NUMBER() OVER (ORDER BY salary) AS row_num,
       AVG(salary) OVER (PARTITION BY department_id) AS dept_avg
FROM employees;


-- ======================
-- 17. JSON / JSONB
-- ======================
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    data JSONB
);

INSERT INTO orders (data) VALUES ('{"product":"Laptop","qty":2,"price":1200}');

-- Extract values
SELECT data->>'product' AS product, (data->>'qty')::INT AS quantity FROM orders;


-- ======================
-- 18. SEQUENCES
-- ======================
CREATE SEQUENCE emp_seq START 100;
SELECT nextval('emp_seq');
ALTER SEQUENCE emp_seq RESTART WITH 200;


-- ======================
-- 19. TRIGGERS
-- ======================
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE employees ADD COLUMN updated_at TIMESTAMP;
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON employees
FOR EACH ROW EXECUTE FUNCTION update_timestamp();


-- ======================
-- 20. EXTENSIONS
-- ======================
-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
SELECT uuid_generate_v4();

-- Enable trigram search for fuzzy text matching
CREATE EXTENSION IF NOT EXISTS pg_trgm;
SELECT * FROM employees WHERE name % 'Jon';


-- ======================
-- 21. PERFORMANCE
-- ======================
EXPLAIN SELECT * FROM employees WHERE salary > 50000;
EXPLAIN ANALYZE SELECT * FROM employees WHERE salary > 50000;
ANALYZE employees;


-- ======================
-- 22. IMPORT / EXPORT
-- ======================
-- Export table to CSV
COPY employees TO '/tmp/employees.csv' CSV HEADER;

-- Import from CSV
COPY employees FROM '/tmp/employees.csv' CSV HEADER;


-- ======================
-- 23. BACKUP & RESTORE
-- ======================
-- Backup a database (terminal)
-- pg_dump dvdrental > dvdrental_backup.sql







-- Comparison & Logical Operators

-- Equal to
SELECT * FROM users WHERE age = 25;

-- Not equal to (SQL standard)
SELECT * FROM users WHERE age <> 25;

-- Not equal to (PostgreSQL alias, same as <>)
SELECT * FROM users WHERE age != 25;

-- Greater than
SELECT * FROM users WHERE age > 25;

-- Less than
SELECT * FROM users WHERE age < 25;

-- Greater than or equal to
SELECT * FROM users WHERE age >= 25;

-- Less than or equal to
SELECT * FROM users WHERE age <= 25;

-- BETWEEN (inclusive: min and max included)
SELECT * FROM users WHERE age BETWEEN 18 AND 30;

-- IN (matches any in the list)
SELECT * FROM users WHERE age IN (18, 21, 25);

-- NOT IN (excludes listed values)
SELECT * FROM users WHERE age NOT IN (18, 21, 25);

-- LIKE (case-sensitive pattern match, % = wildcard, _ = single char)
SELECT * FROM users WHERE name LIKE 'S%';   -- starts with S
SELECT * FROM users WHERE name LIKE '%ar';  -- ends with ar
SELECT * FROM users WHERE name LIKE '_a%';  -- second letter is a

-- ILIKE (case-insensitive LIKE)
SELECT * FROM users WHERE name ILIKE 's%';  -- matches "Sam", "sagar", "SAGAR"

-- IS NULL
SELECT * FROM users WHERE email IS NULL;

-- IS NOT NULL
SELECT * FROM users WHERE email IS NOT NULL;


/* ============================================================
 Aggregates & Statistical Functions
============================================================ */

-- Basic aggregates across the whole table
SELECT
  COUNT(*)                            AS total_rows,           -- all rows
  COUNT(email)                        AS email_nonnull_rows,   -- ignores NULLs
  COUNT(DISTINCT department_id)       AS distinct_departments, -- unique count
  SUM(salary)                         AS total_salary,
  AVG(salary)                         AS avg_salary,           -- average
  MIN(salary)                         AS min_salary,           -- minimum
  MAX(salary)                         AS max_salary            -- maximum
FROM employees;

-- Grouped aggregates (collapse by group)
SELECT
  department_id,
  COUNT(*)                            AS n,
  SUM(salary)                         AS payroll,
  AVG(salary)::numeric(12,2)          AS avg_salary,
  MIN(salary)                         AS min_salary,
  MAX(salary)                         AS max_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 60000            -- filter groups
ORDER BY payroll DESC;

-- Conditional aggregates (only rows matching the condition)
SELECT
  COUNT(*) FILTER (WHERE active)                    AS active_users,
  COUNT(*) FILTER (WHERE NOT active)                AS inactive_users,
  SUM(salary) FILTER (WHERE department_id = 1)      AS eng_payroll,
  AVG(salary) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days')
                                                    AS avg_salary_last_30d
FROM employees;

-- Null-safe sums/averages (treat NULL as 0 or a default)
SELECT
  COALESCE(SUM(bonus), 0)               AS total_bonus,
  AVG(COALESCE(bonus, 0))               AS avg_bonus_null_as_zero
FROM employees;

-- String and array aggregations (handy for rollups / exports)
SELECT
  department_id,
  STRING_AGG(name, ', ' ORDER BY name)  AS names_csv,
  ARRAY_AGG(id ORDER BY id)             AS employee_ids
FROM employees
GROUP BY department_id;

-- Percentiles & median (ordered-set aggregates)
SELECT
  PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY salary) AS median_salary,
  PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY salary) AS p90_salary
FROM employees;

-- Standard deviation & variance (distribution insight)
SELECT
  STDDEV_POP(salary)   AS salary_stddev_pop,
  STDDEV_SAMP(salary)  AS salary_stddev_sample,
  VAR_POP(salary)      AS salary_var_pop,
  VAR_SAMP(salary)     AS salary_var_sample
FROM employees;

-- Mode (most frequent value) using ordered-set aggregate
SELECT MODE() WITHIN GROUP (ORDER BY department_id) AS most_common_department
FROM employees;

-- Windowed aggregates (per-row metrics without collapsing result)
SELECT
  id,
  department_id,
  salary,
  AVG(salary) OVER (PARTITION BY department_id)                       AS dept_avg_salary,
  MIN(salary) OVER (PARTITION BY department_id)                       AS dept_min_salary,
  MAX(salary) OVER (PARTITION BY department_id)                       AS dept_max_salary,
  SUM(salary) OVER (PARTITION BY department_id ORDER BY created_at
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_dept_payroll
FROM employees;

-- Subtotals and grand totals with ROLLUP (quick reports)
SELECT
  department_id,
  job_title,
  SUM(salary) AS payroll
FROM employees
GROUP BY ROLLUP (department_id, job_title)
ORDER BY department_id NULLS LAST, job_title NULLS LAST;



-- Restore a database
-- psql dvdrental < dvdrental_backup.sql
