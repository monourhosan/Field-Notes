"""Live API regression check. Creates two uniquely named audit accounts and tombstoned test records."""
import json
import os
import uuid
import urllib.request
import urllib.error

BASE = os.environ.get("API_BASE_URL", "http://localhost:8080")
checks = 0
last_headers = {}

def request(method, path, body=None, token=None, expected=200, headers=None):
    global checks, last_headers
    combined = {"Content-Type": "application/json", **(headers or {})}
    if token:
        combined["Authorization"] = "Bearer " + token
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(BASE + path, data=data, headers=combined, method=method)
    try:
        response = urllib.request.urlopen(req, timeout=30)
    except urllib.error.HTTPError as error:
        response = error
    assert response.code == expected, f"{method} {path}: expected {expected}, got {response.code}"
    last_headers = dict(response.headers.items())
    checks += 1
    raw = response.read()
    return json.loads(raw) if raw else None

suffix = uuid.uuid4().hex[:16]
password = uuid.uuid4().hex
def register(name):
    return request("POST", "/api/auth/register", {"username": name+suffix, "email": name+suffix+"@example.com", "password": password}, expected=201)

owner, other = register("audit"), register("other")
token, outsider = owner["token"], other["token"]
request("POST", "/api/auth/login", {"username": " audit"+suffix+" ", "password": password})
request("POST", "/api/auth/login", {"username": ("audit"+suffix+"@example.com").upper(), "password": password})
request("POST", "/api/auth/login", {"username":"missing","password":"é"*40},expected=400)
request("POST", "/api/auth/login", {"username": "audit"+suffix, "password": "wrong"}, expected=401)
request("GET", "/api/customers", expected=401)
request("GET", "/api/customers", token="invalid", expected=401)
customer = request("POST", "/api/customers", {"name": "Audit customer"}, token, 201)
site = request("POST", "/api/sites", {"customerId":customer["id"],"siteName":"Audit site"}, token, 201)
note = request("POST", "/api/notes", {"siteId":site["id"],"title":"Inspection","description":"Voltage","status":"DRAFT","photo":"photo","dateTime":"2040-01-02T03:04:05Z"}, token, 201)
assert note["dateTime"] == "2040-01-02T03:04:05Z"
request("GET", "/api/customers/"+customer["id"], token=outsider, expected=404)
request("GET", "/api/sites/"+site["id"], token=outsider, expected=404)
request("GET", "/api/notes/"+note["id"], token=outsider, expected=404)
request("POST", "/api/customers", {"id":customer["id"],"name":"Attack"}, outsider, 409)
updated = request("PUT", "/api/notes/"+note["id"], {"siteId":site["id"],"title":"Inspection","description":"Voltage","status":"COMPLETED","version":note["version"],"photo":None}, token)
assert updated["photo"] is None and updated["version"] > note["version"]
request("PUT", "/api/notes/"+note["id"], {"siteId":site["id"],"title":"Stale","status":"DRAFT","version":note["version"]}, token, 409)
results = request("GET", "/api/notes?query=Voltage&status=COMPLETED&siteId="+site["id"], token=token)
assert len(results)==1
offline = str(uuid.uuid4())
batch = {"customers":[{"id":offline,"name":"Offline customer","baseVersion":None}],"sites":[],"notes":[]}
pushed = request("POST", "/api/sync/push", batch, token)
assert pushed["syncedCustomerIds"]==[offline]
assert request("POST", "/api/sync/push", batch, token)["syncedCustomerIds"]==[offline]
bad = {"customers":[{"id":str(uuid.uuid4()),"name":""}],"sites":[],"notes":[]}
request("POST", "/api/sync/push", bad, token, 400)
missing = {"sites":[{"id":str(uuid.uuid4()),"customerId":"missing","siteName":"No parent"}]}
assert request("POST", "/api/sync/push", missing, token)["syncedSiteIds"]==[]
request("POST", "/api/sync/push", {"customers":[None]},token,400)
request("POST", "/api/sync/push", {"notes":[{"id":str(uuid.uuid4()),"siteId":site["id"],"title":"Out of range","status":"DRAFT","dateTime":9223372036854775807}]},token,400)
request("GET", "/api/sync/pull",token=token)
tag = last_headers["ETag"]
request("GET", "/api/sync/pull",token=token,expected=304,headers={"If-None-Match":tag})
customer = request("PUT", "/api/customers/"+customer["id"],{"name":"Modified","version":customer["version"]},token)
request("GET", "/api/sync/pull",token=token,headers={"If-None-Match":tag})
assert last_headers["ETag"] != tag
request("DELETE", "/api/customers/"+customer["id"], token=token, expected=204)
request("GET", "/api/notes/"+note["id"], token=token, expected=404)
pull = request("GET", "/api/sync/pull?since=4102444800000", token=token)
assert any(n["id"]==note["id"] and n["deleted"] for n in pull["notes"])
assert request("GET", "/api/sync/pull", token=outsider)["customers"]==[]
request("DELETE", "/api/customers/"+offline, token=token, expected=204)
print(f"PASS: {checks} live API checks, including authentication, ownership, versions, sync retries, tombstones and cascade deletion")
