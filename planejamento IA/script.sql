CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('student', 'instructor', 'admin')),
    avatar_url VARCHAR(255),
    bio TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_token VARCHAR(100),
    reset_password_token VARCHAR(100),
    reset_password_expires TIMESTAMP,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    short_description VARCHAR(255),
    instructor_id INTEGER REFERENCES users(id) NOT NULL,
    category_id INTEGER REFERENCES categories(id) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    discount_price DECIMAL(10, 2),
    language VARCHAR(50) DEFAULT 'Português',
    level VARCHAR(20) CHECK (level IN ('beginner', 'intermediate', 'advanced')) NOT NULL,
    duration INTEGER, -- em horas
    thumbnail_url VARCHAR(255),
    promo_video_url VARCHAR(255),
    is_published BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMP,
    requirements TEXT[],
    what_you_will_learn TEXT[],
    target_audience TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE modules (
    id SERIAL PRIMARY KEY,
    course_id INTEGER REFERENCES courses(id) ON DELETE CASCADE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    position INTEGER NOT NULL,
    is_free BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lessons (
    id SERIAL PRIMARY KEY,
    module_id INTEGER REFERENCES modules(id) ON DELETE CASCADE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    content_type VARCHAR(20) CHECK (content_type IN ('video', 'article', 'quiz', 'exercise')) NOT NULL,
    content_url VARCHAR(255),
    duration INTEGER, -- em minutos
    position INTEGER NOT NULL,
    is_preview BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE resources (
    id SERIAL PRIMARY KEY,
    lesson_id INTEGER REFERENCES lessons(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(255) NOT NULL,
    file_url VARCHAR(255) NOT NULL,
    file_size INTEGER,
    file_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE enrollments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) NOT NULL,
    course_id INTEGER REFERENCES courses(id) NOT NULL,
    payment_id INTEGER REFERENCES payments(id),
    enrollment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completion_date TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('active', 'completed', 'canceled')) DEFAULT 'active',
    UNIQUE(user_id, course_id)
);

CREATE TABLE user_progress (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) NOT NULL,
    lesson_id INTEGER REFERENCES lessons(id) NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP,
    last_accessed TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    progress_percentage INTEGER DEFAULT 0,
    UNIQUE(user_id, lesson_id)
);

CREATE TABLE certificates (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    user_id INTEGER REFERENCES users(id) NOT NULL,
    course_id INTEGER REFERENCES courses(id) NOT NULL,
    enrollment_id INTEGER REFERENCES enrollments(id) NOT NULL,
    issue_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    certificate_url VARCHAR(255) NOT NULL,
    verification_code VARCHAR(50) UNIQUE NOT NULL,
    UNIQUE(user_id, course_id)
);

CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) NOT NULL,
    course_id INTEGER REFERENCES courses(id) NOT NULL,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5) NOT NULL,
    comment TEXT,
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, course_id)
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) NOT NULL,
    lesson_id INTEGER REFERENCES lessons(id) NOT NULL,
    parent_id INTEGER REFERENCES comments(id),
    content TEXT NOT NULL,
    is_approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'BRL',
    payment_method VARCHAR(50) NOT NULL,
    payment_status VARCHAR(20) CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')) DEFAULT 'pending',
    transaction_id VARCHAR(100),
    receipt_url VARCHAR(255),
    paid_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payment_methods (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) NOT NULL,
    payment_type VARCHAR(50) CHECK (payment_type IN ('credit_card', 'pix', 'boleto')) NOT NULL,
    card_last_four VARCHAR(4),
    card_brand VARCHAR(20),
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    notification_type VARCHAR(50) NOT NULL,
    related_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE favorites (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) NOT NULL,
    course_id INTEGER REFERENCES courses(id) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, course_id)
);

CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE course_tags (
    course_id INTEGER REFERENCES courses(id) ON DELETE CASCADE,
    tag_id INTEGER REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (course_id, tag_id)
);

-- Índices para consultas frequentes
CREATE INDEX idx_courses_instructor ON courses(instructor_id);
CREATE INDEX idx_courses_category ON courses(category_id);
CREATE INDEX idx_modules_course ON modules(course_id);
CREATE INDEX idx_lessons_module ON lessons(module_id);
CREATE INDEX idx_enrollments_user ON enrollments(user_id);
CREATE INDEX idx_enrollments_course ON enrollments(course_id);
CREATE INDEX idx_progress_user_lesson ON user_progress(user_id, lesson_id);
CREATE INDEX idx_reviews_course ON reviews(course_id);
CREATE INDEX idx_comments_lesson ON comments(lesson_id);
CREATE INDEX idx_payments_user ON payments(user_id);

Relacionamentos Principais
Users → Courses: Um-para-muitos (instrutor cria vários cursos)

Courses → Modules: Um-para-muitos (curso tem vários módulos)

Modules → Lessons: Um-para-muitos (módulo tem várias aulas)

Users → Enrollments: Um-para-muitos (usuário pode se inscrever em vários cursos)

Courses → Enrollments: Um-para-muitos (curso pode ter várias inscrições)

Users → Reviews: Um-para-muitos (usuário pode avaliar vários cursos)

Courses → Reviews: Um-para-muitos (curso pode ter várias avaliações)

Esta estrutura de banco de dados suporta todas as funcionalidades mostradas nos layouts de front-end e nos endpoints da API, com:

Normalização adequada

Chaves estrangeiras para integridade referencial

Tipos de dados apropriados

Restrições para manter a qualidade dos dados

Índices para otimização de consultas frequentes

Você pode implementar este modelo em qualquer sistema de gerenciamento de banco de dados relacional como PostgreSQL, MySQL ou SQL Server.