from pydantic import BaseModel

class UserCreate(BaseModel):
    username: str
    password: str

class UserResponse(BaseModel):
    username: str
    msg: str | None = None
    
class Token(BaseModel):
    access_token: str
    token_type: str