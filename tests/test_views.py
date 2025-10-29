import pytest
from django.test import Client

@pytest.mark.django_db
def test_main_view_get():
    client = Client()
    response = client.get('/')
    assert response.status_code == 200
    assert b"movie" in response.content or b"recommendation" in response.content
