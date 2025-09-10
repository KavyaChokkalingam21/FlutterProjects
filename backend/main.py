from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import sqlite3
import os

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic model for adding comment
class Comment(BaseModel):
    paragraph_id: int
    start_index: int
    end_index: int
    selected_text: str
    comment_text: str
    user_name: str

# Initialize database and table
def init_db():
    conn = sqlite3.connect("comments.db")
    cur = conn.cursor()
    cur.execute(
        '''
        CREATE TABLE IF NOT EXISTS comments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            paragraph_id INTEGER NOT NULL,
            start_index INTEGER NOT NULL,
            end_index INTEGER NOT NULL,
            selected_text TEXT NOT NULL,
            comment_text TEXT NOT NULL,
            user_name TEXT NOT NULL
        )
        '''
    )
    conn.commit()
    conn.close()

@app.on_event("startup")
def startup():
    # Initialize DB on server start
    init_db()

# POST endpoint to add a comment
@app.post("/comments")
def add_comment(comment: Comment):
    conn = sqlite3.connect("comments.db")
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO comments (paragraph_id, start_index, end_index, selected_text, comment_text, user_name) VALUES (?, ?, ?, ?, ?, ?)",
        (comment.paragraph_id, comment.start_index, comment.end_index,
         comment.selected_text, comment.comment_text, comment.user_name)
    )
    conn.commit()
    conn.close()
    return {"message": "Comment added successfully"}

# GET endpoint to fetch all comments for a paragraph
@app.get("/comments")
def get_comments(paragraph_id: int):
    conn = sqlite3.connect("comments.db")
    cur = conn.cursor()
    cur.execute(
        "SELECT start_index, end_index, selected_text, comment_text, user_name FROM comments WHERE paragraph_id = ?",
        (paragraph_id,)
    )
    rows = cur.fetchall()
    conn.close()
    return [
        {
            "start_index": r[0],
            "end_index": r[1],
            "selected_text": r[2],
            "comment_text": r[3],
            "user_name": r[4]
        }
        for r in rows
    ] 
