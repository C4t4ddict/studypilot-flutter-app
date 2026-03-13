from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
import os
import pymysql
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="GUICULUM MySQL API")


def db_conn():
    return pymysql.connect(
        host=os.getenv("MYSQL_HOST", "127.0.0.1"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        user=os.getenv("MYSQL_USER", "guiculum_user"),
        password=os.getenv("MYSQL_PASSWORD", "guiculum123!"),
        database=os.getenv("MYSQL_DB", "guiculum"),
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True,
    )


def ensure_user(user_id: int = 1):
    conn = db_conn()
    with conn.cursor() as cur:
        cur.execute("INSERT IGNORE INTO users(id, login_id, password_hash, role) VALUES(%s,%s,%s,%s)", (user_id, "local_user", "local", "user"))
    conn.close()


class GuidelineIn(BaseModel):
    user_id: int = 1
    target_role: str
    title: str
    notes: str = ""


class CurriculumIn(BaseModel):
    user_id: int = 1
    guideline_id: int
    title: str
    start_date: str
    end_date: str


class TodoIn(BaseModel):
    user_id: int = 1
    curriculum_id: int
    title: str
    status: str = "todo"
    priority: str = "medium"
    due_date: Optional[str] = None


class BulkMoveIn(BaseModel):
    ids: list[int]
    due_date: str


@app.get("/health")
def health():
    try:
        conn = db_conn()
        with conn.cursor() as cur:
            cur.execute("SELECT 1 as ok")
            row = cur.fetchone()
        conn.close()
        return {"ok": bool(row and row["ok"] == 1)}
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/guidelines")
def list_guidelines(user_id: int = 1):
    ensure_user(user_id)
    conn = db_conn()
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM guidelines WHERE user_id=%s ORDER BY created_at DESC", (user_id,))
        rows = cur.fetchall()
    conn.close()
    return rows


@app.post("/guidelines")
def create_guideline(body: GuidelineIn):
    ensure_user(body.user_id)
    conn = db_conn()
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO guidelines(user_id,target_role,title,notes) VALUES(%s,%s,%s,%s)",
            (body.user_id, body.target_role, body.title, body.notes),
        )
        gid = cur.lastrowid
    conn.close()
    return {"id": gid}


@app.get("/curriculums")
def list_curriculums(user_id: int = 1):
    conn = db_conn()
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM curriculums WHERE user_id=%s ORDER BY start_date ASC", (user_id,))
        rows = cur.fetchall()
    conn.close()
    return rows


@app.post("/curriculums")
def create_curriculum(body: CurriculumIn):
    conn = db_conn()
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO curriculums(user_id,guideline_id,title,start_date,end_date) VALUES(%s,%s,%s,%s,%s)",
            (body.user_id, body.guideline_id, body.title, body.start_date, body.end_date),
        )
        cid = cur.lastrowid
    conn.close()
    return {"id": cid}


@app.get("/todos")
def list_todos(user_id: int = 1):
    conn = db_conn()
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM todos WHERE user_id=%s ORDER BY due_date ASC", (user_id,))
        rows = cur.fetchall()
    conn.close()
    return rows


@app.post("/todos")
def create_todo(body: TodoIn):
    conn = db_conn()
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO todos(user_id,curriculum_id,title,status,priority,due_date) VALUES(%s,%s,%s,%s,%s,%s)",
            (body.user_id, body.curriculum_id, body.title, body.status, body.priority, body.due_date),
        )
        tid = cur.lastrowid
    conn.close()
    return {"id": tid}


@app.patch("/todos/{todo_id}")
def patch_todo(todo_id: int, body: dict):
    allowed = {"title", "status", "priority", "due_date"}
    cols = [k for k in body.keys() if k in allowed]
    if not cols:
        return {"ok": True}
    vals = [body[c] for c in cols]
    sets = ", ".join([f"{c}=%s" for c in cols])
    conn = db_conn()
    with conn.cursor() as cur:
        cur.execute(f"UPDATE todos SET {sets} WHERE id=%s", (*vals, todo_id))
    conn.close()
    return {"ok": True}


@app.delete("/todos/{todo_id}")
def delete_todo(todo_id: int):
    conn = db_conn()
    with conn.cursor() as cur:
        cur.execute("DELETE FROM todos WHERE id=%s", (todo_id,))
    conn.close()
    return {"ok": True}


@app.post("/todos/bulk-move")
def bulk_move(body: BulkMoveIn):
    if not body.ids:
        return {"ok": True}
    conn = db_conn()
    with conn.cursor() as cur:
        placeholders = ",".join(["%s"] * len(body.ids))
        cur.execute(f"UPDATE todos SET due_date=%s WHERE id IN ({placeholders})", (body.due_date, *body.ids))
    conn.close()
    return {"ok": True}


@app.get("/dashboard/kpi")
def kpi(user_id: int = 1):
    conn = db_conn()
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) c FROM guidelines WHERE user_id=%s", (user_id,))
        g = cur.fetchone()["c"]
        cur.execute("SELECT COUNT(*) c FROM curriculums WHERE user_id=%s", (user_id,))
        c = cur.fetchone()["c"]
        cur.execute("SELECT COUNT(*) c FROM todos WHERE user_id=%s AND status='done'", (user_id,))
        d = cur.fetchone()["c"]
    conn.close()
    return {"guidelines": g, "curriculums": c, "todos_done": d}
