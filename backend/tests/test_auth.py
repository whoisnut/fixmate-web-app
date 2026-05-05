import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

@pytest.fixture(scope='module')
def test_client():
    return client

def test_register_and_login(test_client):
    email = 'unittestuser@example.com'
    password = 'Test1234!'

    # ensure email doesn't exist by trying to login first
    response = test_client.post('/api/v1.0.0/auth/login', json={'email': email, 'password': password})
    # New backend might return 401 or 422 if format is wrong, but here we expect 401 Unauthorized for bad creds
    assert response.status_code == 401

    # register new user
    response = test_client.post(
        '/api/v1.0.0/auth/register',
        json={
            'name': 'Unit Test User',
            'email': email,
            'phone': '0000000000',
            'password': password,
            'role': 'customer',
        }
    )
    assert response.status_code in (200, 201)
    json_data = response.json()
    assert 'data' in json_data
    data = json_data['data']
    assert 'access_token' in data
    assert 'user' in data

    # login with the created user
    response = test_client.post('/api/v1.0.0/auth/login', json={'email': email, 'password': password})
    assert response.status_code == 200
    json_data = response.json()
    assert 'data' in json_data
    data = json_data['data']
    assert 'access_token' in data
    assert data['user']['email'] == email
