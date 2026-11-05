"""Khởi tạo Firebase Admin một lần, dùng lại cho mọi service cần Firebase (hiện tại: auth-service)."""

import os

import firebase_admin
from firebase_admin import credentials


class FirebaseNotConfigured(Exception):
    """Thiếu hoặc sai file service account trong GOOGLE_APPLICATION_CREDENTIALS."""


def get_firebase_app():
    try:
        return firebase_admin.get_app()
    except ValueError:
        pass
    service_account = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
    if not service_account:
        raise FirebaseNotConfigured('GOOGLE_APPLICATION_CREDENTIALS is not set in Backend/.env')
    try:
        return firebase_admin.initialize_app(credentials.Certificate(service_account))
    except Exception as error:
        raise FirebaseNotConfigured(str(error)) from error
