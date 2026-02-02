from fastapi import FastAPI, Request, HTTPException
import httpx
import os

app = FastAPI(title="TigerAI Commercial Gateway")

# 模擬授權狀態 (這部分可由 Node-RED 寫入文件)
LICENSE_ACTIVE = True 

# 內部服務映射
SERVICE_MAP = {
    "ollama": "http://ollama:11434",
    "automation": "http://n8n:5678",
    "proprietary_v1": "http://api-v1:8000"
}

@app.middleware("http")
async def check_licensing(request: Request, call_next):
    if not LICENSE_ACTIVE:
        return {"error": "License Expired or Inactive. Please renew subscription."}, 403
    return await call_next(request)

@app.get("/health")
def health():
    return {"status": "bridge_active", "license": "valid"}

# 動態反向代理範例
@app.post("/v1/{target_service}/{path:path}")
async def proxy_request(target_service: str, path: str, request: Request):
    if target_service not in SERVICE_MAP:
        raise HTTPException(status_code=404, detail="Service not found")
    
    target_url = f"{SERVICE_MAP[target_service]}/{path}"
    async with httpx.AsyncClient() as client:
        # 轉發請求並傳回結果
        # 這邊可以加入您的商業計費邏輯 (Usage Tracking)
        return {"info": f"Proxying to {target_service}", "url": target_url}
