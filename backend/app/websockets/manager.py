from fastapi import WebSocket
from typing import Dict
import json


class ConnectionManager:
    def __init__(self):
        self._connections: Dict[str, WebSocket] = {}

    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        self._connections[user_id] = websocket

    def disconnect(self, user_id: str):
        self._connections.pop(user_id, None)

    async def send(self, user_id: str, message: dict):
        ws = self._connections.get(user_id)
        if ws:
            try:
                await ws.send_text(json.dumps(message))
            except Exception:
                self.disconnect(user_id)

    async def broadcast(self, user_ids: list[str], message: dict):
        for uid in user_ids:
            await self.send(uid, message)

    def is_connected(self, user_id: str) -> bool:
        return user_id in self._connections


manager = ConnectionManager()
