from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, Integer, String, Boolean, DateTime
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional
from dotenv import load_dotenv
import os

# Carregar variáveis de ambiente
load_dotenv()

# Database setup
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./tasks.db")

# Configuração específica para diferentes tipos de banco
if DATABASE_URL.startswith("sqlite"):
    # SQLite (desenvolvimento)
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
elif DATABASE_URL.startswith("postgresql"):
    # PostgreSQL (RDS)
    engine = create_engine(
        DATABASE_URL,
        pool_size=10,                    # Pool de conexões
        max_overflow=20,                 # Máximo de conexões extras
        pool_pre_ping=True,              # Verificar conexões antes de usar
        pool_recycle=300,                # Reciclar conexões a cada 5 min
        echo=os.getenv("ENVIRONMENT") == "development"  # Log SQL em dev
    )
else:
    # Fallback para outros bancos
    engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database Models
class Task(Base):
    __tablename__ = "tasks"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String, nullable=True)
    completed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

# Pydantic Models
class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = None

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    completed: Optional[bool] = None

class TaskResponse(BaseModel):
    id: int
    title: str
    description: Optional[str]
    completed: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# Create tables
Base.metadata.create_all(bind=engine)

# FastAPI app
app = FastAPI(title="Lista de Tarefas API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Em produção, especifique os domínios permitidos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Routes
@app.get("/")
def read_root():
    return {"message": "Lista de Tarefas API"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.post("/tasks/", response_model=TaskResponse)
def create_task(task: TaskCreate, db: Session = Depends(get_db)):
    db_task = Task(**task.dict())
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

@app.get("/tasks/", response_model=List[TaskResponse])
def read_tasks(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    tasks = db.query(Task).offset(skip).limit(limit).all()
    return tasks

@app.get("/tasks/{task_id}", response_model=TaskResponse)
def read_task(task_id: int, db: Session = Depends(get_db)):
    task = db.query(Task).filter(Task.id == task_id).first()
    if task is None:
        raise HTTPException(status_code=404, detail="Tarefa não encontrada")
    return task

@app.put("/tasks/{task_id}", response_model=TaskResponse)
def update_task(task_id: int, task_update: TaskUpdate, db: Session = Depends(get_db)):
    task = db.query(Task).filter(Task.id == task_id).first()
    if task is None:
        raise HTTPException(status_code=404, detail="Tarefa não encontrada")
    
    for field, value in task_update.dict(exclude_unset=True).items():
        setattr(task, field, value)
    
    db.commit()
    db.refresh(task)
    return task

@app.delete("/tasks/{task_id}")
def delete_task(task_id: int, db: Session = Depends(get_db)):
    task = db.query(Task).filter(Task.id == task_id).first()
    if task is None:
        raise HTTPException(status_code=404, detail="Tarefa não encontrada")
    
    db.delete(task)
    db.commit()
    return {"message": "Tarefa deletada com sucesso"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
